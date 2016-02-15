defmodule ExfileB2.B2Client.HTTPoison do
  @behaviour ExfileB2.B2Client

  import HTTPoison, only: [get: 3, head: 3, post: 4]
  alias ExfileB2.{B2Bucket, B2File, B2UploadAuthorization, B2Client}

  def authenticate(account_id, application_key) do
    hackney_opts = [ basic_auth: {account_id, application_key} ]
    case get("https://api.backblaze.com/b2api/v1/b2_authorize_account", [], [hackney: hackney_opts]) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:ok, %B2Client{
          account_id: account_id,
          api_url: body["apiUrl"],
          authorization_token: body["authorizationToken"],
          download_url: body["downloadUrl"]
        }}
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_bucket(b2, bucket_name) do
    uri = b2.api_url <> "/b2api/v1/b2_list_buckets"
    {:ok, request_body} = Poison.encode(%{"accountId" => b2.account_id})
    headers = [
      {"Authorization", b2.authorization_token},
      {"Content-Type", "application/json"}
    ]
    case post(uri, request_body, headers, []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        bucket = Enum.find(body["buckets"], fn
          (%{"bucketName" => ^bucket_name}) -> true
          (_) -> false
        end)
        if bucket do
          {:ok, %B2Bucket{
            bucket_name: bucket["bucketName"],
            bucket_id: bucket["bucketId"],
            bucket_type: bucket["bucketType"],
            account_id: bucket["accountId"]
          }}
        else
          {:error, :bucket_not_found}
        end
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def download(b2, bucket, path) do
    uri = get_download_url(b2, bucket, path)
    case get(uri, [{"Authorization", b2.authorization_token}], []) do
      {:ok, %{status_code: 200, body: body}} ->
        {:ok, body}
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def download_head(b2, bucket, path) do
    uri = get_download_url(b2, bucket, path)
    case head(uri, [{"Authorization", b2.authorization_token}], []) do
      {:ok, %{status_code: 200}} ->
        :ok
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_upload_url(b2, bucket) do
    uri = b2.api_url <> "/b2api/v1/b2_get_upload_url"
    {:ok, request_body} = Poison.encode(%{"bucketId" => bucket.bucket_id})
    headers = [
      {"Authorization", b2.authorization_token},
      {"Content-Type", "application/json"}
    ]
    case post(uri, request_body, headers, []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:ok, %B2UploadAuthorization{
          bucket_id: body["bucketId"],
          upload_url: body["uploadUrl"],
          authorization_token: body["authorizationToken"]
        }}
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(b2, %B2Bucket{} = bucket, iodata, filename) do
    case get_upload_url(b2, bucket) do
      {:ok, auth} ->
        upload(b2, auth, iodata, filename)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def upload(b2, %B2UploadAuthorization{} = auth, iodata, filename) do
    headers = [
      {"Authorization", auth.authorization_token},
      {"X-Bz-File-Name", filename},
      {"Content-Type", "b2/x-auto"},
      {"X-Bz-Content-Sha1", sha1hash(iodata)}
    ]
    case post(auth.upload_url, iodata, headers, []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:ok, to_file(body)}
      {:ok, %{status_code: code}} when code >= 500 and code < 600 ->
        # Failure codes in the range 500 through 599 mean that the storage pod
        # is having trouble accepting your data. In this case you must call
        # b2_get_upload_url to get a new uploadUrl and a new authorizationToken.
        upload(b2, %B2Bucket{bucket_id: auth.bucket_id}, iodata, filename)
      {:ok, %{status_code: code, body: original_body}} when code >= 400 and code < 500 ->
        # If the failure returns an HTTP status code in the range 400 through
        # 499, it means that there is a problem with your request.
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(b2, %B2File{} = file) do
    uri = b2.api_url <> "/b2api/v1/b2_delete_file_version"
    {:ok, request_body} = Poison.encode(%{
      "fileName" => file.file_name,
      "fileId" => file.file_id
    })
    headers = [
      {"Authorization", b2.authorization_token},
      {"Content-Type", "application/json"}
    ]
    case post(uri, request_body, headers, []) do
      {:ok, %{status_code: 200}} ->
        :ok
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def delete(b2, bucket, filename) when is_binary(filename) do
    case list_file_versions(b2, bucket, filename) do
      {:ok, files} ->
        Enum.each(files, fn(file) ->
          delete(b2, file)
        end)
      error ->
        error
    end
  end

  def list_file_versions(b2, bucket, filename) when is_binary(filename) do
    uri = b2.api_url <> "/b2api/v1/b2_list_file_versions"
    {:ok, request_body} = Poison.encode(%{
      "bucketId" => bucket.bucket_id,
      "startFileName" => filename
    })
    headers = [
      {"Authorization", b2.authorization_token},
      {"Content-Type", "application/json"}
    ]
    case post(uri, request_body, headers, []) do
      {:ok, %{status_code: 200, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:ok, Enum.filter_map(body["files"], fn
          (%{"fileName" => ^filename}) -> true
          _ -> false
        end, &to_file(&1, bucket))}
      {:ok, %{status_code: code, body: original_body}} ->
        body = Poison.Parser.parse!(original_body)
        {:error, {:"http_#{code}", body["message"]}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp sha1hash(iodata) do
    :crypto.hash(:sha, iodata) |> Base.encode16(case: :lower)
  end

  defp get_download_url(%{download_url: download_url}, %{bucket_name: bucket_name}, filename) do
    download_url <> "/file/" <> bucket_name <> "/" <> filename
  end

  defp to_file(file, bucket \\ %B2Bucket{}) do
    %B2File{
      bucket_id: file["bucketId"] || bucket.bucket_id,
      file_id: file["fileId"],
      file_name: file["fileName"],
      content_length: file["contentLength"],
      content_sha1: file["contentSha1"],
      content_type: file["contentType"],
      file_info: file["fileInfo"],
    }
  end
end

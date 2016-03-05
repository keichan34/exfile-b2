defmodule ExfileB2.B2Bucket do
  defstruct bucket_name: nil, bucket_id: nil, bucket_type: nil, account_id: nil
end

defmodule ExfileB2.B2File do
  defstruct bucket_id: nil, file_id: nil, file_name: nil, content_length: nil,
            content_sha1: nil, content_type: nil, file_info: nil
end

defmodule ExfileB2.B2UploadAuthorization do
  defstruct bucket_id: nil, upload_url: nil, authorization_token: nil
end

defmodule ExfileB2.B2Client do
  defstruct api_url: nil, authorization_token: nil, download_url: nil,
            account_id: nil

  @type account_id :: String.t
  @type application_key :: String.t

  @type file_contents :: iolist
  @type file_name :: String.t

  @type b2_client :: %ExfileB2.B2Client{}

  @callback authenticate(account_id, application_key) :: {:ok, b2_client} | {:error, atom}
  @callback get_bucket(b2_client, String.t) :: {:ok, ExfileB2.B2Bucket.t} | {:error, atom}

  @callback download(b2_client, ExfileB2.B2Bucket.t, Path.t) :: {:ok, file_contents} | {:error, atom}
  @callback download_head(b2_client, ExfileB2.B2Bucket.t, Path.t) :: {:ok, non_neg_integer} | {:error, atom}

  @callback get_upload_url(b2_client, ExfileB2.B2Bucket.t) :: {:ok, ExfileB2.B2UploadAuthorization.t} | {:error, atom}
  @callback upload(b2_client, ExfileB2.B2Bucket.t, file_contents, file_name) :: {:ok, ExfileB2.B2File.t} | {:error, atom}
  @callback upload(b2_client, ExfileB2.B2UploadAuthorization.t, file_contents, file_name) :: {:ok, ExfileB2.B2File.t} | {:error, atom}

  @callback delete(b2_client, ExfileB2.B2Bucket.t, Path.t) :: :ok | {:error, atom}
  @callback delete(b2_client, ExfileB2.B2File.t) :: :ok | {:error, atom}

  @callback list_file_versions(b2_client, ExfileB2.B2Bucket.t, file_name) :: {:ok, [ExfileB2.B2File.t, ...]} | {:error, atom}
end

defmodule ExfileB2.Backend do
  use Exfile.Backend

  @b2_client Application.get_env(:exfile_b2, :b2_client, ExfileB2.B2Client.HTTPoison)

  def init(%{account_id: account_id, application_key: application_key, bucket: bucket_name} = opts) do
    {:ok, backend} = super(opts)

    case @b2_client.authenticate(account_id, application_key) do
      {:ok, b2} ->
        case @b2_client.get_bucket(b2, bucket_name) do
          {:ok, bucket} ->
            put_in(backend.meta, %{
              bucket: bucket,
              b2: b2
            })
          {:error, reason} ->
            {:error, reason}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  def open(%{meta: m} = backend, id) do
    case @b2_client.download(m.b2, m.bucket, path(backend, id)) do
      {:ok, contents} ->
        StringIO.open(contents)
      {:error, reason} ->
        {:error, reason}
    end
  end

  def exists?(%{meta: m} = backend, id) do
    case @b2_client.download_head(m.b2, m.bucket, path(backend, id)) do
      :ok -> true
      _ -> false
    end
  end

  def size(backend, id) do
    case open(backend, id) do
      {:error, reason} ->
        {:error, reason}
      {:ok, io} ->
        {:ok, IO.read(io, :all) |> byte_size}
    end
  end

  def delete(%{meta: m} = backend, file_id) do
    @b2_client.delete(m.b2, m.bucket, path(backend, file_id))
  end

  # uploadable is another Exfile.File
  def upload(backend, %Exfile.File{} = other_file) do
    case Exfile.Backend.open(other_file) do
      {:ok, io} ->
        upload(backend, io)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # uploadable is a string path to a tempfile
  def upload(backend, uploadable) when is_binary(uploadable) do
    case File.open(uploadable, [:read, :binary], fn(io) -> upload(backend, io) end) do
      {:ok, result} ->
        result
      {:error, reason} ->
        {:error, reason}
    end
  end

  # uploadable is an io
  def upload(%{meta: m} = backend, io) when is_pid(io) do
    id = backend.hasher.hash(io)
    case IO.read(io, :all) do
      :eof ->
        {:ok, _} = :file.position(io, 0)
        upload(backend, io)
      {:error, reason} ->
        {:error, reason}
      bytes ->
        @b2_client.upload(m.b2, m.bucket, bytes, id)
        {:ok, get(backend, id)}
    end
  end

  def path(%{directory: directory}, id) do
    [directory, id]
    |> Enum.reject(&is_empty?/1)
    |> Enum.join("/")
  end

  defp is_empty?(elem) do
    string = to_string(elem)
    Regex.match?(~r/^\s*$/, string)
  end
end

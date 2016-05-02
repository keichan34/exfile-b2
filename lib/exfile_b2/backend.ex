defmodule ExfileB2.Backend do
  use Exfile.Backend

  alias Exfile.LocalFile
  alias ExfileB2.LocalCache

  @b2_client B2Client.backend

  def init(opts) do
    account_id      = Keyword.get(opts, :account_id)      || raise(ArgumentError, message: "account_id is required.")
    application_key = Keyword.get(opts, :application_key) || raise(ArgumentError, message: "application_key is required.")
    bucket_name     = Keyword.get(opts, :bucket)          || raise(ArgumentError, message: "bucket is required.")

    {:ok, backend} = super(opts)

    with  {:ok, b2} <- @b2_client.authenticate(account_id, application_key),
          {:ok, bucket} <- @b2_client.get_bucket(b2, bucket_name)
          do
            put_in(backend.meta, %{
              bucket: bucket,
              b2: b2
            })
          end
  end

  def open(backend, id) do
    case LocalCache.fetch(id) do
      {:ok, path} ->
        {:ok, %LocalFile{path: path}}
      _error ->
        uncached_open(backend, id)
    end
  end

  defp uncached_open(%{meta: m} = backend, id) do
    case @b2_client.download(m.b2, m.bucket, path(backend, id)) do
      {:ok, contents} ->
        _ = LocalCache.store(id, contents)
        io = File.open!(contents, [:ram, :binary])
        {:ok, %LocalFile{io: io}}
      {:error, reason} ->
        {:error, reason}
    end
  end

  def exists?(%{meta: m} = backend, id) do
    case @b2_client.download_head(m.b2, m.bucket, path(backend, id)) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def size(%{meta: m} = backend, id) do
    @b2_client.download_head(m.b2, m.bucket, path(backend, id))
  end

  def delete(%{meta: m} = backend, file_id) do
    LocalCache.delete(file_id)
    @b2_client.delete(m.b2, m.bucket, path(backend, file_id))
  end

  # uploadable is another Exfile.File
  def upload(backend, %Exfile.File{} = other_file) do
    case Exfile.File.open(other_file) do
      {:ok, local_file} ->
        upload(backend, local_file)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # uploadable is a Exfile.LocalFile
  def upload(backend, %LocalFile{} = local_file) do
    id = backend.hasher.hash(local_file)
    case LocalFile.open(local_file) do
      {:ok, io} ->
        perform_upload(backend, id, io)
      {:error, reason} ->
        {:error, reason}
    end
  end

  # uploadable is an io
  defp perform_upload(%{meta: m} = backend, id, io) do
    case IO.binread(io, :all) do
      {:error, reason} ->
        {:error, reason}
      iodata ->
        _ = LocalCache.store(id, iodata)
        _ = @b2_client.upload(m.b2, m.bucket, iodata, id)
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

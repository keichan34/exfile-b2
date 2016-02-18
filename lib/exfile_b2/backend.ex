defmodule ExfileB2.Backend do
  use Exfile.Backend

  alias Exfile.LocalFile

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
        io = File.open!(contents, [:ram, :binary])
        {:ok, %LocalFile{io: io}}
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
    with  {:ok, local_file} <- open(backend, id),
          {:ok, io}         <- LocalFile.open(local_file),
          do: {:ok, IO.binread(io, :all) |> IO.iodata_length}
  end

  def delete(%{meta: m} = backend, file_id) do
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
        @b2_client.upload(m.b2, m.bucket, iodata, id)
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

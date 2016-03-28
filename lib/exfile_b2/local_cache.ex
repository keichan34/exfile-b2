defmodule ExfileB2.LocalCache do
  use GenServer

  def start_link do
    GenServer.start(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch(key),
    do: GenServer.call(__MODULE__, {:fetch, key})

  def store(key, iodata) do
    delete(key)
    case GenServer.call(__MODULE__, {:store, key}) do
      {:ok, path} ->
        copy_iodata_to_path(iodata, path)

      error ->
        {:error, error}
    end
  end

  defp copy_iodata_to_path(iodata, path) do
    case File.open(path, [:write], &IO.binwrite(&1, iodata)) do
      {:ok, _} ->
        {:ok, path}
      error -> error
    end
  end

  def delete(key),
    do: GenServer.call(__MODULE__, {:delete, key})

  def flush(),
    do: GenServer.call(__MODULE__, :flush)

  ## GenServer Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:fetch, key}, _from, cache) do
    reply = Map.fetch(cache, key)
    {:reply, reply, cache}
  end

  def handle_call({:store, key}, _from, cache) do
    reply = case Exfile.Tempfile.random_file("b2-local-cache") do
      {:ok, path} ->
        cache = Map.put(cache, key, path)
        {:ok, path}
      error ->
        error
    end
    {:reply, reply, cache}
  end

  def handle_call({:delete, key}, _from, cache) do
    cache = case Map.fetch(cache, key) do
      {:ok, path} ->
        File.rm(path)
        Map.delete(cache, key)
      _ ->
        cache
    end
    {:reply, :ok, cache}
  end

  def handle_call(:flush, _from, cache) do
    for path <- Map.values(cache) do
      File.rm(path)
    end
    {:reply, :ok, %{}}
  end
end

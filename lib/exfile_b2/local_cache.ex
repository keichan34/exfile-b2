defmodule ExfileB2.LocalCache do
  use GenServer

  # In ms, 30 seconds.
  @vacuum_interval 30_000

  def start_link do
    GenServer.start(__MODULE__, :ok, name: __MODULE__)
  end

  def fetch(key),
    do: GenServer.call(__MODULE__, {:fetch, key})

  def store(key, iodata) do
    delete(key)
    byte_size = :erlang.iolist_size(iodata)
    case GenServer.call(__MODULE__, {:store, key, byte_size}) do
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

  def vacuum(),
    do: GenServer.call(__MODULE__, :vacuum)

  ## GenServer Callbacks

  def init(:ok) do
    Process.send_after(self, :vacuum, @vacuum_interval)
    {:ok, initial_state}
  end

  def handle_call({:fetch, key}, _from, %{cache: cache} = state) do
    {reply, state} = case Map.fetch(cache, key) do
      {:ok, {_last_used, byte_size, path}} ->
        state = state
        |> update_in([:cache], &Map.put(&1, key, {ts, byte_size, path}))
        {{:ok, path}, state}
      _ ->
        {:error, state}
      end
    {:reply, reply, state}
  end

  def handle_call({:store, key, byte_size}, _from, state) do
    {reply, state} = case Exfile.Tempfile.random_file("b2-local-cache") do
      {:ok, path} ->
        state = state
        |> update_in([:cache], &Map.put(&1, key, {ts, byte_size, path}))
        |> update_in([:bytes_used], &(&1 + byte_size))
        {{:ok, path}, state}
      error ->
        {error, state}
    end
    {:reply, reply, state}
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, perform_delete(state, key)}
  end

  def handle_call(:flush, _from, %{cache: cache}) do
    for {_, _, path} <- Map.values(cache) do
      File.rm(path)
    end
    {:reply, :ok, initial_state}
  end

  def handle_call(:vacuum, _from, state) do
    {:reply, :ok, perform_vacuum(state, cache_size)}
  end

  def handle_info(:vacuum, state) do
    state = perform_vacuum(state, cache_size)
    Process.send_after(self, :vacuum, @vacuum_interval)
    {:noreply, state}
  end

  defp perform_delete(%{cache: cache} = state, key) do
    case Map.fetch(cache, key) do
      {:ok, {_, byte_size, path}} ->
        File.rm(path)
        state
        |> update_in([:cache], &Map.delete(&1, key))
        |> update_in([:bytes_used], &(&1 - byte_size))
      _ ->
        state
    end
  end

  defp perform_vacuum(%{bytes_used: bytes} = state, cache_size) when bytes < cache_size,
    do: state
  defp perform_vacuum(%{cache: cache} = state, cache_size) do
    state
    |> perform_delete(lru_key cache)
    |> perform_vacuum(cache_size)
  end

  defp lru_key(cache) do
    Enum.reduce(cache, {ts + 1_000_000, nil}, fn
      ({key, {time, _, _}}, {least_access_time, _key}) when time < least_access_time ->
        {time, key}
      (_, {time, key}) ->
        {time, key}
    end) |> elem(1)
  end

  defp ts, do: :erlang.system_time(:micro_seconds)
  defp cache_size,
    do: Application.get_env(:exfile_b2, :local_cache_size, 100_000_000)
  defp initial_state, do: %{cache: %{}, bytes_used: 0}
end

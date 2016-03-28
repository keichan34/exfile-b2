defmodule ExfileB2.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      worker(ExfileB2.LocalCache, [])
    ]

    if requires_memory_server? do
      children = children ++ [
        worker(ExfileB2.B2Client.Memory, [])
      ]
    end

    supervise(children, strategy: :one_for_one)
  end

  defp requires_memory_server? do
    Application.get_env(:exfile_b2, :b2_client) == ExfileB2.B2Client.Memory
  end
end

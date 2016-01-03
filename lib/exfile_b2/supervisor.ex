defmodule ExfileB2.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_backend_state(args \\ []) do
    Supervisor.start_child(__MODULE__, [args])
  end

  def init(:ok) do
    children = [
    ]

    supervise(children, strategy: :one_for_one)
  end
end

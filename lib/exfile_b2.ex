defmodule ExfileB2 do
  use Application

  @doc false
  def start(_type, _args) do
    ExfileB2.Supervisor.start_link()
  end
end

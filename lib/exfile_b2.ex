defmodule ExfileB2 do
  @moduledoc false
  use Application

  @doc false
  def start(_type, _args) do
    ExfileB2.Supervisor.start_link
  end
end

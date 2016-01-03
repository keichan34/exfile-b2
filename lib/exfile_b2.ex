defmodule ExfileB2 do
  use Application

  @doc false
  def start(_type, _args) do
    {:ok, self}
  end
end

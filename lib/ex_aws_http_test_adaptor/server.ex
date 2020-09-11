defmodule ExAwsHttpTestAdaptor.Server do
  use GenServer

  def init(_) do
    {:ok, %{calls: %{}}}
  end

  def start(_type, _args) do
    Supervisor.start_link(
      [
        __MODULE__
      ],
      strategy: :one_for_one,
      name: ExAwsHttpTestAdaptor.Supervisor
    )
  end

  def start_link(args), do: GenServer.start_link(__MODULE__, args, name: __MODULE__)
end

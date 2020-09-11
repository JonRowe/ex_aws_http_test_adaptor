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

  def handle_call({:set, pid, method, path, status, headers, body}, _, %{calls: calls}) do
    {:reply,:ok, %{calls: Map.put(calls, pid, set_call(get(calls, pid), method, path, status, headers, body))}}
  end

  def handle_call({:request, pid, method, path, _body, _headers, _opts}, _, state = %{calls: calls}) do
    {:reply, request(get(calls, pid), method, path), state}
  end

  def handle_call(_, _, state), do: {:noreply, state}

  defp get(map, key), do: Map.get(map, key, %{})

  defguardp map_get(map, key) when :erlang.map_get(key, map)

  defp request(call, method, path) when is_map_key(call, path) and is_map_key(map_get(call, path), method)do
    call
    |> Map.get(path)
    |> Map.get(method)
  end

  defp request(_, _, _), do: {404, [], []}

  defp set_call(map, method, path, status, headers, body) do
    Map.put(map, path, Map.put(get(map, path), method, {status, headers, body}))
  end
end

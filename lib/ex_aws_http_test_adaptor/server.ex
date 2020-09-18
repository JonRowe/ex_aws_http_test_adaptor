defmodule ExAwsHttpTestAdaptor.Server do
  use GenServer

  require Logger

  @not_found {404, [], []}

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

  def handle_call({:set, pid, method, path, response}, _, %{calls: calls}) do
    {:reply, :ok, update_calls(calls, pid, method, path, response)}
  end

  def handle_call({:request, pid, method, path, _body, _headers, _opts}, _, state = %{calls: calls}) do
    {:reply, request(get(calls, pid), method, path), state}
  end

  def handle_call(_, _, state), do: {:noreply, state}

  defp get(map, key), do: Map.get(map, key, %{})

  defguardp map_get(map, key) when :erlang.map_get(key, map)

  defp request(call, method, path) when is_map_key(call, path) and is_map_key(map_get(call, path), method) do
    Logger.debug("Hit for #{method} #{path}")

    call
    |> Map.get(path)
    |> Map.get(method)
    |> handle_hit()
  end

  defp request(call, method, path) do
    Logger.debug("No call found for #{method} #{path} in #{inspect(call)}")
    @not_found
  end

  defp handle_hit([response = {_, _, _} | _]), do: response
  defp handle_hit([]), do: @not_found

  defp set_call(call, method, path, value) do
    Map.put(call, path, Map.update(get(call, path), method, [value], &(&1 ++ [value])))
  end

  defp update_calls(calls, pid, method, path, value) do
    %{calls: Map.put(calls, pid, set_call(get(calls, pid), method, path, value))}
  end
end

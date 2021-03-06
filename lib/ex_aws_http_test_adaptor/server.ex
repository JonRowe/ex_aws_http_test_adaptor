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

  def handle_call({:prevent, pid, method, path}, _, %{calls: calls}) do
    {:reply, :ok, update_calls(calls, pid, method, path, :raise)}
  end

  def handle_call({:set, pid, method, path, required_headers, response}, _, %{calls: calls}) do
    {:reply, :ok, update_calls(calls, pid, method, path, {required_headers, response})}
  end

  def handle_call({:request, pid, method, path, _body, headers, _opts}, _, state = %{calls: calls}) do
    {:reply, request(get(calls, pid), method, path, headers), state}
  end

  def handle_call(_, _, state), do: {:noreply, state}

  defp get(map, key), do: Map.get(map, key, %{})

  defguardp map_get(map, key) when :erlang.map_get(key, map)

  defp request(call, method, path, headers) when is_map_key(call, path) and is_map_key(map_get(call, path), method) do
    Logger.debug("Hit for #{method} #{path}")

    call
    |> Map.get(path)
    |> Map.get(method)
    |> handle_hit(headers)
  end

  defp request(call, method, path, _headers) do
    Logger.debug("No call found for #{method} #{path} in #{inspect(call)}")
    @not_found
  end

  defp handle_hit([:raise | _], _), do: :raise
  defp handle_hit([], _), do: @not_found

  defp handle_hit([{required_headers, response} | rest], headers) when is_list(headers) do
    if Enum.all?(required_headers, fn {key, value} -> match_headers(headers, key, value) end) do
      response
    else
      handle_hit(rest, headers)
    end
  end

  defp match_headers([{key, value} | _], key, value), do: true
  defp match_headers([_ | rest], key, value), do: match_headers(rest, key, value)
  defp match_headers([], _, _), do: false

  defp set_call(call, method, path, value) do
    Map.put(call, path, Map.update(get(call, path), method, [value], &(&1 ++ [value])))
  end

  defp update_calls(calls, pid, method, path, value) do
    %{calls: Map.put(calls, pid, set_call(get(calls, pid), method, path, value))}
  end
end

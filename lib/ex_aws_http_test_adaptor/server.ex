defmodule ExAwsHttpTestAdaptor.Server do
  use GenServer

  require Logger

  @not_found {404, [], []}

  def init(_) do
    {:ok, %{configured: %{}, received: %{}}}
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

  def handle_call({:calls, pid}, _, state = %{received: calls}), do: {:reply, Map.get(calls, pid, []), state}

  def handle_call({:prevent, pid, method, path}, _, state) do
    {:reply, :ok, update_configured(state, pid, method, path, :raise)}
  end

  def handle_call({:set, pid, method, path, required_headers, response}, _, state) do
    {:reply, :ok, update_configured(state, pid, method, path, {required_headers, response})}
  end

  def handle_call({:request, pid, method, path, body, headers, _opts}, _, state = %{configured: calls}) do
    {:reply, request(get(calls, pid), method, path, headers), record(state, pid, {method, path, headers, body})}
  end

  def handle_call(_, _, state), do: {:noreply, state}

  defp get(map, key), do: Map.get(map, key, %{})

  defguardp map_get(map, key) when :erlang.map_get(key, map)

  defp request(call, method, path, headers) when is_map_key(call, path) and is_map_key(map_get(call, path), method) do
    Logger.debug("Hit for #{method} #{inspect(path)}")

    call
    |> Map.get(path)
    |> Map.get(method)
    |> handle_hit(headers)
  end

  defp request(call, method, path, headers) do
    if found_path = find_regex_path(Enum.into(call, []), path, method) do
      Logger.debug("Looking for call matching #{inspect(found_path)} from #{inspect(path)}")
      request(call, method, found_path, headers)
    else
      Logger.debug("No call found for #{method} #{path} in #{inspect(call)}")
      @not_found
    end
  end

  defp find_regex_path([{%Regex{} = regex_path, call} | rest], path, method) when is_map_key(call, method) do
    if Regex.match?(regex_path, path) do
      regex_path
    else
      find_regex_path(rest, path, method)
    end
  end

  defp find_regex_path([_ | rest], path, method), do: find_regex_path(rest, path, method)
  defp find_regex_path([], _path, _method), do: nil

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

  defp update_configured(state = %{configured: calls}, pid, method, path, value) do
    Map.put(state, :configured, Map.put(calls, pid, set_call(get(calls, pid), method, path, value)))
  end

  defp record(state = %{received: received}, pid, call) do
    Map.put(state, :received, Map.update(received, pid, [call], fn calls -> calls ++ [call] end))
  end
end

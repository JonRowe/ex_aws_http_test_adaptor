defmodule ExAwsHttpTestAdaptor do
  @moduledoc """
  A test http adaptor for ExAws, allows testing responses from AWS by
  swapping out the HTTP adaptor.
  """

  alias ExAwsHttpTestAdaptor.Server

  @behaviour ExAws.Request.HttpClient

  require Logger

  @doc """
  Make a fake request to url with supplied body, headers and opts.
  """
  @impl true
  def request(method, url, req_body, headers, http_opts) do
    verb = String.upcase(to_string(method))
    Logger.debug("[#{inspect self()}] #{verb} call made to #{url}")

    case GenServer.call(Server, {:request, self(), method, url, req_body, headers, http_opts}) do
      {status, response_headers, body} -> {:ok, %{status_code: status, body: body, headers: response_headers}}
      :raise -> raise "Refuted #{verb} to #{url} was called."
    end
  end

  @doc """
  Return calls that have been made.
  """
  def calls(opts \\ []) do
    pid = Keyword.get(opts, :pid, self())
    GenServer.call(Server, {:calls, pid})
  end

  @doc """
  Deliberately cause a failure for a url and method.
  """
  def refute(url, opts \\ []) do
    method = Keyword.get(opts, :method, :get)
    pid = Keyword.get(opts, :pid, self())
    GenServer.call(Server, {:prevent, pid, method, url})
  end

  @doc """
  Set a fake response to url with supplied body, headers and opts.
  """
  def set(url, body \\ [], opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    method = Keyword.get(opts, :method, :get)
    pid = Keyword.get(opts, :pid, self())
    required_headers = Keyword.get(opts, :required_headers, [])
    status = Keyword.get(opts, :status, 200)

    Logger.debug("[#{inspect pid}] #{String.upcase(to_string(method))} set for #{url}")

    GenServer.call(Server, {:set, pid, method, url, required_headers, {status, headers, body}})
  end
end

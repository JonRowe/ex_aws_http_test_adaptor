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
    Logger.debug("Call made to #{url}")

    {status, _headers, body} = GenServer.call(Server, {:request, self(), method, url, req_body, headers, http_opts})

    {:ok, %{status_code: status, body: body}}
  end

  @doc """
  Set a fake response to url with supplied body, headers and opts.
  """
  def set(url, body \\ [], opts \\ []) do
    headers = Keyword.get(opts, :headers, [])
    method = Keyword.get(opts, :method, :get)
    pid = Keyword.get(opts, :pid, self())
    status = Keyword.get(opts, :status, 200)

    GenServer.call(Server, {:set, pid, method, url, status, headers, body})
  end
end

defmodule ExAwsHttpTestAdaptor.ServerTest do
  use ExUnit.Case, async: true

  alias ExAwsHttpTestAdaptor.Server

  describe "init/1" do
    test "it provides an empty state" do
      assert {:ok, %{calls: %{}}} = Server.init(nil)
    end

    test "it is booted on startup" do
      assert is_pid(Process.whereis(Server)) == true
    end
  end

  # def request(method, url, req_body, headers, http_opts) do
  describe "handle_call/2" do
    setup :find_server

    test "it defaults to a 404", %{pid: pid} do
      assert {404, [], []} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
    end

    test "it allows setting a response", %{pid: pid} do
      assert :ok == GenServer.call(pid, {:set, self(), :get, "/some/path", [], {200, [], ["OK"]}})
    end

    test "it returns a previously set response", %{pid: pid} do
      GenServer.call(pid, {:set, self(), :get, "/some/path", [], {200, [], ["OK"]}})
      assert {200, [], ["OK"]} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
    end

    test "it still returns 404 if a set response is a mismatch", %{pid: pid} do
      GenServer.call(pid, {:set, self(), :get, "/other/path", [], {200, [], ["OK"]}})
      assert {404, [], []} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
    end

    test "it supports regular expresions for paths", %{pid: pid} do
      GenServer.call(pid, {:set, self(), :get, ~r{/some}, [], {200, [], ["OK"]}})
      assert {200, [], ["OK"]} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
    end

    test "it supports filtering responses on headers", %{pid: pid} do
      GenServer.call(pid, {:set, self(), :get, "/some/path", [{"allow", "header"}], {200, [], ["OK"]}})
      assert {404, [], []} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})

      header_based_request = {:request, self(), :get, "/some/path", "", [{"allow", "header"}, {"other", "header"}], []}
      assert {200, [], ["OK"]} == GenServer.call(pid, header_based_request)
    end

    test "it supports multiple set responses", %{pid: pid} do
      GenServer.call(pid, {:set, self(), :get, "/some/path", [], {200, [], ["OK"]}})
      GenServer.call(pid, {:set, self(), :post, "/some/path", [], {201, [], ["OK"]}})
      assert {200, [], ["OK"]} == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
      assert {201, [], ["OK"]} == GenServer.call(pid, {:request, self(), :post, "/some/path", "", [], []})
    end

    test "it supports failing (preventing responses)", %{pid: pid} do
      GenServer.call(pid, {:prevent, self(), :get, "/some/path"})
      assert :raise == GenServer.call(pid, {:request, self(), :get, "/some/path", "", [], []})
    end
  end

  defp find_server(_), do: {:ok, pid: Process.whereis(Server)}
end

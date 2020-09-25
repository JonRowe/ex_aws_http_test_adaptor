defmodule ExAwsHttpTestAdaptorTest do
  use ExUnit.Case
  doctest ExAwsHttpTestAdaptor

  test "it will default to the current processes requests" do
    ExAwsHttpTestAdaptor.set("https://amazon.com/s3/", "OK")

    assert {:ok, %{status_code: 200, body: "OK"}} =
             ExAwsHttpTestAdaptor.request(:get, "https://amazon.com/s3/", "", [], [])
  end

  test "it isolates processes" do
    Task.start(fn -> ExAwsHttpTestAdaptor.set("https://amazon.com/s3/", "OK") end)

    assert {:ok, %{status_code: 404, body: []}} =
             ExAwsHttpTestAdaptor.request(:get, "https://amazon.com/s3/", "", [], [])
  end

  test "it supports across process communication" do
    pid = self()

    Task.start(fn ->
      ExAwsHttpTestAdaptor.set("https://amazon.com/s3/", "OK", pid: pid)
      send(pid, :setup)
    end)

    # this blocks until the task has run
    receive do
      :setup -> :done
    end

    assert {:ok, %{status_code: 200, body: "OK"}} =
             ExAwsHttpTestAdaptor.request(:get, "https://amazon.com/s3/", "", [], [])
  end

  test "it will allow refuting a url combo" do
    ExAwsHttpTestAdaptor.refute("https://amazon.com/s3/", method: :delete)

    assert_raise RuntimeError, fn -> ExAwsHttpTestAdaptor.request(:delete, "https://amazon.com/s3/", "", [], []) end
  end

  describe "calls/0" do
    test "it will return current pid calls by default" do
      assert ExAwsHttpTestAdaptor.calls() == []

      ExAwsHttpTestAdaptor.request(:get, "https://amazon.com/s3/", "", [], [])

      assert ExAwsHttpTestAdaptor.calls() == [{:get, "https://amazon.com/s3/", [], ""}]
    end
  end
end

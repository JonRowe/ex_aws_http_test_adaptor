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
end

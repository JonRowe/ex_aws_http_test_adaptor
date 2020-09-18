defmodule ExAwsHttpTestAdaptorTest do
  use ExUnit.Case
  doctest ExAwsHttpTestAdaptor

  test "it will default to the current processes requests" do
    ExAwsHttpTestAdaptor.set("https://amazon.com/s3/", "OK")

    assert {:ok, %{status_code: 200, body: "OK"}} =
             ExAwsHttpTestAdaptor.request(:get, "https://amazon.com/s3/", "", [], [])
  end

  test "it will allow refuting a url combo" do
    ExAwsHttpTestAdaptor.refute("https://amazon.com/s3/", method: :delete)

    assert_raise RuntimeError, fn -> ExAwsHttpTestAdaptor.request(:delete, "https://amazon.com/s3/", "", [], []) end
  end
end

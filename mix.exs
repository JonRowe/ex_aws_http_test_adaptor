defmodule ExAwsHttpTestAdaptor.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aws_http_test_adaptor,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_aws, "~> 2.1"}
    ]
  end
end

defmodule ExAwsHttpTestAdaptor.MixProject do
  use Mix.Project

  @version "0.3.1"

  def project do
    [
      app: :ex_aws_http_test_adaptor,
      deps: deps(),
      description: "A test HTTP adaptor for ExAws.",
      docs: docs(),
      elixir: "~> 1.10",
      package: package(),
      version: @version
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {ExAwsHttpTestAdaptor.Server, []}
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21.3", only: :dev},
      {:ex_aws, "~> 2.1"}
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/JonRowe/ex_aws_http_test_adaptor"
    ]
  end

  defp package do
    [
      maintainers: ["Jon Rowe"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/JonRowe/ex_aws_http_test_adaptor"},
      files: ~w(lib) ++ ~w(mix.exs README.md)
    ]
  end
end

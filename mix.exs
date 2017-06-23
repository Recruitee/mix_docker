defmodule MixDocker.Mixfile do
  use Mix.Project

  def project do
    [
      app: :mix_docker,
      version: "0.5.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),

      description: description(),
      package: package(),

      source_url: "https://github.com/recruitee/mix_docker",
      docs: [main: "readme", extras: ["README.md"]]
    ]
  end

  defp description do
    "Put your Elixir app production release inside minimal docker image"
  end

  defp package do
    [
      maintainers: ["Tymon Tobolski"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/recruitee/mix_docker"}
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:distillery, "~> 1.2"},
      {:ex_doc, "~> 0.10", only: :dev}
    ]
  end
end

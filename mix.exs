defmodule MixDocker.Mixfile do
  use Mix.Project

  def project do
    [app: :mix_docker,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [{:distillery, "0.9.0"}] # see https://github.com/bitwalker/distillery/issues/96
  end
end

defmodule Mix.Tasks.Docker.Init do
  use Mix.Task

  @shortdoc "Initialize distillery release"

  defdelegate run(args), to: MixDocker, as: :init
end

defmodule Mix.Tasks.Docker.Build do
  use Mix.Task

  @shortdoc "Build docker image from distillery release"
  @preferred_cli_env :prod

  defdelegate run(args), to: MixDocker, as: :build
end

defmodule Mix.Tasks.Docker.Release do
  use Mix.Task

  @shortdoc "Build minimal, self-contained docker image"
  @preferred_cli_env :prod

  defdelegate run(args), to: MixDocker, as: :release
end

defmodule Mix.Tasks.Docker.Shipit do
  use Mix.Task

  @shortdoc "Run build & release & publish"
  @preferred_cli_env :prod

  defdelegate run(args), to: MixDocker, as: :shipit
end

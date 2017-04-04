defmodule Mix.Tasks.Docker.Init do
  use Mix.Task

  @shortdoc "Initialize distillery release"
  @moduledoc """
  Initialize distillery release.
  Any arguments and options will be passed directly to
  `mix release.init` task.

  This task also create a default `.dockerignore` file.

  ## Examples

      # Use default options
      mix docker.init

      # Pass distillery config
      mix docker.init --name foobar
  """

  defdelegate run(args), to: MixDocker, as: :init
end

defmodule Mix.Tasks.Docker.Build do
  use Mix.Task

  @shortdoc "Build docker image from distillery release"
  @preferred_cli_env :prod
  @moduledoc """
  Build docker image from distillery release.
  Any arguments and options will be passed directly to
  `docker build` command.

  ## Examples

      # Build your app release
      mix docker.build

      # Skip cache
      mix docker.build --no-cache
  """

  defdelegate run(args), to: MixDocker, as: :build
end

defmodule Mix.Tasks.Docker.Release do
  use Mix.Task

  @shortdoc "Build minimal, self-contained docker image"
  @preferred_cli_env :prod
  @moduledoc """
  Build minimal, self-contained docker image
  Any arguments and options will be passed directly to
  `docker build` command.

  ## Examples

      # Build minimal container
      mix docker.release

      # Skip cache
      mix docker.release --no-cache
  """
  defdelegate run(args), to: MixDocker, as: :release
end

defmodule Mix.Tasks.Docker.Publish do
  use Mix.Task

  @shortdoc "Publish current image to docker registry"
  @preferred_cli_env :prod
  @moduledoc """
  Publish current image to docker registry

  ## Examples

      # Just publish
      mix docker.publish

      # Use different tag for published image
      mix docker.publish --tag "mytag-{mix-version}-{git-branch}"
  """
  defdelegate run(args), to: MixDocker, as: :publish
end

defmodule Mix.Tasks.Docker.Shipit do
  use Mix.Task

  @shortdoc "Run build & release & publish"
  @preferred_cli_env :prod
  @moduledoc """
  Run build & release & publis.
  This is the same as running

      mix do docker.build, docker.release, docker.publish

  You can also pass docker build/publish flags.

  ## Examples

      # Use custom --tag (see docker.publish) and --no-cache for docker build
      mix docker.shipit --tag my-custom-tag --no-cache
  """
  defdelegate run(args), to: MixDocker, as: :shipit
end

defmodule Mix.Tasks.Docker.Customize do
  use Mix.Task

  @shortdoc "Copy & customize Dockerfiles"
  @preferred_cli_env :prod
  @moduledoc """
  Copy & customize Dockerfiles
  This task will copy Dockerfile.build and Dockerfile.release
  into project's directory for further customization.
  """

  defdelegate run(args), to: MixDocker, as: :customize
end

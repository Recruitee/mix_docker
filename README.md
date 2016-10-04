# mix docker

Put your Elixir app inside minimal docker image based on alpine linux.
Based on distillery releases.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `mix_docker` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:mix_docker, "~> 0.1.0"}]
    end
    ```

  2. Configure docker image name

    ```elixir
    # config/config.exs
    config :mix_docker, image: "recruitee/hello"
    ```

  3. Run `mix docker.init` to init distillery release configuration

## Usage

### Build release
Run `mix docker.build` to build a release inside docker container

### Create run container
Run `mix docker.release` to put the release inside minimal docker image

### Publish to docker registry
Run `mix docker.publish` to push newly created image to docker registry

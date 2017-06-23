# mix docker

[![Build Status](https://travis-ci.org/Recruitee/mix_docker.svg?branch=master)](https://travis-ci.org/Recruitee/mix_docker)

Put your Elixir app inside minimal Docker image.
Based on [alpine linux](https://hub.docker.com/r/bitwalker/alpine-erlang/)
and [distillery](https://github.com/bitwalker/distillery) releases.

## Installation

  1. Add `mix_docker` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:mix_docker, "~> 0.5.0"}]
end
```

  2. Configure Docker image name

```elixir
# config/config.exs
config :mix_docker, image: "recruitee/hello"
```

  3. Run `mix docker.init` to init distillery release configuration

  4. Run `mix docker.build` & `mix docker.release` to build the image. See [Usage](#Usage) for more.


## Guides

- [Getting Started Tutorial](http://teamon.eu/2017/deploying-phoenix-to-production-using-docker/)
- [Setting up cluster with Rancher](http://teamon.eu/2017/setting-up-elixir-cluster-using-docker-and-rancher/)
- [Phoenix App Configuration Walkthrough](https://shovik.com/blog/8-deploying-phoenix-apps-with-docker)

## Usage

### Build a release
Run `mix docker.build` to build a release inside docker container

### Create minimal run container
Run `mix docker.release` to put the release inside minimal docker image

### Publish to docker registry
Run `mix docker.publish` to push newly created image to docker registry

### All three in one pass
Run `mix docker.shipit`

### Customize default Dockerfiles
Run `mix docker.customize`


## FAQ

#### How to configure my app?

Using ENV variables.
The provided Docker images contain `REPLACE_OS_VARS=true`, so you can use `"${VAR_NAME}"` syntax in `config/prod.exs`
like this:

```elixir
config :hello, Hello.Endpoint,
  server: true,
  url: [host: "${DOMAIN}"]

config :hello, Hello.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: "${MAILGUN_API_KEY}"
```

#### How to configure the image tag?

By default, the image tag uses the following format: `{mix-version}.{git-count}-{git-sha}`
You can provide your own tag template in `config/prod.exs` like this:

```elixir
# config/config.exs
config :mix_docker,
  tag: "dev_{mix-version}_{git-sha}"
```

Additionally, you can pass the tag as an argument to `mix docker.publish` and `mix docker.shipit`:

```bash
mix docker.publish --tag "{mix-version}-{git-branch}"
```

See below for a list of possible variables

| Variable        | Description                            |
|-----------------|----------------------------------------|
| `{mix-version}` | Current project version from `mix.exs` |
| `{rel-version}` | Default distillery release version     |
| `{git-sha}`     | Git commit SHA (10 characters)         |
| `{git-shaN}`    | Git commit SHA (N characters)          |
| `{git-count}`   | Git commit count                       |
| `{git-branch}`  | Git branch                             |


#### What version of Erlang/Elixir is installed by default?
The default dockerfiles are based on [bitwalker/alpine-erlang](https://github.com/bitwalker/alpine-erlang) and elixir installed from [apk repository](https://pkgs.alpinelinux.org/packages?name=elixir&branch=&repo=&arch=&maintainer=)

The following table summarizes the default versions:

| mix_docker version   | alpine   | erlang   | elixir                             |
|----------------------|----------|----------|------------------------------------|
| up to `0.3.2`        | `3.4`    | `18.3`   | `elixir@edge` at the time of build |
| `0.4.0`              | `3.5`    | `19.2`   | `elixir@edge=1.4.1-r0`             |
| `0.4.1`              | `3.5`    | `19.2`   | `elixir@edge=1.4.2-r0`             |

Please note that you can use any version you want by customizing your dockerfiles. See `mix docker.customize` for reference.


#### How to attach to running app using remote_console?

The easiest way is to `docker exec` into running container and run the following command,
where `CID` is the app container IO and `hello` is the name of your app.

```bash
docker exec -it CID /opt/app/bin/hello remote_console
```

#### [Using alternative Dockerfiles](https://github.com/Recruitee/mix_docker/wiki/Alternative-Dockerfiles)

#### How to install additional packages into build/release image?

First, run `mix docker.customize` to copy `Dockerfile.build` and `Dockerfile.release` into your project directory.
Now you can add whatever you like using standard Dockerfile commands.
Feel free to add some more apk packages or run some custom commands.
TIP: To keep the build process efficient check whether a given package is required only for
compilation (build) or runtime (release) or both.

#### How to move the Dockerfiles?

You can specify where to find the two Dockerfiles in the config.

```elixir
# config/config.exs
config :mix_docker,
  dockerfile_build: "path/to/Dockerfile.build",
  dockerfile_release: "path/to/Dockerfile.release"
```

The path is relative to the project root, and the files must be located inside
the root.


#### How to configure an Umbrella app?

The default build Dockerfile does not handle the installation of umbrella app
deps, so you will need to modify it to match the structure of your project.

Run `mix docker.customize` and then edit `Dockerfile.build` to copy across
each of your umbrella's applications.

```dockerfile
COPY mix.exs mix.lock ./

RUN mkdir -p apps/my_first_app/config
COPY apps/my_first_app/mix.exs apps/my_first_app/
COPY apps/my_first_app/config/* apps/my_first_app/config/

RUN mkdir -p apps/my_second_app/config
COPY apps/my_second_app/mix.exs apps/my_second_app/
COPY apps/my_second_app/config/* apps/my_second_app/config/

# etc.
```


#### How to configure a Phoenix app?

To run a Phoenix app you'll need to install additional packages into the build image: run `mix docker.customize`.

Modify the `apk --no-cache --update add` command in the `Dockerfile.build` as follows (add `nodejs` and `python`):

```
# Install Elixir and basic build dependencies
RUN \
    echo "@edge http://nl.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk update && \
    apk --no-cache --update add \
      git make g++ \
      nodejs python \
      elixir@edge && \
    rm -rf /var/cache/apk/*
```

Install nodejs dependencies and cache them by adding the following lines before the `COPY` command:

```
# Cache node deps
COPY package.json ./
RUN npm install
```

Build and digest static assets by adding the following lines after the `COPY` command:

```
RUN ./node_modules/brunch/bin/brunch b -p && \
    mix phoenix.digest
```

Add the following directories to `.dockerignore`:

```
node_modules
priv/static
```

Remove `config/prod.secret.exs` file and remove a reference to it from `config/prod.exs`. Configure your app's secrets directly in `config/prod.exs` using the environment variables.

Make sure to add `server: true` to your app's Endpoint config.

Build the images and run the release image normally.

Check out [this post](https://shovik.com/blog/8-deploying-phoenix-apps-with-docker) for detailed walkthrough of the Phoenix app configuration.

# mix docker

[![Build Status](https://travis-ci.org/Recruitee/mix_docker.svg?branch=master)](https://travis-ci.org/Recruitee/mix_docker)

Put your Elixir app inside minimal Docker image.
Based on [alpine linux](https://hub.docker.com/r/bitwalker/alpine-erlang/)
and [distillery](https://github.com/bitwalker/distillery) releases.

## Installation

  1. Add `mix_docker` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:mix_docker, "~> 0.3.0"}]
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


#### How to attach to running app using remote_console?

The easiest way is to `docker exec` into running container and run the following command,
where `CID` is the app container IO and `hello` is the name of your app.

```bash
docker exec -it CID /opt/app/bin/hello remote_console
```


#### How to install additional packages into build/release image?

First, run `mix docker.customize` to copy `Dockerfile.build` and `Dockerfile.release` into your project directory.
Now you can add whatever you like using standard Dockerfile commands.
Feel free to add some more apk packages or run some custom commands.
TIP: To keep the build process efficient check whether a given package is required only for
compilation (build) or runtime (release) or both.


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

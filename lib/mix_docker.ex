defmodule MixDocker do
  require Logger

  @dockerfile_path    :code.priv_dir(:mix_docker)
  @dockerfile_build   Application.get_env(:mix_docker, :dockerfile_build, "Dockerfile.build")
  @dockerfile_release Application.get_env(:mix_docker, :dockerfile_release, "Dockerfile.release")

  def init(args) do
    # copy .dockerignore
    unless File.exists?(".dockerignore") do
      File.cp(Path.join([@dockerfile_path, "dockerignore"]), ".dockerignore")
    end

    Mix.Task.run("release.init", args)
  end

  def build(args) do
    with_dockerfile @dockerfile_build, fn ->
      docker :build, @dockerfile_build, image(:build), args
    end

    Mix.shell.info "Docker image #{image(:build)} has been successfully created"
  end

  def release(args) do
    project = Mix.Project.get.project
    app     = project[:app]
    version = project[:version]

    cid = "mix_docker-#{:rand.uniform(1000000)}"

    with_dockerfile @dockerfile_release, fn ->
      docker :rm, cid
      docker :create, cid, image(:build)
      docker :cp, cid, "/opt/app/_build/prod/rel/#{app}/releases/#{version}/#{app}.tar.gz", "#{app}.tar.gz"
      docker :rm, cid
      docker :build, @dockerfile_release, image(:release), args
    end

    Mix.shell.info "Docker image #{image(:release)} has been successfully created"
    Mix.shell.info "You can now test your app with the following command:"
    Mix.shell.info "  docker run -it --rm #{image(:release)} foreground"
  end

  def publish(args) do
    name = image(version: image_version(args))

    docker :tag, image(:release), name
    docker :push, name

    Mix.shell.info "Docker image #{name} has been successfully created"
  end

  def shipit(args) do
    build(args)
    release(args)
    publish(args)
  end

  def customize([]) do
    try_copy_dockerfile @dockerfile_build
    try_copy_dockerfile @dockerfile_release
  end

  defp git_head_sha do
    with true <- File.regular?(".git"),
         {sha, 0} <- System.cmd("git", ["rev-parse", "HEAD"]) do
      String.slice(sha, 0, 10)
    else
      _ -> ""
    end
  end

  defp git_commit_count do
    with true <- File.regular?(".git"),
         {count, 0} <- System.cmd("git", ["rev-list", "--count", "HEAD"]) do
      String.trim(count)
    else
      _ -> ""
    end
  end

  defp image(tag) do
    image_name() <> ":" <> to_string(image_tag(tag))
  end

  defp image_name do
    Application.get_env(:mix_docker, :image) || to_string(Mix.Project.get.project[:app])
  end

  defp image_tag(version: version_template) do
    version = Mix.Project.get.project[:version]
    count   = git_commit_count()
    sha     = git_head_sha()

    version_template
    |> String.replace("$mix_version", version)
    |> String.replace("$git_count", count)
    |> String.replace("$git_sha", sha)
  end
  defp image_tag(tag), do: tag

  defp image_version(args) do
    OptionParser.parse(args) |> elem(0) |> Keyword.get(:version)
    || Application.get_env(:mix_docker, :version)
    || "$mix_version.$git_count-$git_sha"
  end

  defp docker(:cp, cid, source, dest) do
    system! "docker", ["cp", "#{cid}:#{source}", dest]
  end

  defp docker(:build, dockerfile, tag, args) do
    system! "docker", ["build", "-f", dockerfile, "-t", tag] ++ args ++ ["."]
  end

  defp docker(:create, name, image) do
    system! "docker", ["create", "--name", name, image]
  end

  defp docker(:tag, image, tag) do
    system! "docker", ["tag", image, tag]
  end

  defp docker(:rm, cid) do
    system "docker", ["rm", "-f", cid]
  end

  defp docker(:push, image) do
    system! "docker", ["push", image]
  end

  defp with_dockerfile(name, fun) do
    if File.exists?(name) do
      fun.()
    else
      try do
        copy_dockerfile(name)
        fun.()
      after
        File.rm(name)
      end
    end
  end

  defp copy_dockerfile(name) do
    app = Mix.Project.get.project[:app]
    content = [@dockerfile_path, name]
      |> Path.join
      |> File.read!
      |> String.replace("${APP}", to_string(app))
    File.write!(name, content)
  end

  defp try_copy_dockerfile(name) do
    if File.exists?(name) do
      Logger.warn("#{name} already exists")
    else
      copy_dockerfile(name)
    end
  end

  defp system(cmd, args) do
    Logger.debug "$ #{cmd} #{args |> Enum.join(" ")}"
    System.cmd(cmd, args, into: IO.stream(:stdio, :line))
  end

  defp system!(cmd, args) do
    {_, 0} = system(cmd, args)
  end
end

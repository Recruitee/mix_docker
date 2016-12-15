defmodule MixDocker do
  require Logger

  @dockerfile_path    :code.priv_dir(:mix_docker)
  @dockerfile_build   "Dockerfile.build"
  @dockerfile_release "Dockerfile.release"

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
      docker :cp, cid, "/opt/app/rel/#{app}/releases/#{version}/#{app}.tar.gz", "#{app}.tar.gz"
      docker :rm, cid
      docker :build, @dockerfile_release, image(:release), args
    end

    Mix.shell.info "Docker image #{image(:release)} has been successfully created"
    Mix.shell.info "You can now test your app with the following command:"
    Mix.shell.info "  docker run -it --rm #{image(:release)} foreground"
  end

  def publish(_args) do
    name = image(:version)

    docker :tag, image(:release), name
    docker :push, name

    Mix.shell.info "Docker image #{name} has been successfully created"
  end

  def shipit(args) do
    build(args)
    release(args)
    publish(args)
  end

  defp git_head_sha do
    {sha, 0} = System.cmd "git", ["rev-parse", "HEAD"]
    String.slice(sha, 0, 10)
  end

  defp git_commit_count do
    {count, 0} = System.cmd "git", ["rev-list", "--count", "HEAD"]
    String.trim(count)
  end

  defp image(tag) do
    image_name <> ":" <> to_string(image_tag(tag))
  end

  defp image_name do
    Application.get_env(:mix_docker, :image) || to_string(Mix.Project.get.project[:app])
  end

  defp image_tag(:version) do
    version = Mix.Project.get.project[:version]
    count   = git_commit_count
    sha     = git_head_sha

    "#{version}.#{count}-#{sha}"
  end
  defp image_tag(tag), do: tag


  defp docker(:cp, cid, source, dest) do
    system! "docker", ["cp", "#{cid}:#{source}", dest]
  end

  defp docker(:build, dockerfile, tag, args) do
    system! "docker", ["build", "-f", dockerfile, "-t", tag] ++ args ++ ["."]
  end

  defp docker(:create, name, image) do
    system! "docker", ["create", "--name", name, image]
  end

  defp docker(:rm, cid) do
    system "docker", ["rm", "-f", cid]
  end

  defp docker(:push, image) do
    system! "docker", ["push", image]
  end

  defp docker(:tag, image, tag) do
    system! "docker", ["tag", image, tag]
  end


  defp with_dockerfile(name, fun) do
    if File.exists?(name) do
      fun.()
    else
      app = Mix.Project.get.project[:app]

      try do
        content = [@dockerfile_path, name]
          |> Path.join
          |> File.read!
          |> String.replace("${APP}", to_string(app))
        File.write!(name, content)
        fun.()
      after
        File.rm(name)
      end
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

defmodule MixDocker do
  require Logger

  @dockerfile_path    :code.priv_dir(:mix_docker)
  @dockerfile_build   "Dockerfile.build"
  @dockerfile_release "Dockerfile.release"

  def init(args) do
    Mix.Task.run("release.init", args)
  end

  def build(_args) do
    project = Mix.Project.get.project
    app     = project[:app]
    version = project[:version]
    image   = "build-#{git_head_sha}"

    with_dockerfile @dockerfile_build, fn ->
      docker :build, @dockerfile_build, "build"
      docker :rm, image
      docker :create, image, "build"
      docker :cp, image, "/opt/app/rel/#{app}/releases/#{version}/#{app}.tar.gz", "#{app}.tar.gz"
      docker :rm, image
    end
  end

  def release(_args) do
    image = image_name

    with_dockerfile @dockerfile_release, fn ->
      docker :build, @dockerfile_release, image
    end

    Mix.shell.info "Docker image #{image} has been successfully created"
  end

  def publish(_args) do
    docker :push, image_name
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

  defp image_name do
    project = Mix.Project.get.project
    app     = project[:app]
    version = project[:version]

    name  = Application.get_env(:mix_docker, :image, to_string(app))

    count = git_commit_count
    sha   = git_head_sha

    "#{name}:#{version}.#{count}-#{sha}"
  end

  defp docker(:cp, cid, source, dest) do
    system! "docker", ["cp", "#{cid}:#{source}", dest]
  end

  defp docker(:build, dockerfile, tag) do
    system! "docker", ["build", "-f", dockerfile, "-t", tag, "."]
  end

  defp docker(:create, name, image) do
    system! "docker", ["create", "--name", name, image]
  end

  defp docker(:rm, image) do
    system "docker", ["rm", "-f", image]
  end

  defp docker(:push, image) do
    system! "docker", ["push", image]
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

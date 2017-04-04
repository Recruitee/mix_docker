defmodule MixDockerTest do
  use ExUnit.Case
  doctest MixDocker

  @single   "test/test-app"
  @umbrella "test/test-umbrella"

  defmacro inapp(dir, do: body) do
    quote do
      File.cd!(unquote(dir), fn -> unquote(body) end)
    end
  end

  def mix(task, args \\ []) do
    IO.puts "$ mix #{task}"
    assert {_, 0} = System.cmd("mix", [task | args], into: IO.stream(:stdio, :line))
  end

  def cleanup(%{dir: dir} = tags) do
    inapp(dir) do
      File.rm_rf! "rel"
      File.rm_rf! "app.tar.gz"
      File.rm_rf! "deps"
      File.rm_rf! "mix.lock"
      File.rm_rf! "Dockerfile.build"
      File.rm_rf! "Dockerfile.release"
      File.rm_rf! "vendor/mix_docker"
      File.mkdir_p! "vendor/mix_docker"
      File.cp_r! "../../config",   "vendor/mix_docker/config"
      File.cp_r! "../../deps",     "vendor/mix_docker/deps"
      File.cp_r! "../../lib",      "vendor/mix_docker/lib"
      File.cp_r! "../../priv",     "vendor/mix_docker/priv"
      File.cp_r! "../../mix.exs",  "vendor/mix_docker/mix.exs"

      mix "deps.get"
    end

    {:ok, tags}
  end

  describe "single" do
    setup [:cleanup]

    @tag dir: @single
    test "everything", %{dir: dir} do
      inapp(dir) do
        mix "docker.init"

        assert File.exists?(".dockerignore")
        assert File.exists?("rel/config.exs")

        mix "docker.build"

        mix "docker.release"
      end
    end

    @tag dir: @single
    test "customize", %{dir: dir} do
      inapp(dir) do
        mix "docker.customize"

        assert File.exists?("Dockerfile.build")
        assert File.exists?("Dockerfile.release")
      end
    end
  end



  @tag dir: @umbrella
  describe "umbrella" do
    setup [:cleanup]

    test "everything", %{dir: dir} do
      inapp(dir) do
        mix "docker.init"

        assert File.exists?(".dockerignore")
        assert File.exists?("rel/config.exs")

        mix "docker.build"

        mix "docker.release"
      end
    end
  end
end

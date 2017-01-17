defmodule MixDockerTest do
  use ExUnit.Case
  doctest MixDocker

  @appdir "test-app"
  defmacro inapp(do: body) do
    quote do
      File.cd!(@appdir, fn -> unquote(body) end)
    end
  end

  def mix(task, args \\ []) do
    IO.puts "$ mix #{task}"
    assert {_, 0} = System.cmd("mix", [task | args], into: IO.stream(:stdio, :line))
  end

  setup do
    inapp do
      File.rm_rf "rel"
      File.rm_rf "app.tar.gz"
      File.rm_rf "deps"
      File.rm_rf "mix.lock"

      mix "deps.get"
    end

    :ok
  end

  test "everything" do
    inapp do
      mix "docker.init"

      assert File.exists?(".dockerignore")
      assert File.exists?("rel/config.exs")

      mix "docker.build"

      mix "docker.release"
    end
  end

  test "customize" do
    inapp do
      mix "docker.customize"

      assert File.exists?("Dockerfile.build")
      assert File.exists?("Dockerfile.release")
    end
  end
end

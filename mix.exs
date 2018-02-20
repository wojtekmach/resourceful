defmodule Resourceful.MixProject do
  use Mix.Project

  def project do
    [
      app: :resourceful,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp aliases do
    [
      test: ["test", &test_bloggy/1]
    ]
  end

  defp test_bloggy(_) do
    cmd(~w(mix test), cd: "examples/bloggy")
  end

  defp cmd([command | args], opts) do
    opts = Keyword.put_new(opts, :into, IO.stream(:stdio, :line))
    {_, 0} = System.cmd(command, args, opts)
  end
end

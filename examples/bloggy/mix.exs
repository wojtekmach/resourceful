defmodule Bloggy.Mixfile do
  use Mix.Project

  def project do
    [
      app: :bloggy,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Bloggy.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:resourceful, path: "../../"}
    ]
  end

  defp aliases do
    [
      "setup": ["deps.get", &setup_yarn/1, "ecto.drop", "ecto.create", "ecto.migrate", &maybe_seed/1],
      server: ["phx.server"],
      "test": ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp maybe_seed(_) do
    if Mix.env() == :dev do
      Mix.Tasks.Run.run(["priv/repo/seeds.exs"])
    end
  end

  defp setup_yarn(_) do
    cmd(~w(yarn install), cd: "assets")
  end

  defp cmd([command | args], opts) do
    opts = Keyword.put_new(opts, :into, IO.stream(:stdio, :line))
    {_, 0} = System.cmd(command, args, opts)
  end
end

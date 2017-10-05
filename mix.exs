defmodule EctoSharding.Mixfile do
  use Mix.Project

  def project do
    [
      app: :ecto_sharding,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mariaex, ">= 0.8.2"},
      {:ecto, "~> 2.2"},
      {:ex_doc, "~> 0.11.0", only: :dev},
      {:earmark, ">= 0.0.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end

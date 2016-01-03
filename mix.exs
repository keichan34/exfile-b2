defmodule ExfileB2.Mixfile do
  use Mix.Project

  def project do
    [app: :exfile_b2,
     version: "0.0.1",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {ExfileB2, []},
      applications: [
        :logger,
        :exfile,
        :httpoison,
        :crypto
      ],
      included_applications: [
        :poison
      ]
    ]
  end

  defp deps do
    [
      {:exfile, ">= 0.0.3"},
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.5"}
    ]
  end
end

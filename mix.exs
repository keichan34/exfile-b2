defmodule ExfileB2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfile_b2,
      version: "0.0.3",
      elixir: "~> 1.2",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      source_url: "https://github.com/keichan34/exfile-b2",
      docs: [
        extras: ["README.md"]
      ],
      package: package,
      description: description
   ]
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
      {:exfile, "~> 0.0.4"},
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.5"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Keitaroh Kobayashi"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/keichan34/exfile-b2"
      }
    ]
  end

  defp description do
    """
    A Backblaze B2 storage backend adapter for Exfile.
    """
  end
end

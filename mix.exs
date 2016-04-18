defmodule ExfileB2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfile_b2,
      version: "0.2.0",
      elixir: "~> 1.2.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      source_url: "https://github.com/keichan34/exfile-b2",
      docs: [
        extras: ["README.md"]
      ],
      package: package,
      description: description,
      dialyzer: [
        plt_file: ".local.plt",
        plt_add_apps: [
          :exfile,
          :httpoison,
          :poison
        ]
      ],
      aliases: [
        "publish": [&git_tag/1, "hex.publish", "hex.docs"]
      ]
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
        :crypto,
        :poison
      ]
    ]
  end

  defp deps do
    [
      {:exfile, "~> 0.3.1"},
      {:httpoison, "~> 0.8.0"},
      {:poison, "~> 1.5"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Keitaroh Kobayashi"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/keichan34/exfile-b2",
        "Docs" => "http://hexdocs.pm/exfile_b2/readme.html"
      }
    ]
  end

  defp description do
    """
    A Backblaze B2 storage backend adapter for Exfile.
    """
  end

  defp git_tag(_args) do
    version_tag = case Version.parse(project[:version]) do
      {:ok, %Version{pre: []}} ->
        "v" <> project[:version]
      _ ->
        raise "Version should be a release version."
    end
    System.cmd "git", ["tag", "-a", version_tag, "-m", "Release #{version_tag}"]
    System.cmd "git", ["push", "--tags"]
  end
end

defmodule ExfileB2.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exfile_b2,
      version: "0.2.1",
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
        :b2_client,
      ]
    ]
  end

  defp deps do
    [
      {:exfile, "~> 0.3.1"},
      {:b2_client, "~> 0.0.1"},
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
end

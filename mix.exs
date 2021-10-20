defmodule PatternMetonyms.MixProject do
  use Mix.Project

  def version, do: "0.5.0"

  defp description do
    """
    Haskell's pattern synonyms for Elixir
    """
  end

  def project do
    [
      app: :pattern_metonyms,
      version: version(),
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: git_repository(),
      deps: deps(),
      docs: docs(),
      elixirc_options: [warnings_as_errors: true],
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
    ]
  end

  defp deps do
    [
      {:circe, "~> 0.1"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => git_repository(),
        "Paper" => "https://www.microsoft.com/en-us/research/publication/pattern-synonyms/",
        "Changelog" => "https://hexdocs.pm/pattern_metonyms/changelog.html",
      },
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "README.md": [title: "Overview"],
      ],
      api_reference: false,
      main: "readme",
      source_url: git_repository(),
      source_ref: "v#{version()}",
    ]
  end

  defp git_repository do
    "https://github.com/Shakadak/pattern_metonyms"
  end
end

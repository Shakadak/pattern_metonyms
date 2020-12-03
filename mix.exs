defmodule PatternMetonyms.MixProject do
  use Mix.Project

  defp description do
    """
    Haskell's pattern synonyms for Elixir
    """
  end

  def project do
    [
      app: :pattern_metonyms,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: git_repository(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => git_repository(),
        "Paper" => "https://www.microsoft.com/en-us/research/publication/pattern-synonyms/",
      },
    ]
  end

  defp git_repository do
    "https://github.com/Shakadak/pattern_metonyms"
  end
end

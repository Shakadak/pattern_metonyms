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
      version: "0.3.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      source_url: git_repository(),
      deps: deps(),
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
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
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

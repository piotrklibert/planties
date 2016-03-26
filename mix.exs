defmodule Planties.Mixfile do
  use Mix.Project

  def project do
    [app: :planties,
     version: "0.0.1",
     elixir: "~> 1.3-dev",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :mix, :elixir_ale, :pattern_tap],
     mod: {Planties, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:elixir_ale, "~> 0.4.1"},
      {:pattern_tap, git: "git@github.com:mgwidmann/elixir-pattern_tap.git"},
      {:exrm, "~> 0.18.1"}
    ]
  end
end

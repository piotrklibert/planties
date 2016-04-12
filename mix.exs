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
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :mix, :elixir_ale, :pattern_tap, :porcelain],
     mod: {Planties, []}]
  end

  defp deps, do: [
      {:elixir_ale, "~> 0.4.1"},
      {:pattern_tap, git: "git@github.com:mgwidmann/elixir-pattern_tap.git"},
      {:logger_file_backend, git: "https://github.com/onkel-dirtus/logger_file_backend"},
      {:exrm, "~> 0.18.1"},
      {:porcelain, "~> 2.0"},
      {:skel, git: "git@github.com:ParaPhrase/skel.git"}
    ]
end

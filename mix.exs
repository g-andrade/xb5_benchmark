defmodule Xb5Benchmark.MixProject do
  use Mix.Project

  def project do
    [
      app: :xb5_benchmark,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
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
      {:jason, "~> 1.4"},
      {:statistex, "~> 1.1"},
      {:taskforce, "~> 1.2"},
      {:typed_struct, "~> 0.3"},
      {:xb5, git: "https://github.com/g-andrade/xb5.git", branch: "main"}
    ]
  end
end

defmodule Precheck.MixProject do
  use Mix.Project

  @version "1.0.0"

  def project do
    [
      app: :precheck,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.37.1", runtime: false}
    ]
  end

  defp escript do
    [main_module: Precheck.CLI]
  end
end

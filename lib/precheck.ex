defmodule Precheck do
  @moduledoc """
  Precheck - Secure pre-deployment toolkit.

  Scripts are embedded and encrypted in the native binary.
  Users cannot access raw script source code.
  """

  @version "1.0.0"

  def version, do: @version

  @doc "Run all pre-deployment checks"
  def run(opts \\ []) do
    path = Keyword.get(opts, :path, ".")

    with :ok <- Precheck.Scanner.check_secrets(path),
         :ok <- Precheck.Scanner.check_environment(path) do
      {:ok, "All checks passed"}
    end
  end
end

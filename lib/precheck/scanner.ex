defmodule Precheck.Scanner do
  @moduledoc """
  High-level scanner interface.
  Delegates to Native module for actual scanning.
  """

  def check_secrets(path) do
    case Precheck.Native.run_checks(path) do
      {:ok, []} -> :ok
      {:ok, findings} -> {:error, {:secrets_found, findings}}
      {:error, _} = err -> err
    end
  end

  def check_environment(_path) do
    # Placeholder for environment checks
    :ok
  end
end

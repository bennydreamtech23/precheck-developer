defmodule Precheck.Native do
  @moduledoc """
  Rust NIF interface.

  All sensitive logic (including embedded scripts) lives in the Rust binary.
  This module provides the Elixir interface.
  """
  use Rustler,
    otp_app: :precheck,
    crate: "precheck_native"

  @doc "Run all security checks on a path"
  def run_checks(_path), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Scan for secrets in content"
  def scan_secrets(_content, _filename), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Execute embedded script by name (decrypts at runtime)"
  def execute_script(_script_name, _args), do: :erlang.nif_error(:nif_not_loaded)

  @doc "Get list of available checks"
  def list_checks, do: :erlang.nif_error(:nif_not_loaded)
end

defmodule Precheck.Native.ScanResult do
  @moduledoc "Result struct from native scanner"
  defstruct [:file, :line, :pattern, :matched]
end

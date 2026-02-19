defmodule Precheck.Native do
  @moduledoc """
  Rust NIF interface.

  All sensitive logic (including embedded scripts) lives in the Rust binary.
  This module provides the Elixir interface.
  """

  # Explicitly load the NIF from the new install path
  @on_load :load_nif

  def load_nif do
    ext = nif_extension()
    lib_name = "precheck_native#{ext}"

    candidate_paths = [
      "/usr/local/lib/precheck/priv/native/#{lib_name}",
      Path.join([to_string(:code.priv_dir(:precheck)), "native", lib_name]),
      Path.join([
        Path.dirname(escript_path()),
        "..",
        "lib",
        "precheck",
        "priv",
        "native",
        lib_name
      ])
    ]

    case Enum.find(candidate_paths, &File.exists?/1) do
      nil ->
        {:error, {:load_failed, "NIF library not found in known paths: #{Enum.join(candidate_paths, ", ")}"}}

      nif_path ->
        :erlang.load_nif(strip_extension(nif_path, ext), 0)
    end
  end

  defp nif_extension do
    case :os.type() do
      {:unix, :darwin} -> ".dylib"
      _ -> ".so"
    end
  end

  defp escript_path do
    case :escript.script_name() do
      [] -> "."
      charlist -> List.to_string(charlist)
    end
  end

  defp strip_extension(path, ext) do
    String.trim_trailing(path, ext)
  end

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

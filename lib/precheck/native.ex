defmodule Precheck.Native.ScanResult do
  @moduledoc "Result struct from scanner"
  defstruct [:file, :line, :pattern, :matched]
end

defmodule Precheck.Native do
  @moduledoc """
  Pure Elixir security scanner interface.

  This replaces the previous Rust NIF implementation so the project can run
  and be released as a single open-source repository without a Rust toolchain.
  """

  @exclude_dirs MapSet.new([".git", "_build", "deps", "node_modules", "dist"])

  @doc "Run all security checks on a path"
  def run_checks(path) do
    path
    |> collect_files()
    |> Enum.flat_map(&scan_file/1)
    |> then(&{:ok, &1})
  rescue
    error -> {:error, Exception.message(error)}
  end

  @doc "Scan for secrets in content"
  def scan_secrets(content, filename) when is_binary(content) do
    content
    |> String.split("\n")
    |> Enum.with_index(1)
    |> Enum.flat_map(fn {line, line_number} ->
      Enum.flat_map(check_patterns(), fn {label, pattern} ->
        if Regex.match?(pattern, line) do
          [
            %Precheck.Native.ScanResult{
              file: filename,
              line: line_number,
              pattern: label,
              matched: String.trim(line)
            }
          ]
        else
          []
        end
      end)
    end)
  end

  @doc "Not used in the script-first OSS flow"
  def execute_script(_script_name, _args), do: {:error, :not_supported}

  @doc "Get list of available checks"
  def list_checks do
    ["secrets", "files"]
  end

  defp collect_files(path) do
    if File.regular?(path) do
      [path]
    else
      path
      |> Path.expand()
      |> walk([])
    end
  end

  defp check_patterns do
    [
      {"AWS Access Key", ~r/AKIA[0-9A-Z]{16}/},
      {"GitHub Token", ~r/ghp_[0-9A-Za-z]{36}/},
      {"OpenAI Key", ~r/sk-[A-Za-z0-9]{20,}/},
      {"Hardcoded Password", ~r/password\s*[:=]\s*["'][^"']{4,}["']/i},
      {"Generic Secret", ~r/secret\s*[:=]\s*["'][^"']{8,}["']/i},
      {"Private Key", ~r/-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----/}
    ]
  end

  defp walk(dir, acc) do
    case File.ls(dir) do
      {:ok, entries} ->
        Enum.reduce(entries, acc, fn entry, files ->
          full_path = Path.join(dir, entry)

          cond do
            File.dir?(full_path) and MapSet.member?(@exclude_dirs, entry) ->
              files

            File.dir?(full_path) ->
              walk(full_path, files)

            File.regular?(full_path) ->
              [full_path | files]

            true ->
              files
          end
        end)

      {:error, _} ->
        acc
    end
  end

  defp scan_file(file_path) do
    case File.read(file_path) do
      {:ok, content} when is_binary(content) and byte_size(content) > 0 ->
        if String.valid?(content) do
          scan_secrets(content, file_path)
        else
          []
        end

      _ ->
        []
    end
  end
end

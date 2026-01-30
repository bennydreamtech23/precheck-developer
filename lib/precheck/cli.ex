defmodule Precheck.CLI do
  @moduledoc "Command-line interface for precheck"

  def main(args) do
    args
    |> parse_args()
    |> execute()
  end

  defp parse_args(args) do
    {opts, commands, _} =
      OptionParser.parse(args,
        switches: [
          help: :boolean,
          version: :boolean,
          path: :string,
          format: :string
        ],
        aliases: [h: :help, v: :version, p: :path, f: :format]
      )

    {opts, commands}
  end

  defp execute({opts, _commands}) do
    cond do
      opts[:help] -> print_help()
      opts[:version] -> print_version()
      true -> run_checks(opts)
    end
  end

  defp run_checks(opts) do
    path = opts[:path] || "."
    format = opts[:format] || "text"

    IO.puts("🔍 Precheck v#{Precheck.version()} - Running security checks...\n")

    case Precheck.Native.run_checks(path) do
      {:ok, results} ->
        output_results(results, format)

      {:error, reason} ->
        IO.puts("❌ Error: #{reason}")
        System.halt(1)
    end
  end

  defp output_results(results, "text") do
    if Enum.empty?(results) do
      IO.puts("✅ No security issues found!")
    else
      IO.puts("⚠️  Found #{length(results)} potential issues:\n")

      Enum.each(results, fn result ->
        IO.puts("  #{result.file}:#{result.line} - #{result.pattern}")
        IO.puts("    └─ #{result.matched}\n")
      end)

      System.halt(1)
    end
  end

  defp output_results(results, "json") do
    # Simple JSON output without dependencies
    json =
      results
      |> Enum.map(fn r ->
        ~s({"file":"#{r.file}","line":#{r.line},"pattern":"#{r.pattern}","matched":"#{r.matched}"})
      end)
      |> Enum.join(",")

    IO.puts("[#{json}]")
  end

  defp print_help do
    IO.puts("""
    Precheck v#{Precheck.version()} - Secure pre-deployment checks

    Usage: precheck [options]

    Options:
      -h, --help       Show this help
      -v, --version    Show version
      -p, --path       Path to scan (default: current directory)
      -f, --format     Output format: text, json (default: text)

    Examples:
      precheck                    # Scan current directory
      precheck -p ./src           # Scan specific path
      precheck --format json      # JSON output
    """)
  end

  defp print_version do
    IO.puts("precheck v#{Precheck.version()}")
  end
end

ExUnit.start()

# Helper module for common test utilities
defmodule Precheck.TestHelpers do
  @project_root Path.expand("../..", __DIR__)

  def project_root, do: @project_root

  def file_exists?(relative_path) do
    Path.join(@project_root, relative_path) |> File.exists?()
  end

  def dir_exists?(relative_path) do
    Path.join(@project_root, relative_path) |> File.dir?()
  end

  def script_executable?(relative_path) do
    path = Path.join(@project_root, relative_path)
    File.exists?(path) && File.stat!(path).mode |> Bitwise.band(0o111) > 0
  end
end

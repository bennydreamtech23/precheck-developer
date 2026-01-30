defmodule PrecheckTest do
  use ExUnit.Case

  describe "Precheck.Native" do
    test "scan_secrets detects AWS keys" do
      content = """
      config = {
        aws_key: "AKIAIOSFODNN7EXAMPLE"
      }
      """

      results = Precheck.Native.scan_secrets(content, "test.ex")
      assert length(results) == 1
      assert hd(results).pattern == "AWS Access Key"
    end

    test "scan_secrets detects hardcoded passwords" do
      content = ~s(password = "super_secret_123")

      results = Precheck.Native.scan_secrets(content, "config.ex")
      assert length(results) == 1
      assert hd(results).pattern == "Hardcoded Password"
    end

    test "scan_secrets returns empty for clean code" do
      content = """
      defmodule Clean do
        def hello, do: :world
      end
      """

      results = Precheck.Native.scan_secrets(content, "clean.ex")
      assert Enum.empty?(results)
    end

    test "list_checks returns available checks" do
      checks = Precheck.Native.list_checks()
      assert "secrets" in checks
    end
  end
end

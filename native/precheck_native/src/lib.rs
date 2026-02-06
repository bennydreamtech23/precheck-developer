mod embedded;
mod scanner;

use rustler::NifStruct;

#[derive(Debug, NifStruct)]
#[module = "Precheck.Native.ScanResult"]
pub struct ScanResult {
    pub file: String,
    pub line: i64,
    pub pattern: String,
    pub matched: String,
}

#[rustler::nif]
fn run_checks(path: String) -> Result<Vec<ScanResult>, String> {
    scanner::scan_directory(&path)
}

#[rustler::nif]
fn scan_secrets(content: String, filename: String) -> Vec<ScanResult> {
    scanner::scan_content(&content, &filename)
}

#[rustler::nif]
fn execute_script(script_name: String, args: Vec<String>) -> Result<String, String> {
    embedded::execute(&script_name, &args)
}

#[rustler::nif]
fn list_checks() -> Vec<String> {
    vec!["secrets".to_string(), "environment".to_string(), "dependencies".to_string()]
}

rustler::init!("Elixir.Precheck.Native");

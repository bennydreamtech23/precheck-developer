use crate::ScanResult;
use regex::Regex;
use std::fs;
use std::path::Path;
use std::sync::OnceLock;
use walkdir::WalkDir;

/// Secret patterns to detect
const PATTERNS: &[(&str, &str)] = &[
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key"),
    (r"ABIA[0-9A-Z]{16}", "AWS Access Key"),
    (r"ACCA[0-9A-Z]{16}", "AWS Access Key"),
    (
        r#"(?i)password\s*[:=]\s*['"][^'"]{4,}['"]"#,
        "Hardcoded Password",
    ),
    (r#"(?i)api[_-]?key\s*[:=]\s*['"][^'"]{8,}['"]"#, "API Key"),
    (
        r#"(?i)secret\s*[:=]\s*['"][^'"]{4,}['"]"#,
        "Hardcoded Secret",
    ),
    (
        r"-----BEGIN (?:RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY-----",
        "Private Key",
    ),
    (r"ghp_[a-zA-Z0-9]{36}", "GitHub Personal Access Token"),
    (r"gho_[a-zA-Z0-9]{36}", "GitHub OAuth Token"),
    (r"sk-[a-zA-Z0-9]{48}", "OpenAI API Key"),
    (
        r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24}",
        "Slack Token",
    ),
];

/// Files/directories to skip
const SKIP_PATTERNS: &[&str] = &[
    ".git",
    "node_modules",
    "_build",
    "deps",
    "target",
    ".elixir_ls",
    "*.beam",
    "*.pyc",
];

/// Directory names to skip to avoid noisy test fixtures/examples by default.
const SKIP_DIR_NAMES: &[&str] = &["test", "tests", "__tests__", "spec", "fixtures"];

/// Avoid spending excessive time/memory scanning huge files.
const MAX_FILE_SIZE_BYTES: u64 = 2 * 1024 * 1024;

/// Known binary/artifact extensions to skip.
const SKIP_EXTENSIONS: &[&str] = &[
    "beam", "so", "dylib", "dll", "a", "o", "class", "jar", "war", "png", "jpg", "jpeg", "gif",
    "pdf", "zip", "tar", "gz", "7z", "mp4", "mp3", "woff", "woff2", "ttf",
];

fn compiled_patterns() -> &'static Vec<(Regex, &'static str)> {
    static COMPILED: OnceLock<Vec<(Regex, &'static str)>> = OnceLock::new();

    COMPILED.get_or_init(|| {
        PATTERNS
            .iter()
            .map(|(pattern, name)| (Regex::new(pattern).expect("invalid regex pattern"), *name))
            .collect()
    })
}

pub fn scan_directory(path: &str) -> Result<Vec<ScanResult>, String> {
    let mut results = Vec::new();

    for entry in WalkDir::new(path)
        .into_iter()
        .filter_entry(|e| !should_skip(e.path()))
    {
        let entry = entry.map_err(|e| e.to_string())?;

        if entry.file_type().is_file() {
            if !should_scan_file(entry.path()) {
                continue;
            }

            let bytes = match fs::read(entry.path()) {
                Ok(bytes) => bytes,
                Err(_) => {
                    continue;
                }
            };

            // Skip binary-like files quickly.
            if bytes.contains(&0) {
                continue;
            }

            let content = String::from_utf8_lossy(&bytes);
            let file_path = entry.path().to_string_lossy().to_string();
            results.extend(scan_content(&content, &file_path));
        }
    }

    Ok(results)
}

pub fn scan_content(content: &str, filename: &str) -> Vec<ScanResult> {
    let mut results = Vec::new();

    for (line_num, line) in content.lines().enumerate() {
        // Skip comments and empty lines for performance
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') || trimmed.starts_with("//") {
            continue;
        }

        for (re, name) in compiled_patterns() {
            if let Some(matched) = re.find(line) {
                // Mask the actual secret value
                let masked = mask_secret(matched.as_str());

                results.push(ScanResult {
                    file: filename.to_string(),
                    line: (line_num + 1) as i64,
                    pattern: name.to_string(),
                    matched: masked,
                });
            }
        }
    }

    results
}

fn should_skip(path: &Path) -> bool {
    let path_str = path.to_string_lossy();

    if path.components().any(|component| {
        component
            .as_os_str()
            .to_str()
            .map(|name| SKIP_DIR_NAMES.contains(&name))
            .unwrap_or(false)
    }) {
        return true;
    }

    SKIP_PATTERNS.iter().any(|pattern| {
        if let Some(stripped) = pattern.strip_prefix('*') {
            path_str.ends_with(stripped)
        } else {
            path_str.contains(pattern)
        }
    })
}

fn should_scan_file(path: &Path) -> bool {
    if let Ok(metadata) = fs::metadata(path) {
        if metadata.len() > MAX_FILE_SIZE_BYTES {
            return false;
        }
    }

    if let Some(ext) = path.extension().and_then(|e| e.to_str()) {
        if SKIP_EXTENSIONS
            .iter()
            .any(|skip| ext.eq_ignore_ascii_case(skip))
        {
            return false;
        }
    }

    true
}

fn mask_secret(secret: &str) -> String {
    // If the match includes quoted value assignment, mask only the quoted value
    // to keep output readable and avoid trailing quote artifacts.
    if let Some(masked) = mask_quoted_value(secret) {
        return masked;
    }

    let len = secret.len();
    if len <= 8 {
        "*".repeat(len)
    } else {
        format!("{}...{}", &secret[..4], &secret[len - 4..])
    }
}

fn mask_quoted_value(secret: &str) -> Option<String> {
    let quote_pairs = [('\"', '\"'), ('\'', '\'')];

    for (open, close) in quote_pairs {
        let Some(start) = secret.find(open) else {
            continue;
        };
        let Some(end_rel) = secret[start + 1..].find(close) else {
            continue;
        };
        let value = &secret[start + 1..start + 1 + end_rel];

        if value.is_empty() {
            return Some(String::new());
        }

        let len = value.len();
        if len <= 8 {
            return Some("*".repeat(len));
        }

        return Some(format!("{}...{}", &value[..4], &value[len - 4..]));
    }

    None
}

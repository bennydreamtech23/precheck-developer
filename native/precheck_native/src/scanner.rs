use crate::ScanResult;
use regex::Regex;
use std::fs;
use walkdir::WalkDir;

/// Secret patterns to detect
const PATTERNS: &[(&str, &str)] = &[
    (r"AKIA[0-9A-Z]{16}", "AWS Access Key"),
    (r"ABIA[0-9A-Z]{16}", "AWS Access Key"),
    (r"ACCA[0-9A-Z]{16}", "AWS Access Key"),
    (r#"(?i)password\s*[:=]\s*['"][^'"]{4,}['"]"#, "Hardcoded Password"),
    (r#"(?i)api[_-]?key\s*[:=]\s*['"][^'"]{8,}['"]"#, "API Key"),
    (r#"(?i)secret\s*[:=]\s*['"][^'"]{4,}['"]"#, "Hardcoded Secret"),
    (r"-----BEGIN (?:RSA|DSA|EC|OPENSSH|PGP) PRIVATE KEY-----", "Private Key"),
    (r"ghp_[a-zA-Z0-9]{36}", "GitHub Personal Access Token"),
    (r"gho_[a-zA-Z0-9]{36}", "GitHub OAuth Token"),
    (r"sk-[a-zA-Z0-9]{48}", "OpenAI API Key"),
    (r"xox[baprs]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9]{24}", "Slack Token"),
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

pub fn scan_directory(path: &str) -> Result<Vec<ScanResult>, String> {
    let mut results = Vec::new();

    for entry in WalkDir::new(path)
        .into_iter()
        .filter_entry(|e| !should_skip(e.path().to_str().unwrap_or(""))) {
        let entry = entry.map_err(|e| e.to_string())?;

        if entry.file_type().is_file() {
            if let Ok(content) = fs::read_to_string(entry.path()) {
                let file_path = entry.path().to_str().unwrap_or("").to_string();
                results.extend(scan_content(&content, &file_path));
            }
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

        for (pattern, name) in PATTERNS {
            if let Ok(re) = Regex::new(pattern) {
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
    }

    results
}

fn should_skip(path: &str) -> bool {
    SKIP_PATTERNS.iter().any(|pattern| {
        if let Some(stripped) = pattern.strip_prefix('*') {
            path.ends_with(stripped)
        } else {
            path.contains(pattern)
        }
    })
}

fn mask_secret(secret: &str) -> String {
    let len = secret.len();
    if len <= 8 {
        "*".repeat(len)
    } else {
        format!("{}...{}", &secret[..4], &secret[len - 4..])
    }
}

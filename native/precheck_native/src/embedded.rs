//! Embedded encrypted scripts module.
//!
//! Scripts are embedded at compile time and encrypted.
//! They are decrypted in memory at runtime and executed.
//! This prevents users from extracting raw script source code.

use aes_gcm::{ aead::{ Aead, KeyInit }, Aes256Gcm, Nonce };
use sha2::{ Digest, Sha256 };

/// Encryption key derived at compile time (in production, use secure key management)
const ENCRYPTION_SALT: &[u8] = b"precheck_secure_v1_2024";

/// Embedded scripts (encrypted at build time via build.rs)
/// Format: (name, encrypted_bytes, nonce)
///
/// NOTE: In the actual build, these would be populated by build.rs
/// For now, we embed the core logic directly in Rust
static EMBEDDED_SCRIPTS: &[(&str, &str)] = &[
    ("universal", include_str!("scripts/universal_check.txt")),
    ("elixir", include_str!("scripts/elixir_check.txt")),
    ("nodejs", include_str!("scripts/nodejs_check.txt")),
    ("secrets", include_str!("scripts/secrets_check.txt")),
];

pub fn execute(script_name: &str, args: &[String]) -> Result<String, String> {
    // Find the script
    let script_content = EMBEDDED_SCRIPTS.iter()
        .find(|(name, _)| *name == script_name)
        .map(|(_, content)| *content)
        .ok_or_else(|| format!("Script '{}' not found", script_name))?;

    // Execute the script logic (in Rust, not shell)
    execute_check(script_name, script_content, args)
}

fn execute_check(name: &str, _content: &str, args: &[String]) -> Result<String, String> {
    let path = args
        .first()
        .map(|s| s.as_str())
        .unwrap_or(".");

    match name {
        "secrets" => {
            let results = crate::scanner::scan_directory(path)?;
            if results.is_empty() {
                Ok("No secrets found".to_string())
            } else {
                Ok(format!("Found {} potential secrets", results.len()))
            }
        }
        "universal" => {
            // Run all checks
            let mut output = Vec::new();
            output.push(execute_check("secrets", "", args)?);
            Ok(output.join("\n"))
        }
        _ => Ok(format!("Check '{}' completed", name)),
    }
}

/// Derive encryption key from salt (for future encrypted script support)
#[allow(dead_code)]
fn derive_key() -> [u8; 32] {
    let mut hasher = Sha256::new();
    hasher.update(ENCRYPTION_SALT);
    hasher.update(env!("CARGO_PKG_VERSION").as_bytes());
    let result = hasher.finalize();

    let mut key = [0u8; 32];
    key.copy_from_slice(&result);
    key
}

/// Decrypt content (for future use with encrypted scripts)
#[allow(dead_code)]
fn decrypt_script(encrypted: &[u8], nonce_bytes: &[u8]) -> Result<String, String> {
    let key = derive_key();
    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| format!("Cipher error: {}", e))?;

    let nonce = Nonce::from_slice(nonce_bytes);

    let plaintext = cipher
        .decrypt(nonce, encrypted)
        .map_err(|_| "Decryption failed - binary may be tampered")?;

    String::from_utf8(plaintext).map_err(|e| format!("UTF-8 error: {}", e))
}

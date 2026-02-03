#!/usr/bin/env bash
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SECRETS_FOUND=0
REPORT="secrets_scan_report.txt"
: > "$REPORT"

echo -e "${BLUE}🔒 Scanning for Secrets and Sensitive Data${NC}" | tee -a "$REPORT"
echo "Project: $(basename "$(pwd)")" | tee -a "$REPORT"
echo "Date: $(date)" | tee -a "$REPORT"
echo "" | tee -a "$REPORT"

# Patterns to search for
declare -A PATTERNS=(
  ["AWS Access Key"]="AKIA[0-9A-Z]{16}"
  ["AWS Secret Key"]="aws.{0,20}['\"][0-9a-zA-Z/+]{40}['\"]"
  ["GitHub Token"]="ghp_[0-9a-zA-Z]{36}"
  ["Generic API Key"]="api[_-]?key['\"]?\s*[:=]\s*['\"][0-9a-zA-Z]{32,}['\"]"
  ["Generic Secret"]="secret['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
  ["Password in Code"]="password['\"]?\s*[:=]\s*['\"][^'\"]{4,}['\"]"
  ["Private Key"]="-----BEGIN (RSA |DSA |EC )?PRIVATE KEY-----"
  ["JWT Token"]="eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9._-]{10,}"
  ["Database URL"]="(postgres|mysql|mongodb)://[^\s]+"
  ["Slack Token"]="xox[baprs]-[0-9]{10,12}-[0-9]{10,12}-[a-zA-Z0-9]{24,32}"
  ["Stripe Key"]="sk_live_[0-9a-zA-Z]{24,}"
  ["OpenAI Key"]="sk-[a-zA-Z0-9]{48}"
  ["Email Address"]="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
)

# Files/directories to exclude
EXCLUDE_PATTERNS=(
  "node_modules"
  ".git"
  "_build"
  "deps"
  "dist"
  "build"
  "*.log"
  "*.lock"
  "*.min.js"
  "*.map"
  ".precheck"
)

# Build exclusion arguments for grep
EXCLUDE_ARGS=""
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  EXCLUDE_ARGS="$EXCLUDE_ARGS --exclude-dir=$pattern --exclude=$pattern"
done

echo -e "${CYAN}Scanning for sensitive patterns...${NC}\n"

# Scan for each pattern
for pattern_name in "${!PATTERNS[@]}"; do
  pattern="${PATTERNS[$pattern_name]}"
  
  echo -e "${BLUE}Checking for: $pattern_name${NC}"
  
  # Use grep to find matches
  if matches=$(grep -rniE $EXCLUDE_ARGS "$pattern" . 2>/dev/null); then
    echo -e "${RED}⚠️  Found potential $pattern_name:${NC}" | tee -a "$REPORT"
    echo "$matches" | while IFS= read -r line; do
      ((SECRETS_FOUND++))
      # Mask the actual secret value
      file_and_line=$(echo "$line" | cut -d: -f1,2)
      echo -e "   ${YELLOW}$file_and_line${NC}" | tee -a "$REPORT"
    done
    echo "" | tee -a "$REPORT"
  fi
done

# Check for common sensitive files that shouldn't be committed
echo -e "\n${BLUE}Checking for sensitive files...${NC}"

SENSITIVE_FILES=(
  ".env"
  ".env.local"
  ".env.production"
  "*.pem"
  "*.key"
  "*.p12"
  "*.pfx"
  "id_rsa"
  "id_dsa"
  "credentials"
  "config/secrets.yml"
  "config/database.yml"
)

for file_pattern in "${SENSITIVE_FILES[@]}"; do
  if found_files=$(find . -name "$file_pattern" -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/_build/*" -not -path "*/deps/*" 2>/dev/null); then
    if [ -n "$found_files" ]; then
      echo -e "${YELLOW}⚠️  Found sensitive file: $file_pattern${NC}" | tee -a "$REPORT"
      echo "$found_files" | while IFS= read -r file; do
        if [ -n "$file" ]; then
          # Check if file is in .gitignore
          if git check-ignore -q "$file" 2>/dev/null; then
            echo -e "   ${GREEN}✓ $file (properly ignored)${NC}" | tee -a "$REPORT"
          else
            echo -e "   ${RED}✗ $file (NOT in .gitignore)${NC}" | tee -a "$REPORT"
            ((SECRETS_FOUND++))
          fi
        fi
      done
      echo ""
    fi
  fi
done

# Check .gitignore existence
if [ ! -f ".gitignore" ]; then
  echo -e "${RED}⚠️  No .gitignore file found${NC}" | tee -a "$REPORT"
  echo -e "   Create a .gitignore file to exclude sensitive files\n" | tee -a "$REPORT"
  ((SECRETS_FOUND++))
fi

# Check for hardcoded IPs
echo -e "${BLUE}Checking for hardcoded IP addresses...${NC}"
if ip_matches=$(grep -rniE "$EXCLUDE_ARGS" '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' . 2>/dev/null | grep -v "127.0.0.1\|0.0.0.0\|localhost"); then
  if [ -n "$ip_matches" ]; then
    echo -e "${YELLOW}⚠️  Found hardcoded IP addresses:${NC}" | tee -a "$REPORT"
    echo "$ip_matches" | head -5 | while IFS= read -r line; do
      file_and_line=$(echo "$line" | cut -d: -f1,2)
      echo -e "   ${YELLOW}$file_and_line${NC}" | tee -a "$REPORT"
    done
    echo -e "   ${CYAN}(Use environment variables instead)${NC}\n" | tee -a "$REPORT"
  fi
fi

# Summary
echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         SECURITY SCAN SUMMARY          ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"

if [ $SECRETS_FOUND -eq 0 ]; then
  echo -e "${GREEN}✅ No secrets or sensitive data detected${NC}" | tee -a "$REPORT"
  echo -e "${GREEN}✅ Security scan passed!${NC}" | tee -a "$REPORT"
  exit 0
else
  echo -e "${RED}⚠️  Found $SECRETS_FOUND potential security issues${NC}" | tee -a "$REPORT"
  echo "" | tee -a "$REPORT"
  echo -e "${YELLOW}Recommendations:${NC}" | tee -a "$REPORT"
  echo "1. Remove hardcoded secrets from your code" | tee -a "$REPORT"
  echo "2. Use environment variables for sensitive data" | tee -a "$REPORT"
  echo "3. Add sensitive files to .gitignore" | tee -a "$REPORT"
  echo "4. Rotate any exposed credentials immediately" | tee -a "$REPORT"
  echo "5. Use secret management tools (e.g., Vault, AWS Secrets Manager)" | tee -a "$REPORT"
  echo "" | tee -a "$REPORT"
  echo -e "${BLUE}📋 Detailed report saved to $REPORT${NC}"
  exit 1
fi
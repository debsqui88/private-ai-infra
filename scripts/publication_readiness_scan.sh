#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
REPORT="$PROJECT_ROOT/docs/PUBLICATION_READINESS_REPORT.md"
BLOCKERS=0
REVIEWS=0

cd "$PROJECT_ROOT" || exit 1
mkdir -p docs
: > "$REPORT"

log_report() {
  printf "%s\n" "$1" >> "$REPORT"
}

section() {
  echo
  echo "===== $1 ====="
  log_report ""
  log_report "## $1"
  log_report ""
}

blocker() {
  echo "BLOCKER: $1"
  log_report "- BLOCKER: $1"
  BLOCKERS=$((BLOCKERS + 1))
}

review() {
  echo "REVIEW: $1"
  log_report "- REVIEW: $1"
  REVIEWS=$((REVIEWS + 1))
}

info() {
  echo "INFO: $1"
  log_report "- INFO: $1"
}

log_report "# Publication Readiness Report"
log_report ""
log_report "Generated: $(date)"
log_report ""
log_report "This report does not publish, commit, push, delete, or redact files."

section "Repository Shape"
for d in venv model_cache logs backups tmp certs; do
  if [ -e "$d" ]; then review "$d exists locally and should be excluded from GitHub"; else info "$d not present at project root"; fi
done

section "Required Portfolio Files"
for f in README.md ARCHITECTURE.md SECURITY_MODEL.md RUNBOOK.md FUTURE.md INTERVIEW_TALK_TRACK.md docs/GITHUB_SANITIZATION.md docs/VALIDATION_SUMMARY.md; do
  if [ -s "$f" ]; then info "$f present"; else review "$f missing or empty"; fi
done

section "Gitignore Review"
if [ -f .gitignore ]; then
  info ".gitignore exists"
  for pattern in venv model_cache logs backups tmp certs .env "*.pem" "*.key" "*.crt" ".DS_Store"; do
    if grep -Fq -- "$pattern" .gitignore 2>/dev/null; then info ".gitignore includes $pattern"; else review ".gitignore may need $pattern"; fi
  done
else
  review ".gitignore missing"
fi

section "Dangerous File Extensions"
dangerous_files="$(find . -type f \( -name "*.pem" -o -name "*.key" -o -name "*.p12" -o -name "*.pfx" -o -name ".env" \) -not -path "./venv/*" -not -path "./model_cache/*" -not -path "./backups/*" -not -path "./logs/*" -not -path "./tmp/*" -not -path "./certs/*" 2>/dev/null || true)"
if [ -n "$dangerous_files" ]; then
  echo "$dangerous_files" | while read -r f; do [ -n "$f" ] && blocker "dangerous file candidate: $f"; done
  BLOCKERS=$((BLOCKERS + 1))
else
  info "no dangerous secret-bearing file extensions found outside excluded directories"
fi

section "Secret Pattern Scan"
scan_files="$(find . -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.conf" -o -name "*.yaml" -o -name "*.yml" -o -name ".gitignore" \) -not -path "./venv/*" -not -path "./model_cache/*" -not -path "./backups/*" -not -path "./logs/*" -not -path "./tmp/*" -not -path "./certs/*" -not -path "./.git/*" 2>/dev/null || true)"

if echo "$scan_files" | xargs grep -InE "AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY" >/tmp/private_ai_secret_hits.txt 2>/dev/null; then
  blocker "high-confidence secret pattern found; inspect /tmp/private_ai_secret_hits.txt"
  sed -n "1,20p" /tmp/private_ai_secret_hits.txt
else
  info "no high-confidence secret patterns found in scanned publishable file types"
fi

section "Known Placeholder and Local Token Review"
if echo "$scan_files" | xargs grep -In "private-portfolio-token" >/tmp/private_ai_placeholder_hits.txt 2>/dev/null; then
  review "private-portfolio-token placeholder appears; decide whether to replace with YOUR_TOKEN before GitHub"
  sed -n "1,20p" /tmp/private_ai_placeholder_hits.txt
else
  info "private-portfolio-token placeholder not found"
fi

section "Machine-Specific Path Review"
if echo "$scan_files" | xargs grep -In "/Users/debsqui" >/tmp/private_ai_path_hits.txt 2>/dev/null; then
  review "machine-specific path /Users/debsqui found; consider generalizing before GitHub"
  sed -n "1,20p" /tmp/private_ai_path_hits.txt
else
  info "no /Users/debsqui paths found in scanned publishable file types"
fi

section "OffSec Review"
if echo "$scan_files" | xargs grep -InEi "offsec|exploit|payload|reverse shell|credential dumping|persistence" >/tmp/private_ai_offsec_hits.txt 2>/dev/null; then
  review "offensive-security terminology found; manually review context before GitHub"
  sed -n "1,25p" /tmp/private_ai_offsec_hits.txt
else
  info "no obvious offensive-security terminology found in scanned publishable file types"
fi

section "Overall Result"
log_report ""
log_report "Blockers: $BLOCKERS"
log_report "Review items: $REVIEWS"

echo "BLOCKERS=$BLOCKERS"
echo "REVIEW_ITEMS=$REVIEWS"

if [ "$BLOCKERS" -gt 0 ]; then
  echo "PUBLICATION_READINESS_STATUS=FAIL"
  log_report "PUBLICATION_READINESS_STATUS=FAIL"
  exit 1
elif [ "$REVIEWS" -gt 0 ]; then
  echo "PUBLICATION_READINESS_STATUS=REVIEW_REQUIRED"
  log_report "PUBLICATION_READINESS_STATUS=REVIEW_REQUIRED"
  exit 0
else
  echo "PUBLICATION_READINESS_STATUS=PASS"
  log_report "PUBLICATION_READINESS_STATUS=PASS"
  exit 0
fi

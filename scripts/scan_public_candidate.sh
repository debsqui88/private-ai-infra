#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
CANDIDATE="$PROJECT_ROOT/public_release"
REPORT="$CANDIDATE/docs/PUBLIC_CANDIDATE_SCAN_REPORT.md"
BLOCKERS=0
REVIEWS=0

cd "$PROJECT_ROOT" || exit 1

if [ ! -d "$CANDIDATE" ]; then
  echo "ERROR: public_release directory missing. Run scripts/export_public_candidate.sh first."
  exit 1
fi

: > "$REPORT"
printf "%s\n" "# Public Candidate Scan Report" >> "$REPORT"
printf "%s\n" "" >> "$REPORT"
printf "%s\n" "Generated: $(date)" >> "$REPORT"
printf "%s\n" "" >> "$REPORT"

section() {
  echo
  echo "===== $1 ====="
  printf "%s\n" "" >> "$REPORT"
  printf "%s\n" "## $1" >> "$REPORT"
  printf "%s\n" "" >> "$REPORT"
}

blocker() {
  echo "BLOCKER: $1"
  printf "%s\n" "- BLOCKER: $1" >> "$REPORT"
  BLOCKERS=$((BLOCKERS + 1))
}

review() {
  echo "REVIEW: $1"
  printf "%s\n" "- REVIEW: $1" >> "$REPORT"
  REVIEWS=$((REVIEWS + 1))
}

info() {
  echo "INFO: $1"
  printf "%s\n" "- INFO: $1" >> "$REPORT"
}

section "Candidate Shape"
for f in README.md ARCHITECTURE.md SECURITY_MODEL.md RUNBOOK.md FUTURE.md INTERVIEW_TALK_TRACK.md .gitignore docs/PUBLIC_RELEASE_MANIFEST.md; do
  if [ -s "$CANDIDATE/$f" ]; then info "$f present"; else blocker "$f missing or empty"; fi
done

section "Excluded Runtime Material Check"
for d in venv model_cache logs backups tmp certs gateway config memory; do
  if [ -e "$CANDIDATE/$d" ]; then blocker "$d should not exist in public_release"; else info "$d excluded"; fi
done

section "Dangerous File Extension Check"
dangerous="$(find "$CANDIDATE" -type f \( -name "*.pem" -o -name "*.key" -o -name "*.crt" -o -name "*.p12" -o -name "*.pfx" -o -name ".env" \) 2>/dev/null || true)"
if [ -n "$dangerous" ]; then
  echo "$dangerous" | while read -r f; do [ -n "$f" ] && echo "BLOCKER: dangerous candidate file $f"; done
  printf "%s\n" "$dangerous" >> "$REPORT"
  BLOCKERS=$((BLOCKERS + 1))
else
  info "no dangerous secret-bearing file extensions found"
fi

section "Secret and Local Context Pattern Check"
scan_files="$(find "$CANDIDATE" -type f \( -name "*.md" -o -name "*.py" -o -name "*.sh" -o -name "*.json" -o -name "*.conf" -o -name "*.yaml" -o -name "*.yml" -o -name ".gitignore" \) -not -name "PUBLIC_CANDIDATE_SCAN_REPORT.md" 2>/dev/null || true)"

if echo "$scan_files" | xargs grep -InE "AKIA[0-9A-Z]{16}|ASIA[0-9A-Z]{16}|ghp_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|xox[baprs]-[A-Za-z0-9-]{10,}|BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY" >/tmp/public_candidate_secret_hits.txt 2>/dev/null; then
  blocker "high-confidence secret pattern found; inspect /tmp/public_candidate_secret_hits.txt"
  sed -n "1,20p" /tmp/public_candidate_secret_hits.txt
else
  info "no high-confidence secret patterns found"
fi

if echo "$scan_files" | xargs grep -In "private-portfolio-token" >/tmp/public_candidate_token_hits.txt 2>/dev/null; then
  blocker "private-portfolio-token still present in public candidate"
  sed -n "1,20p" /tmp/public_candidate_token_hits.txt
else
  info "private-portfolio-token absent"
fi

if echo "$scan_files" | xargs grep -In "/Users/debsqui" >/tmp/public_candidate_path_hits.txt 2>/dev/null; then
  blocker "/Users/debsqui still present in public candidate"
  sed -n "1,20p" /tmp/public_candidate_path_hits.txt
else
  info "/Users/debsqui absent"
fi

if echo "$scan_files" | xargs grep -InEi "offsec|exploit|payload|reverse shell|credential dumping|persistence" >/tmp/public_candidate_offsec_hits.txt 2>/dev/null; then
  review "sensitive lab wording still present in public candidate"
  sed -n "1,25p" /tmp/public_candidate_offsec_hits.txt
else
  info "sensitive lab wording absent"
fi

section "Overall Result"
echo "BLOCKERS=$BLOCKERS"
echo "REVIEW_ITEMS=$REVIEWS"
printf "%s\n" "" >> "$REPORT"
printf "%s\n" "Blockers: $BLOCKERS" >> "$REPORT"
printf "%s\n" "Review items: $REVIEWS" >> "$REPORT"

if [ "$BLOCKERS" -gt 0 ]; then
  echo "PUBLIC_CANDIDATE_STATUS=FAIL"
  printf "%s\n" "PUBLIC_CANDIDATE_STATUS=FAIL" >> "$REPORT"
  exit 1
elif [ "$REVIEWS" -gt 0 ]; then
  echo "PUBLIC_CANDIDATE_STATUS=REVIEW_REQUIRED"
  printf "%s\n" "PUBLIC_CANDIDATE_STATUS=REVIEW_REQUIRED" >> "$REPORT"
  exit 0
else
  echo "PUBLIC_CANDIDATE_STATUS=PASS"
  printf "%s\n" "PUBLIC_CANDIDATE_STATUS=PASS" >> "$REPORT"
  exit 0
fi

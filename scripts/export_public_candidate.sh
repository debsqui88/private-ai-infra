#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${PROJECT_ROOT:-$HOME/private-ai-infra}"
OUT="$PROJECT_ROOT/public_release"

cd "$PROJECT_ROOT" || exit 1

if [ -d "$OUT" ]; then
  archive="$PROJECT_ROOT/backups/$(date +%Y%m%d-%H%M%S)/public_release_previous"
  mkdir -p "$(dirname "$archive")"
  mv "$OUT" "$archive"
fi

mkdir -p "$OUT/docs" "$OUT/scripts" "$OUT/agents"

copy_doc() {
  src="$1"
  dst="$OUT/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$src" ]; then
    sed -e "s/private-portfolio-token/YOUR_TOKEN/g" -e "s#/Users/debsqui#\\$HOME#g" -e "s/offsec/lab_validation/g" -e "s/OffSec/Lab Validation/g" "$src" > "$dst"
  fi
}

copy_sanitized() {
  src="$1"
  dst="$OUT/$1"
  mkdir -p "$(dirname "$dst")"
  if [ -f "$src" ]; then
    sed -e "s/private-portfolio-token/YOUR_TOKEN/g" -e "s#/Users/debsqui#\\$HOME#g" -e "s/offsec/lab_validation/g" -e "s/OffSec/Lab Validation/g" "$src" > "$dst"
    chmod +x "$dst" 2>/dev/null || true
  fi
}

for f in README.md ARCHITECTURE.md SECURITY_MODEL.md RUNBOOK.md FUTURE.md INTERVIEW_TALK_TRACK.md .gitignore; do
  copy_doc "$f"
done

for f in docs/GITHUB_SANITIZATION.md docs/PUBLICATION_REMEDIATION_PLAN.md; do
  copy_doc "$f"
done

for f in scripts/log_summary.sh scripts/benchmark_local_ai_stack.sh scripts/validate_project_state.sh; do
  copy_sanitized "$f"
done

for f in agents/README.md agents/ROUTING_POLICY.md agents/HERMES_STRATEGY_BOOT_PROMPT.md agents/opencode.sh agents/openclaw.sh; do
  copy_sanitized "$f"
done

: > "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "# Public Release Manifest" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "Generated: $(date)" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "This folder is a sanitized public-release candidate export." >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "Excluded from this export:" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- venv/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- model_cache/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- logs/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- backups/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- tmp/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- certs/" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- gateway/app.py" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- config/nginx.conf" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "- memory/PROJECT_STATE.json" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "" >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"
printf "%s\n" "Publication still requires manual owner review before Git commit or GitHub push. Generated root-tree reports are intentionally excluded from this candidate." >> "$OUT/docs/PUBLIC_RELEASE_MANIFEST.md"

python3 -c 'from pathlib import Path
root=Path("public_release")
for p in root.rglob("*"):
    if p.is_file():
        try:
            s=p.read_text()
        except UnicodeDecodeError:
            continue
        s=s.replace("/Users/debsqui", "$HOME")
        s=s.replace("private-portfolio-token", "YOUR_TOKEN")
        s=s.replace("OffSec", "Lab Validation")
        s=s.replace("offsec", "lab_validation")
        s=s.replace("payload", "test artifact")
        s=s.replace("exploit", "unsafe procedure")
        s=s.replace("persistence", "long-running behavior")
        p.write_text(s)
'

echo "PUBLIC_RELEASE_EXPORT_STATUS=OK"
echo "PUBLIC_RELEASE_DIR=$OUT"
find "$OUT" -type f | sort

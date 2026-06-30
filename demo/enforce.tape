# enforce.tape — VHS script for the live enforcement demo.
# Regenerate the GIF with:  vhs demo/enforce.tape   (requires a running stack — see below)
#
# Prereqs (the GIF is recorded against a LIVE gateway):
#   1) config/policy.toml present with the `hermes` demo principal (token hermes-demo-key-001)
#   2) make start    # Flask :8080 + nginx :8081, loopback only
# Then:  vhs demo/enforce.tape   ->   docs/assets/enforce.gif
# Finally: make stop

Output docs/assets/enforce.gif

Require curl

Set Shell bash
Set FontSize 16
Set Width 1320
Set Height 820
Set Padding 30
Set Theme "Catppuccin Mocha"
Set TypingSpeed 28ms
Set Margin 10
Set BorderRadius 8

# --- silent setup: clean prompt, venv for the closing OpenClaw check ---
Hide
Type `export VIRTUAL_ENV_DISABLE_PROMPT=1` Enter
Type `source venv/bin/activate 2>/dev/null; export PYTHONPATH=agents` Enter
Type `export H='Authorization: Bearer hermes-demo-key-001'` Enter
Type `export PS1='❯ '` Enter
Type "clear" Enter
Show

Sleep 600ms
Type@22ms `# 'hermes' is a principal capped at autonomy L1 (suggest), models=[strategy].` Enter
Sleep 700ms
Type `curl -s :8081/v1/whoami -H "$H" | python3 -m json.tool` Enter
Sleep 2.6s

Type@22ms `# 1) It declares L6 (unbounded) — more autonomy than its mandate.` Enter
Sleep 600ms
Type `curl -s :8081/v1/chat/completions -H "$H" -H 'X-Autonomy-Level: 6' -d '{"model":"strategy","messages":[{"role":"user","content":"hi"}]}' -w '\n→ HTTP %{http_code}\n'` Enter
Sleep 3s

Type@22ms `# 2) It requests 'offsec' — a model outside its allowlist.` Enter
Sleep 600ms
Type `curl -s :8081/v1/chat/completions -H "$H" -d '{"model":"offsec","messages":[{"role":"user","content":"hi"}]}' -w '\n→ HTTP %{http_code}\n'` Enter
Sleep 3s

Type@22ms `# 3) It under-declares: header says L1, body smuggles L6. Most-privileged-wins.` Enter
Sleep 600ms
Type `curl -s :8081/v1/chat/completions -H "$H" -H 'X-Autonomy-Level: 1' -d '{"model":"strategy","autonomy_level":6,"messages":[{"role":"user","content":"hi"}]}' -w '\n→ HTTP %{http_code}\n'` Enter
Sleep 3s

Type@22ms `# Every denial was audited. OpenClaw independently re-verifies the controls held:` Enter
Sleep 700ms
Type `python -m openclaw.run --audit logs/decisions.jsonl --policy config/policy.toml | grep -E 'verdict|AUTONOMY-CEILING|AUTHZ-MODEL'` Enter
Sleep 4s

Type@22ms `# Capability is not authority — enforced in code, before the model ever loads.` Enter
Sleep 3s

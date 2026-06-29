"""Tests for OpenClaw evidence loaders."""

from __future__ import annotations

from openclaw import evidence


def _write(tmp_path, name, text):
    p = tmp_path / name
    p.write_text(text, encoding="utf-8")
    return p


# ----------------------------------------------------------------------- audit
def test_load_audit_parses_records(tmp_path):
    p = _write(
        tmp_path,
        "d.jsonl",
        '{"ts":"t","request_id":"r1","principal":"a","method":"POST","path":"/p",'
        '"model":"strategy","decision":"allow","reason":"ok","status":200}\n',
    )
    log = evidence.load_audit(p)
    assert len(log.events) == 1
    assert not log.malformed
    e = log.events[0]
    assert e.principal == "a" and e.decision == "allow" and e.status == 200


def test_load_audit_flags_corrupt_and_incomplete_lines(tmp_path):
    p = _write(
        tmp_path,
        "d.jsonl",
        "\n"  # blank lines are skipped, not flagged
        "{ not json\n"  # corrupt -> malformed
        '{"ts":"t","decision":"allow"}\n',  # missing required fields -> malformed
    )
    log = evidence.load_audit(p)
    assert log.events == []
    assert log.malformed == [2, 3]


def test_load_audit_missing_file_is_empty_not_error(tmp_path):
    log = evidence.load_audit(tmp_path / "nope.jsonl")
    assert log.events == [] and log.malformed == []


def test_audit_status_must_be_int(tmp_path):
    p = _write(
        tmp_path,
        "d.jsonl",
        '{"ts":"t","request_id":"r","principal":"a","method":"POST","path":"/p",'
        '"model":"m","decision":"allow","reason":"ok","status":"two-hundred"}\n',
    )
    log = evidence.load_audit(p)
    assert log.malformed == [1]


def test_audit_helpers_filter_by_decision_and_reason(tmp_path):
    p = _write(
        tmp_path,
        "d.jsonl",
        '{"ts":"t","request_id":"r1","principal":"a","method":"POST","path":"/p",'
        '"model":"m","decision":"deny","reason":"autonomy_exceeded: L3>L1","status":403}\n'
        '{"ts":"t","request_id":"r2","principal":"a","method":"POST","path":"/p",'
        '"model":"m","decision":"filter","reason":"guardrail","status":200}\n',
    )
    log = evidence.load_audit(p)
    assert [e.request_id for e in log.with_decision("filter")] == ["r2"]
    assert [e.request_id for e in log.matching_reason("AUTONOMY")] == ["r1"]


# --------------------------------------------------------------------- metrics
def test_parse_metrics_labels_and_totals():
    text = (
        "# HELP gateway_authz_denials_total denials\n"
        "# TYPE gateway_authz_denials_total counter\n"
        'gateway_authz_denials_total{reason="model_not_allowed"} 3\n'
        'gateway_authz_denials_total{reason="autonomy_exceeded"} 2\n'
        "gateway_rate_limited_total 4\n"
    )
    ms = evidence.parse_metrics(text)
    assert ms.total("gateway_authz_denials_total") == 5
    assert ms.total("gateway_rate_limited_total") == 4
    assert ms.has("gateway_rate_limited_total")
    assert not ms.has("nonexistent_total")


def test_parse_metrics_handles_comma_in_quoted_label_value():
    ms = evidence.parse_metrics('thing_total{reason="a, b",k="v"} 1\n')
    sample = ms.samples[0]
    assert sample.labels == {"reason": "a, b", "k": "v"}
    assert sample.value == 1.0


# ------------------------------------------------------------------- isolation
def test_parse_isolation_report_extracts_fields_and_verdicts():
    text = (
        "RUN_ID=123\n"
        "PASS: token present (length 23)\n"
        "SECRET_SCAN_RESULT=PASS_NO_FATAL_HITS\n"
        "OPENCODE_EXIT=0\n"
        "ISOLATION_RESULT=PASS\n"
    )
    rep = evidence.parse_isolation_report(text)
    assert rep.result == "PASS"
    assert rep.secret_scan == "PASS_NO_FATAL_HITS"
    assert rep.opencode_exit == "0"
    assert rep.pass_lines and not rep.fail_lines


def test_parse_isolation_report_captures_fail_lines():
    rep = evidence.parse_isolation_report("FAIL: sandbox copy was modified\nISOLATION_RESULT=FAIL\n")
    assert rep.result == "FAIL"
    assert rep.fail_lines == ["sandbox copy was modified"]


def test_load_isolation_report_missing_is_none(tmp_path):
    assert evidence.load_isolation_report(tmp_path / "nope.txt") is None


# ---------------------------------------------------------------------- policy
def test_load_policy_reduces_principals(tmp_path):
    p = _write(
        tmp_path,
        "policy.toml",
        '[[principals]]\nname = "hermes"\nallowed_models = ["strategy"]\n'
        'max_autonomy_level = "L1"\n',
    )
    view = evidence.load_policy(p)
    assert view.allowed_models("hermes") == {"strategy"}
    assert view.allowed_models("unknown") is None


def test_load_policy_missing_is_none(tmp_path):
    assert evidence.load_policy(tmp_path / "nope.toml") is None

"""Unit tests for the console entry point. The CLI imports the app lazily (only on
`serve`), so parsing and `version` work without MLX and run everywhere."""

from __future__ import annotations

import pytest

from private_ai_gateway import cli


def test_version_command_prints_and_exits_zero(capsys):
    rc = cli.main(["version"])
    assert rc == 0
    assert cli.__version__ in capsys.readouterr().out


def test_version_flag():
    # argparse `action="version"` exits 0
    with pytest.raises(SystemExit) as e:
        cli.main(["--version"])
    assert e.value.code == 0


def test_serve_parser_defaults_to_loopback():
    args = cli.build_parser().parse_args(["serve"])
    assert args.host == "127.0.0.1"
    assert args.port == 8080
    assert args.command == "serve"


def test_no_command_prints_help_and_exits_zero(capsys):
    rc = cli.main([])
    assert rc == 0
    assert "private-ai-gateway" in capsys.readouterr().out

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab API client - common utilities.

Standard library only. Compatible with Python 3.6+.
"""

from __future__ import print_function, unicode_literals

import json
import mimetypes
import os
import sys
import uuid
from urllib.error import HTTPError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


class GitLabClient(object):
    """GitLab REST API v4 client using only the Python standard library."""

    def __init__(self):
        self.token = self._resolve_config("GITLAB_TOKEN")
        self.base_url = (
            self._resolve_config("GITLAB_URL") or "https://gitlab.com"
        ).rstrip("/")
        if not self.token:
            print("ERROR: GITLAB_TOKEN is not set.", file=sys.stderr)
            print("Set it via:", file=sys.stderr)
            print("  1. export GITLAB_TOKEN=glpat-xxx", file=sys.stderr)
            print(
                "  2. Add to $HOME/.config/skills/gitlab/.env", file=sys.stderr
            )
            print("  3. Add to $HOME/.config/skills/.env", file=sys.stderr)
            sys.exit(1)
        self.api_base = self.base_url + "/api/v4"

    @staticmethod
    def _load_env_file(path):
        """Load key=value pairs from a .env file."""
        result = {}
        if not os.path.isfile(path):
            return result
        try:
            with open(path, "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" not in line:
                        continue
                    key, value = line.split("=", 1)
                    key = key.strip()
                    value = value.strip()
                    if (
                        len(value) >= 2
                        and value[0] == value[-1]
                        and value[0] in ('"', "'")
                    ):
                        value = value[1:-1]
                    result[key] = value
        except (IOError, OSError):
            pass
        return result

    def _resolve_config(self, var_name):
        """Resolve config: env var > ~/.config/skills/gitlab/.env > ~/.config/skills/.env."""
        val = os.environ.get(var_name, "")
        if val:
            return val
        home = os.path.expanduser("~")
        for env_path in [
            os.path.join(home, ".config", "skills", "gitlab", ".env"),
            os.path.join(home, ".config", "skills", ".env"),
        ]:
            env_vars = self._load_env_file(env_path)
            if var_name in env_vars:
                return env_vars[var_name]
        return ""

    @staticmethod
    def encode_path(path):
        """URL-encode a project/group path (e.g. 'ns/proj' -> 'ns%2Fproj')."""
        return quote(str(path), safe="")

    def api(self, method, endpoint, data=None):
        """Execute a GitLab API call.

        Args:
            method: HTTP method (GET, POST, PUT, DELETE, PATCH).
            endpoint: API endpoint (e.g. /projects).
            data: Request body as dict (JSON-encoded automatically).

        Returns:
            Parsed JSON response, or None for empty responses.
        """
        url = self.api_base + endpoint
        headers = {
            "PRIVATE-TOKEN": self.token,
            "Content-Type": "application/json",
        }
        body = None
        if data is not None:
            body = json.dumps(data, ensure_ascii=False).encode("utf-8")

        req = Request(url, data=body, headers=headers, method=method)
        try:
            resp = urlopen(req)
            content = resp.read().decode("utf-8")
            if not content.strip():
                return None
            return json.loads(content)
        except HTTPError as e:
            error_body = e.read().decode("utf-8")
            print(
                "ERROR: HTTP {} from {} {}".format(e.code, method, endpoint),
                file=sys.stderr,
            )
            print(error_body, file=sys.stderr)
            sys.exit(1)

    def upload(self, endpoint, file_path, field_name="file"):
        """Upload a file via multipart form-data.

        Args:
            endpoint: API endpoint for the upload.
            file_path: Local path to the file.
            field_name: Form field name (default: 'file').

        Returns:
            Parsed JSON response.
        """
        boundary = uuid.uuid4().hex
        filename = os.path.basename(file_path)
        ctype = mimetypes.guess_type(filename)[0] or "application/octet-stream"

        with open(file_path, "rb") as f:
            file_data = f.read()

        parts = []
        parts.append(("--" + boundary + "\r\n").encode("utf-8"))
        parts.append(
            (
                'Content-Disposition: form-data; name="{}"; filename="{}"\r\n'.format(
                    field_name, filename
                )
            ).encode("utf-8")
        )
        parts.append(
            ("Content-Type: {}\r\n".format(ctype)).encode("utf-8")
        )
        parts.append(b"\r\n")
        parts.append(file_data)
        parts.append(b"\r\n")
        parts.append(("--" + boundary + "--\r\n").encode("utf-8"))
        body = b"".join(parts)

        url = self.api_base + endpoint
        headers = {
            "PRIVATE-TOKEN": self.token,
            "Content-Type": "multipart/form-data; boundary={}".format(boundary),
        }
        req = Request(url, data=body, headers=headers, method="POST")
        try:
            resp = urlopen(req)
            content = resp.read().decode("utf-8")
            if not content.strip():
                return None
            return json.loads(content)
        except HTTPError as e:
            error_body = e.read().decode("utf-8")
            print(
                "ERROR: HTTP {} from upload to {}".format(e.code, endpoint),
                file=sys.stderr,
            )
            print(error_body, file=sys.stderr)
            sys.exit(1)

    def download(self, endpoint, output_path):
        """Download a file from a GitLab API endpoint.

        Args:
            endpoint: API endpoint.
            output_path: Local path to save the file.
        """
        url = self.api_base + endpoint
        req = Request(url, method="GET")
        req.add_header("PRIVATE-TOKEN", self.token)
        try:
            resp = urlopen(req)
            with open(output_path, "wb") as f:
                while True:
                    chunk = resp.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
        except HTTPError as e:
            error_body = e.read().decode("utf-8")
            print(
                "ERROR: HTTP {} from GET {}".format(e.code, endpoint),
                file=sys.stderr,
            )
            print(error_body, file=sys.stderr)
            sys.exit(1)

    def paginate(self, endpoint, per_page=100):
        """Paginate through all results for a list endpoint.

        Args:
            endpoint: API endpoint (may include query params).
            per_page: Results per page (default: 100).

        Returns:
            List of all results across all pages.
        """
        all_results = []
        page = 1
        while True:
            sep = "&" if "?" in endpoint else "?"
            result = self.api(
                "GET",
                "{}{}per_page={}&page={}".format(endpoint, sep, per_page, page),
            )
            if not result:
                break
            if isinstance(result, list):
                all_results.extend(result)
                if len(result) < per_page:
                    break
            else:
                all_results.append(result)
                break
            page += 1
        return all_results


# ---------------------------------------------------------------------------
# CLI Helpers
# ---------------------------------------------------------------------------


def pp(data):
    """Pretty print data as JSON to stdout."""
    print(json.dumps(data, indent=2, ensure_ascii=False))


def build_query_string(params):
    """Build a query string from a dict, omitting empty/None values.

    Args:
        params: Dict of query parameters.

    Returns:
        Query string starting with '?' or empty string.
    """
    filtered = {
        k: v for k, v in params.items() if v is not None and v != ""
    }
    if not filtered:
        return ""
    return "?" + urlencode(filtered)


def _parse_cli_args(args):
    """Parse CLI arguments into (positional, keyword) tuple.

    Supports:
        positional: value1 value2
        keyword:    --key value
        json data:  --data '{"key":"value"}'
    """
    positional = []
    kwargs = {}
    i = 0
    while i < len(args):
        if args[i].startswith("--"):
            key = args[i][2:].replace("-", "_")
            if i + 1 < len(args) and not args[i + 1].startswith("--"):
                kwargs[key] = args[i + 1]
                i += 2
            else:
                kwargs[key] = "true"
                i += 1
        else:
            positional.append(args[i])
            i += 1
    return positional, kwargs


def run_cli(functions):
    """Run a CLI interface for the given function map.

    Each function must accept a GitLabClient as its first argument.

    Usage:
        python3 module.py <function_name> [args...] [--key value ...]
    """
    prog = os.path.basename(sys.argv[0])

    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(
            "Usage: python3 {} <function> [args...] [--key value ...]".format(
                prog
            )
        )
        print()
        print("Available functions:")
        for name in sorted(functions):
            func = functions[name]
            doc = (func.__doc__ or "").strip().split("\n")[0]
            print("  {:<40s} {}".format(name, doc))
        sys.exit(0)

    func_name = sys.argv[1]
    if func_name not in functions:
        print("Unknown function: {}".format(func_name), file=sys.stderr)
        print(
            "Run with --help to see available functions.", file=sys.stderr
        )
        sys.exit(1)

    client = GitLabClient()
    positional, kwargs = _parse_cli_args(sys.argv[2:])

    # Handle --data as JSON
    if "data" in kwargs and isinstance(kwargs["data"], str):
        try:
            kwargs["data"] = json.loads(kwargs["data"])
        except (ValueError, TypeError):
            pass

    result = functions[func_name](client, *positional, **kwargs)
    if result is not None:
        pp(result)

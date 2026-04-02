#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Packages API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_packages(client, project_id, package_type=None, package_name=None):
    """List packages for a project."""
    pid = client.encode_path(project_id)
    qs = build_query_string({
        "package_type": package_type, "package_name": package_name,
    })
    return client.api("GET", "/projects/{}/packages{}".format(pid, qs))


def list_group_packages(client, group_id, package_type=None,
                        package_name=None):
    """List group-level packages."""
    gid = client.encode_path(group_id)
    qs = build_query_string({
        "package_type": package_type, "package_name": package_name,
    })
    return client.api("GET", "/groups/{}/packages{}".format(gid, qs))


def get_package(client, project_id, package_id):
    """Get a single package."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/packages/{}".format(pid, package_id)
    )


def delete_package(client, project_id, package_id):
    """Delete a package."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/packages/{}".format(pid, package_id)
    )


def list_package_files(client, project_id, package_id):
    """List files for a package."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET",
        "/projects/{}/packages/{}/package_files".format(pid, package_id),
    )


def upload_generic_package(client, project_id, package_name, package_version,
                           file_name, file_path):
    """Upload file to generic package registry."""
    pid = client.encode_path(project_id)
    endpoint = "/projects/{}/packages/generic/{}/{}/{}".format(
        pid, client.encode_path(package_name),
        client.encode_path(package_version),
        client.encode_path(file_name),
    )
    with open(file_path, "rb") as f:
        file_data = f.read()
    url = client.api_base + endpoint
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError

    req = Request(url, data=file_data, method="PUT")
    req.add_header("PRIVATE-TOKEN", client.token)
    req.add_header("Content-Type", "application/octet-stream")
    try:
        resp = urlopen(req)
        import json
        content = resp.read().decode("utf-8")
        return json.loads(content) if content.strip() else None
    except HTTPError as e:
        error_body = e.read().decode("utf-8")
        print("ERROR: HTTP {} from upload".format(e.code), file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)


def download_generic_package(client, project_id, package_name,
                             package_version, file_name, output_path):
    """Download file from generic package registry."""
    pid = client.encode_path(project_id)
    endpoint = "/projects/{}/packages/generic/{}/{}/{}".format(
        pid, client.encode_path(package_name),
        client.encode_path(package_version),
        client.encode_path(file_name),
    )
    client.download(endpoint, output_path)
    return {"status": "downloaded", "path": output_path}


if __name__ == "__main__":
    run_cli({
        "list_packages": list_packages,
        "list_group_packages": list_group_packages,
        "get_package": get_package,
        "delete_package": delete_package,
        "list_package_files": list_package_files,
        "upload_generic_package": upload_generic_package,
        "download_generic_package": download_generic_package,
    })

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Merge Requests API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_merge_requests(client, project_id, state="all", order_by=None):
    """List merge requests for a project."""
    qs = build_query_string({"state": state, "order_by": order_by})
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/merge_requests{}".format(pid, qs))


def get_merge_request(client, project_id, mr_iid):
    """Get a single merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/merge_requests/{}".format(pid, mr_iid)
    )


def create_merge_request(client, project_id, source_branch, target_branch,
                         title, **kwargs):
    """Create a merge request."""
    pid = client.encode_path(project_id)
    data = {
        "source_branch": source_branch,
        "target_branch": target_branch,
        "title": title,
    }
    data.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api("POST", "/projects/{}/merge_requests".format(pid), data)


def update_merge_request(client, project_id, mr_iid, data=None, **kwargs):
    """Update a merge request with arbitrary data."""
    pid = client.encode_path(project_id)
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT", "/projects/{}/merge_requests/{}".format(pid, mr_iid), body
    )


def delete_merge_request(client, project_id, mr_iid):
    """Delete a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/merge_requests/{}".format(pid, mr_iid)
    )


def merge_merge_request(client, project_id, mr_iid,
                        merge_when_pipeline_succeeds="false",
                        squash="false"):
    """Merge a merge request."""
    pid = client.encode_path(project_id)
    data = {
        "merge_when_pipeline_succeeds": merge_when_pipeline_succeeds == "true",
        "squash": squash == "true",
    }
    return client.api(
        "PUT", "/projects/{}/merge_requests/{}/merge".format(pid, mr_iid),
        data,
    )


def rebase_merge_request(client, project_id, mr_iid):
    """Rebase a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "PUT", "/projects/{}/merge_requests/{}/rebase".format(pid, mr_iid)
    )


def list_mr_changes(client, project_id, mr_iid):
    """List changes/diffs for a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/merge_requests/{}/changes".format(pid, mr_iid)
    )


def list_mr_commits(client, project_id, mr_iid):
    """List commits for a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/merge_requests/{}/commits".format(pid, mr_iid)
    )


def get_mr_approvals(client, project_id, mr_iid):
    """Get approval state for a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/merge_requests/{}/approvals".format(pid, mr_iid)
    )


def approve_merge_request(client, project_id, mr_iid):
    """Approve a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/merge_requests/{}/approve".format(pid, mr_iid)
    )


def unapprove_merge_request(client, project_id, mr_iid):
    """Unapprove a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST",
        "/projects/{}/merge_requests/{}/unapprove".format(pid, mr_iid),
    )


def list_mr_notes(client, project_id, mr_iid):
    """List notes (comments) on a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/merge_requests/{}/notes".format(pid, mr_iid)
    )


def create_mr_note(client, project_id, mr_iid, body):
    """Create a note (comment) on a merge request."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST",
        "/projects/{}/merge_requests/{}/notes".format(pid, mr_iid),
        {"body": body},
    )


if __name__ == "__main__":
    run_cli({
        "list_merge_requests": list_merge_requests,
        "get_merge_request": get_merge_request,
        "create_merge_request": create_merge_request,
        "update_merge_request": update_merge_request,
        "delete_merge_request": delete_merge_request,
        "merge_merge_request": merge_merge_request,
        "rebase_merge_request": rebase_merge_request,
        "list_mr_changes": list_mr_changes,
        "list_mr_commits": list_mr_commits,
        "get_mr_approvals": get_mr_approvals,
        "approve_merge_request": approve_merge_request,
        "unapprove_merge_request": unapprove_merge_request,
        "list_mr_notes": list_mr_notes,
        "create_mr_note": create_mr_note,
    })

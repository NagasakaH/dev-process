#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Issues API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_issues(client, project_id=None, state=None, labels=None,
                search=None):
    """List issues globally or for a specific project."""
    qs = build_query_string({
        "state": state, "labels": labels, "search": search,
    })
    if project_id:
        pid = client.encode_path(project_id)
        return client.api("GET", "/projects/{}/issues{}".format(pid, qs))
    return client.api("GET", "/issues" + qs)


def list_project_issues(client, project_id, state=None, labels=None):
    """List issues for a specific project."""
    pid = client.encode_path(project_id)
    qs = build_query_string({"state": state, "labels": labels})
    return client.api("GET", "/projects/{}/issues{}".format(pid, qs))


def list_group_issues(client, group_id, state=None, labels=None):
    """List issues for a specific group."""
    gid = client.encode_path(group_id)
    qs = build_query_string({"state": state, "labels": labels})
    return client.api("GET", "/groups/{}/issues{}".format(gid, qs))


def get_issue(client, project_id, issue_iid):
    """Get a single issue."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/issues/{}".format(pid, issue_iid))


def create_issue(client, project_id, title, description=None, labels=None,
                 assignee_ids=None, milestone_id=None):
    """Create an issue."""
    pid = client.encode_path(project_id)
    data = {"title": title}
    if description:
        data["description"] = description
    if labels:
        data["labels"] = labels
    if assignee_ids:
        if isinstance(assignee_ids, str):
            import json as _json
            try:
                assignee_ids = _json.loads(assignee_ids)
            except (ValueError, TypeError):
                pass
        data["assignee_ids"] = assignee_ids
    if milestone_id:
        data["milestone_id"] = int(milestone_id)
    return client.api("POST", "/projects/{}/issues".format(pid), data)


def edit_issue(client, project_id, issue_iid, data=None, **kwargs):
    """Edit an issue."""
    pid = client.encode_path(project_id)
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT", "/projects/{}/issues/{}".format(pid, issue_iid), body
    )


def delete_issue(client, project_id, issue_iid):
    """Delete an issue."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/issues/{}".format(pid, issue_iid)
    )


def move_issue(client, project_id, issue_iid, to_project_id):
    """Move an issue to another project."""
    pid = client.encode_path(project_id)
    data = {"to_project_id": int(to_project_id)}
    return client.api(
        "POST", "/projects/{}/issues/{}/move".format(pid, issue_iid), data
    )


def list_issue_notes(client, project_id, issue_iid):
    """List notes on an issue."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/issues/{}/notes".format(pid, issue_iid)
    )


def create_issue_note(client, project_id, issue_iid, body):
    """Create a note on an issue."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST",
        "/projects/{}/issues/{}/notes".format(pid, issue_iid),
        {"body": body},
    )


def list_labels(client, project_id):
    """List project labels."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/labels".format(pid))


def create_label(client, project_id, name, color):
    """Create a project label."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/labels".format(pid),
        {"name": name, "color": color},
    )


def list_milestones(client, project_id):
    """List project milestones."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/milestones".format(pid))


def create_milestone(client, project_id, title):
    """Create a project milestone."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/milestones".format(pid), {"title": title}
    )


if __name__ == "__main__":
    run_cli({
        "list_issues": list_issues,
        "list_project_issues": list_project_issues,
        "list_group_issues": list_group_issues,
        "get_issue": get_issue,
        "create_issue": create_issue,
        "edit_issue": edit_issue,
        "delete_issue": delete_issue,
        "move_issue": move_issue,
        "list_issue_notes": list_issue_notes,
        "create_issue_note": create_issue_note,
        "list_labels": list_labels,
        "create_label": create_label,
        "list_milestones": list_milestones,
        "create_milestone": create_milestone,
    })

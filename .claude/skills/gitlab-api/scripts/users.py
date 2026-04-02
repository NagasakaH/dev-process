#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Users API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_users(client, search=None, username=None, active=None):
    """List users with optional filters."""
    qs = build_query_string({
        "search": search, "username": username, "active": active,
    })
    return client.api("GET", "/users" + qs)


def get_user(client, user_id):
    """Get a single user by ID."""
    return client.api("GET", "/users/{}".format(user_id))


def get_current_user(client):
    """Get the authenticated user."""
    return client.api("GET", "/user")


def get_user_status(client, user_id):
    """Get user status."""
    return client.api("GET", "/users/{}/status".format(user_id))


def set_user_status(client, emoji=None, message=None):
    """Set current user's status with emoji and message."""
    data = {}
    if emoji:
        data["emoji"] = emoji
    if message:
        data["message"] = message
    return client.api("PUT", "/user/status", data)


def list_project_members(client, project_id):
    """List project members."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/members".format(pid))


def list_group_members(client, group_id):
    """List group members."""
    gid = client.encode_path(group_id)
    return client.api("GET", "/groups/{}/members".format(gid))


def add_project_member(client, project_id, user_id, access_level):
    """Add member to project with access level."""
    pid = client.encode_path(project_id)
    data = {"user_id": int(user_id), "access_level": int(access_level)}
    return client.api("POST", "/projects/{}/members".format(pid), data)


def add_group_member(client, group_id, user_id, access_level):
    """Add member to group with access level."""
    gid = client.encode_path(group_id)
    data = {"user_id": int(user_id), "access_level": int(access_level)}
    return client.api("POST", "/groups/{}/members".format(gid), data)


def edit_project_member(client, project_id, user_id, access_level):
    """Edit project member's access level."""
    pid = client.encode_path(project_id)
    data = {"access_level": int(access_level)}
    return client.api(
        "PUT", "/projects/{}/members/{}".format(pid, user_id), data
    )


def remove_project_member(client, project_id, user_id):
    """Remove member from project."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/members/{}".format(pid, user_id)
    )


def remove_group_member(client, group_id, user_id):
    """Remove member from group."""
    gid = client.encode_path(group_id)
    return client.api(
        "DELETE", "/groups/{}/members/{}".format(gid, user_id)
    )


def list_access_tokens(client, project_id):
    """List project access tokens."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/access_tokens".format(pid))


def create_access_token(client, project_id, name, scopes, expires_at=None):
    """Create project access token with name, scopes, expiration."""
    pid = client.encode_path(project_id)
    if isinstance(scopes, str):
        scopes = [s.strip() for s in scopes.split(",")]
    data = {"name": name, "scopes": scopes}
    if expires_at:
        data["expires_at"] = expires_at
    return client.api("POST", "/projects/{}/access_tokens".format(pid), data)


def revoke_access_token(client, project_id, token_id):
    """Revoke a project access token."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/access_tokens/{}".format(pid, token_id)
    )


def list_ssh_keys(client):
    """List SSH keys for current user."""
    return client.api("GET", "/user/keys")


def add_ssh_key(client, title, key):
    """Add SSH key with title."""
    return client.api("POST", "/user/keys", {"title": title, "key": key})


def delete_ssh_key(client, key_id):
    """Delete SSH key by ID."""
    return client.api("DELETE", "/user/keys/{}".format(key_id))


if __name__ == "__main__":
    run_cli({
        "list_users": list_users,
        "get_user": get_user,
        "get_current_user": get_current_user,
        "get_user_status": get_user_status,
        "set_user_status": set_user_status,
        "list_project_members": list_project_members,
        "list_group_members": list_group_members,
        "add_project_member": add_project_member,
        "add_group_member": add_group_member,
        "edit_project_member": edit_project_member,
        "remove_project_member": remove_project_member,
        "remove_group_member": remove_group_member,
        "list_access_tokens": list_access_tokens,
        "create_access_token": create_access_token,
        "revoke_access_token": revoke_access_token,
        "list_ssh_keys": list_ssh_keys,
        "add_ssh_key": add_ssh_key,
        "delete_ssh_key": delete_ssh_key,
    })

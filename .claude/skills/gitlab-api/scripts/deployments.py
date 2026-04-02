#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Deployments, Environments, Releases, Deploy Keys and Tokens API."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


# --- Deployments ---

def list_deployments(client, project_id):
    """List deployments for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/deployments".format(pid))


def get_deployment(client, project_id, deployment_id):
    """Get a specific deployment."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/deployments/{}".format(pid, deployment_id)
    )


# --- Environments ---

def list_environments(client, project_id):
    """List environments for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/environments".format(pid))


def create_environment(client, project_id, name, external_url=None):
    """Create environment with optional external URL."""
    pid = client.encode_path(project_id)
    data = {"name": name}
    if external_url:
        data["external_url"] = external_url
    return client.api("POST", "/projects/{}/environments".format(pid), data)


def stop_environment(client, project_id, environment_id):
    """Stop an environment."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST",
        "/projects/{}/environments/{}/stop".format(pid, environment_id),
    )


def delete_environment(client, project_id, environment_id):
    """Delete an environment."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE",
        "/projects/{}/environments/{}".format(pid, environment_id),
    )


# --- Releases ---

def list_releases(client, project_id):
    """List releases for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/releases".format(pid))


def get_release(client, project_id, tag_name):
    """Get release by tag name."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET",
        "/projects/{}/releases/{}".format(pid, client.encode_path(tag_name)),
    )


def create_release(client, project_id, tag_name, name=None,
                   description=None):
    """Create release with tag, name, description."""
    pid = client.encode_path(project_id)
    data = {"tag_name": tag_name}
    if name:
        data["name"] = name
    if description:
        data["description"] = description
    return client.api("POST", "/projects/{}/releases".format(pid), data)


def update_release(client, project_id, tag_name, data=None, **kwargs):
    """Update a release."""
    pid = client.encode_path(project_id)
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT",
        "/projects/{}/releases/{}".format(pid, client.encode_path(tag_name)),
        body,
    )


def delete_release(client, project_id, tag_name):
    """Delete a release."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE",
        "/projects/{}/releases/{}".format(pid, client.encode_path(tag_name)),
    )


def list_release_links(client, project_id, tag_name):
    """List links of a release."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET",
        "/projects/{}/releases/{}/assets/links".format(
            pid, client.encode_path(tag_name)
        ),
    )


def create_release_link(client, project_id, tag_name, name, url):
    """Create release link with name and URL."""
    pid = client.encode_path(project_id)
    data = {"name": name, "url": url}
    return client.api(
        "POST",
        "/projects/{}/releases/{}/assets/links".format(
            pid, client.encode_path(tag_name)
        ),
        data,
    )


# --- Deploy Keys ---

def list_deploy_keys(client, project_id):
    """List deploy keys for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/deploy_keys".format(pid))


def add_deploy_key(client, project_id, title, key, can_push="false"):
    """Add deploy key with optional push permission."""
    pid = client.encode_path(project_id)
    data = {"title": title, "key": key, "can_push": can_push == "true"}
    return client.api("POST", "/projects/{}/deploy_keys".format(pid), data)


def delete_deploy_key(client, project_id, key_id):
    """Delete deploy key."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/deploy_keys/{}".format(pid, key_id)
    )


# --- Deploy Tokens ---

def list_deploy_tokens(client, project_id):
    """List deploy tokens for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/deploy_tokens".format(pid))


def create_deploy_token(client, project_id, name, scopes,
                        expires_at=None):
    """Create deploy token with scopes and optional expiration."""
    pid = client.encode_path(project_id)
    if isinstance(scopes, str):
        scopes = [s.strip() for s in scopes.split(",")]
    data = {"name": name, "scopes": scopes}
    if expires_at:
        data["expires_at"] = expires_at
    return client.api(
        "POST", "/projects/{}/deploy_tokens".format(pid), data
    )


def delete_deploy_token(client, project_id, token_id):
    """Delete deploy token."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/deploy_tokens/{}".format(pid, token_id)
    )


if __name__ == "__main__":
    run_cli({
        "list_deployments": list_deployments,
        "get_deployment": get_deployment,
        "list_environments": list_environments,
        "create_environment": create_environment,
        "stop_environment": stop_environment,
        "delete_environment": delete_environment,
        "list_releases": list_releases,
        "get_release": get_release,
        "create_release": create_release,
        "update_release": update_release,
        "delete_release": delete_release,
        "list_release_links": list_release_links,
        "create_release_link": create_release_link,
        "list_deploy_keys": list_deploy_keys,
        "add_deploy_key": add_deploy_key,
        "delete_deploy_key": delete_deploy_key,
        "list_deploy_tokens": list_deploy_tokens,
        "create_deploy_token": create_deploy_token,
        "delete_deploy_token": delete_deploy_token,
    })

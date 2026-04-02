#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab Admin and System API functions."""

from __future__ import print_function, unicode_literals

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


# --- Instance Info ---

def get_version(client):
    """Get GitLab instance version."""
    return client.api("GET", "/version")


def get_metadata(client):
    """Get GitLab instance metadata."""
    return client.api("GET", "/metadata")


# --- Feature Flags ---

def list_features(client):
    """List all feature flags."""
    return client.api("GET", "/features")


def set_feature(client, name, value, key=None, user=None, group=None,
                project=None):
    """Set/create feature flag with optional scope."""
    data = {"value": value}
    if key:
        data["key"] = key
    if user:
        data["user"] = user
    if group:
        data["group"] = group
    if project:
        data["project"] = project
    return client.api("POST", "/features/{}".format(name), data)


def delete_feature(client, name):
    """Delete a feature flag."""
    return client.api("DELETE", "/features/{}".format(name))


# --- Broadcast Messages ---

def list_broadcast_messages(client):
    """List all broadcast messages."""
    return client.api("GET", "/broadcast_messages")


def create_broadcast_message(client, message, starts_at=None, ends_at=None,
                             color=None, font=None):
    """Create broadcast message with optional timing and styling."""
    data = {"message": message}
    if starts_at:
        data["starts_at"] = starts_at
    if ends_at:
        data["ends_at"] = ends_at
    if color:
        data["color"] = color
    if font:
        data["font"] = font
    return client.api("POST", "/broadcast_messages", data)


def update_broadcast_message(client, message_id, data=None, **kwargs):
    """Update a broadcast message."""
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api(
        "PUT", "/broadcast_messages/{}".format(message_id), body
    )


def delete_broadcast_message(client, message_id):
    """Delete a broadcast message."""
    return client.api("DELETE", "/broadcast_messages/{}".format(message_id))


# --- System Hooks ---

def list_system_hooks(client):
    """List system hooks."""
    return client.api("GET", "/hooks")


def add_system_hook(client, url, token=None, push_events="true",
                    tag_push_events=None, merge_requests_events=None):
    """Add system hook with optional token and event filters."""
    data = {"url": url, "push_events": push_events == "true"}
    if token:
        data["token"] = token
    if tag_push_events is not None:
        data["tag_push_events"] = tag_push_events == "true"
    if merge_requests_events is not None:
        data["merge_requests_events"] = merge_requests_events == "true"
    return client.api("POST", "/hooks", data)


def delete_system_hook(client, hook_id):
    """Delete a system hook."""
    return client.api("DELETE", "/hooks/{}".format(hook_id))


# --- Applications ---

def list_applications(client):
    """List OAuth applications."""
    return client.api("GET", "/applications")


def create_application(client, name, redirect_uri, scopes):
    """Create application with name, redirect_uri, scopes."""
    data = {"name": name, "redirect_uri": redirect_uri, "scopes": scopes}
    return client.api("POST", "/applications", data)


def delete_application(client, application_id):
    """Delete application."""
    return client.api("DELETE", "/applications/{}".format(application_id))


# --- Namespaces ---

def list_namespaces(client, search=None):
    """List namespaces with optional search."""
    qs = build_query_string({"search": search})
    return client.api("GET", "/namespaces" + qs)


def get_namespace(client, namespace_id):
    """Get namespace by ID or path."""
    return client.api(
        "GET",
        "/namespaces/{}".format(client.encode_path(namespace_id)),
    )


# --- Settings ---

def get_settings(client):
    """Get current application settings."""
    return client.api("GET", "/application/settings")


def update_settings(client, data=None, **kwargs):
    """Update application settings."""
    body = data if isinstance(data, dict) else {}
    body.update({k: v for k, v in kwargs.items() if v is not None})
    return client.api("PUT", "/application/settings", body)


if __name__ == "__main__":
    run_cli({
        "get_version": get_version,
        "get_metadata": get_metadata,
        "list_features": list_features,
        "set_feature": set_feature,
        "delete_feature": delete_feature,
        "list_broadcast_messages": list_broadcast_messages,
        "create_broadcast_message": create_broadcast_message,
        "update_broadcast_message": update_broadcast_message,
        "delete_broadcast_message": delete_broadcast_message,
        "list_system_hooks": list_system_hooks,
        "add_system_hook": add_system_hook,
        "delete_system_hook": delete_system_hook,
        "list_applications": list_applications,
        "create_application": create_application,
        "delete_application": delete_application,
        "list_namespaces": list_namespaces,
        "get_namespace": get_namespace,
        "get_settings": get_settings,
        "update_settings": update_settings,
    })

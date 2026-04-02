#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""GitLab CI/CD API functions."""

from __future__ import print_function, unicode_literals

import json as _json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import GitLabClient, build_query_string, run_cli


def list_pipelines(client, project_id, status=None, ref=None,
                   order_by=None):
    """List pipelines for a project."""
    pid = client.encode_path(project_id)
    qs = build_query_string({
        "status": status, "ref": ref, "order_by": order_by,
    })
    return client.api("GET", "/projects/{}/pipelines{}".format(pid, qs))


def get_pipeline(client, project_id, pipeline_id):
    """Get a single pipeline."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/pipelines/{}".format(pid, pipeline_id)
    )


def create_pipeline(client, project_id, ref, variables=None):
    """Create a new pipeline with optional variables."""
    pid = client.encode_path(project_id)
    data = {"ref": ref}
    if variables:
        if isinstance(variables, str):
            variables = _json.loads(variables)
        data["variables"] = variables
    return client.api("POST", "/projects/{}/pipeline".format(pid), data)


def cancel_pipeline(client, project_id, pipeline_id):
    """Cancel a pipeline."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/pipelines/{}/cancel".format(pid, pipeline_id)
    )


def retry_pipeline(client, project_id, pipeline_id):
    """Retry a pipeline."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/pipelines/{}/retry".format(pid, pipeline_id)
    )


def delete_pipeline(client, project_id, pipeline_id):
    """Delete a pipeline."""
    pid = client.encode_path(project_id)
    return client.api(
        "DELETE", "/projects/{}/pipelines/{}".format(pid, pipeline_id)
    )


def list_pipeline_jobs(client, project_id, pipeline_id):
    """List jobs for a pipeline."""
    pid = client.encode_path(project_id)
    return client.api(
        "GET", "/projects/{}/pipelines/{}/jobs".format(pid, pipeline_id)
    )


def get_job(client, project_id, job_id):
    """Get a single job."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/jobs/{}".format(pid, job_id))


def cancel_job(client, project_id, job_id):
    """Cancel a job."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/jobs/{}/cancel".format(pid, job_id)
    )


def retry_job(client, project_id, job_id):
    """Retry a job."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/jobs/{}/retry".format(pid, job_id)
    )


def play_job(client, project_id, job_id):
    """Play a manual job."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/jobs/{}/play".format(pid, job_id)
    )


def get_job_log(client, project_id, job_id):
    """Get job log (trace) as plain text."""
    pid = client.encode_path(project_id)
    url = "{}/projects/{}/jobs/{}/trace".format(client.api_base, pid, job_id)
    from urllib.request import Request, urlopen
    from urllib.error import HTTPError

    req = Request(url, method="GET")
    req.add_header("PRIVATE-TOKEN", client.token)
    try:
        resp = urlopen(req)
        return resp.read().decode("utf-8", errors="replace")
    except HTTPError as e:
        error_body = e.read().decode("utf-8")
        print("ERROR: HTTP {} from GET job log".format(e.code), file=sys.stderr)
        print(error_body, file=sys.stderr)
        sys.exit(1)


def download_artifacts(client, project_id, job_id, output_path):
    """Download job artifacts to a file."""
    pid = client.encode_path(project_id)
    client.download(
        "/projects/{}/jobs/{}/artifacts".format(pid, job_id), output_path
    )
    return {"status": "downloaded", "path": output_path}


def list_runners(client, scope=None):
    """List runners with optional scope filter."""
    qs = build_query_string({"scope": scope})
    return client.api("GET", "/runners" + qs)


def get_runner(client, runner_id):
    """Get runner details."""
    return client.api("GET", "/runners/{}".format(runner_id))


def list_project_runners(client, project_id):
    """List runners for a project."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/runners".format(pid))


def list_project_variables(client, project_id):
    """List project-level CI/CD variables."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/variables".format(pid))


def get_project_variable(client, project_id, key):
    """Get a single project variable."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/variables/{}".format(pid, key))


def create_project_variable(client, project_id, key, value,
                            protected="false", masked="false"):
    """Create a project CI/CD variable."""
    pid = client.encode_path(project_id)
    data = {
        "key": key,
        "value": value,
        "protected": protected == "true",
        "masked": masked == "true",
    }
    return client.api("POST", "/projects/{}/variables".format(pid), data)


def update_project_variable(client, project_id, key, value,
                            protected=None, masked=None):
    """Update a project CI/CD variable."""
    pid = client.encode_path(project_id)
    data = {"value": value}
    if protected is not None:
        data["protected"] = protected == "true"
    if masked is not None:
        data["masked"] = masked == "true"
    return client.api(
        "PUT", "/projects/{}/variables/{}".format(pid, key), data
    )


def delete_project_variable(client, project_id, key):
    """Delete a project CI/CD variable."""
    pid = client.encode_path(project_id)
    return client.api("DELETE", "/projects/{}/variables/{}".format(pid, key))


def list_pipeline_schedules(client, project_id):
    """List pipeline schedules."""
    pid = client.encode_path(project_id)
    return client.api("GET", "/projects/{}/pipeline_schedules".format(pid))


def create_pipeline_schedule(client, project_id, description, ref, cron,
                             cron_timezone=None, active="true"):
    """Create a pipeline schedule with cron expression."""
    pid = client.encode_path(project_id)
    data = {
        "description": description,
        "ref": ref,
        "cron": cron,
        "active": active == "true",
    }
    if cron_timezone:
        data["cron_timezone"] = cron_timezone
    return client.api(
        "POST", "/projects/{}/pipeline_schedules".format(pid), data
    )


def trigger_pipeline(client, project_id, ref, trigger_token, variables=None):
    """Trigger a pipeline via trigger token."""
    pid = client.encode_path(project_id)
    data = {"ref": ref, "token": trigger_token}
    if variables:
        if isinstance(variables, str):
            variables = _json.loads(variables)
        data["variables"] = variables
    return client.api("POST", "/projects/{}/trigger/pipeline".format(pid), data)


def lint_ci(client, project_id, content):
    """Validate CI/CD configuration content."""
    pid = client.encode_path(project_id)
    return client.api(
        "POST", "/projects/{}/ci/lint".format(pid), {"content": content}
    )


if __name__ == "__main__":
    run_cli({
        "list_pipelines": list_pipelines,
        "get_pipeline": get_pipeline,
        "create_pipeline": create_pipeline,
        "cancel_pipeline": cancel_pipeline,
        "retry_pipeline": retry_pipeline,
        "delete_pipeline": delete_pipeline,
        "list_pipeline_jobs": list_pipeline_jobs,
        "get_job": get_job,
        "cancel_job": cancel_job,
        "retry_job": retry_job,
        "play_job": play_job,
        "get_job_log": get_job_log,
        "download_artifacts": download_artifacts,
        "list_runners": list_runners,
        "get_runner": get_runner,
        "list_project_runners": list_project_runners,
        "list_project_variables": list_project_variables,
        "get_project_variable": get_project_variable,
        "create_project_variable": create_project_variable,
        "update_project_variable": update_project_variable,
        "delete_project_variable": delete_project_variable,
        "list_pipeline_schedules": list_pipeline_schedules,
        "create_pipeline_schedule": create_pipeline_schedule,
        "trigger_pipeline": trigger_pipeline,
        "lint_ci": lint_ci,
    })

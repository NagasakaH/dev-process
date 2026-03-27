# Packages API Reference

GitLab REST API v4 reference for the Package Registry, Generic Packages, NPM, PyPI, Maven, and NuGet.

**Base URL:** `https://gitlab.example.com/api/v4`

**Authentication:** Pass a `PRIVATE-TOKEN` header or `access_token` query parameter. Package endpoints also support `JOB-TOKEN` for CI/CD pipelines and deploy tokens.

---

## Package Registry

### List project packages

```
GET /projects/:id/packages
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_type` | string | no | Filter by type: `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, `generic` |
| `package_name` | string | no | Filter by package name |
| `status` | string | no | Filter by status: `default`, `hidden`, `processing`, `error` |
| `order_by` | string | no | `name`, `created_at`, `version`, or `type` (default: `created_at`) |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### List group packages

```
GET /groups/:id/packages
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Group ID or URL-encoded path |
| `exclude_subgroups` | boolean | no | If `true`, packages from subgroups are not listed (default: `false`) |
| `package_type` | string | no | Filter by type: `conan`, `maven`, `npm`, `pypi`, `composer`, `nuget`, `helm`, `generic` |
| `package_name` | string | no | Filter by package name |
| `order_by` | string | no | `name`, `created_at`, `version`, or `type` (default: `created_at`) |
| `sort` | string | no | `asc` or `desc` (default: `desc`) |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

### Get single package

```
GET /projects/:id/packages/:package_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_id` | integer | yes | ID of the package |

### Delete package

```
DELETE /projects/:id/packages/:package_id
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_id` | integer | yes | ID of the package |

### List package files

```
GET /projects/:id/packages/:package_id/package_files
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_id` | integer | yes | ID of the package |
| `per_page` | integer | no | Results per page (default: 20, max: 100) |
| `page` | integer | no | Page number (default: 1) |

---

## Generic Packages

### Upload a package file

```
PUT /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

Upload a file to the generic package registry. The request body is the file content.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_name` | string | yes | Package name (1–255 chars, `a-zA-Z0-9._-`) |
| `package_version` | string | yes | Package version (semantic versioning recommended) |
| `file_name` | string | yes | File name (1–255 chars, `a-zA-Z0-9._-`) |
| `status` | string | no | Package status: `default` (default) or `hidden` |
| `select` | string | no | Response payload: `package_file` (default) returns file details |

**Headers:**

| Header | Description |
|---|---|
| `Content-Type` | MIME type of the file (e.g., `application/octet-stream`) |

### Download a package file

```
GET /projects/:id/packages/generic/:package_name/:package_version/:file_name
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_name` | string | yes | Package name |
| `package_version` | string | yes | Package version |
| `file_name` | string | yes | File name |

---

## NPM

### Scope setup

Configure your npm client to use the GitLab registry for a given scope:

```bash
# Project-level
npm config set @scope:registry https://gitlab.example.com/api/v4/projects/:id/packages/npm/
npm config set -- '//gitlab.example.com/api/v4/projects/:id/packages/npm/:_authToken' "<token>"

# Instance-level
npm config set @scope:registry https://gitlab.example.com/api/v4/packages/npm/
npm config set -- '//gitlab.example.com/api/v4/packages/npm/:_authToken' "<token>"
```

### Upload (publish) a package

```
PUT /projects/:id/packages/npm/:package_name
```

Publish is typically done via the npm CLI:

```bash
npm publish
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_name` | string | yes | Full scoped package name (e.g., `@scope/my-package`) |

The `package.json` must include `"publishConfig": { "registry": "https://gitlab.example.com/api/v4/projects/:id/packages/npm/" }`.

### Download (install) a package

Install packages via the npm CLI after configuring the scope:

```bash
npm install @scope/my-package
```

---

## PyPI

### Upload a package

```
POST /projects/:id/packages/pypi
```

Upload via `twine`:

```bash
TWINE_PASSWORD=<token> TWINE_USERNAME=<username> \
  python -m twine upload --repository-url https://gitlab.example.com/api/v4/projects/:id/packages/pypi dist/*
```

Or via multipart form upload:

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `content` | file | yes | The package file (multipart form field) |
| `name` | string | yes | Package name |
| `version` | string | yes | Package version |

### Download a package

```
GET /projects/:id/packages/pypi/simple/:package_name
```

Configure `pip` to use the GitLab PyPI registry:

```bash
pip install --index-url https://<username>:<token>@gitlab.example.com/api/v4/projects/:id/packages/pypi/simple my-package
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_name` | string | yes | Normalized package name |

---

## Maven

### Deploy a package

```
PUT /projects/:id/packages/maven/:path/:file_name
```

Deploy is typically done via Maven or Gradle. Configure the repository in `pom.xml` or `build.gradle`:

```xml
<repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/:id/packages/maven</url>
</repository>
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `path` | string | yes | Maven path (group ID + artifact ID as path, e.g., `com/example/my-app/1.0`) |
| `file_name` | string | yes | File name (e.g., `my-app-1.0.jar`) |

### Download a package

```
GET /projects/:id/packages/maven/:path/:file_name
```

Configure Maven or Gradle to resolve from the GitLab registry:

```xml
<repository>
    <id>gitlab-maven</id>
    <url>https://gitlab.example.com/api/v4/projects/:id/packages/maven</url>
</repository>
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `path` | string | yes | Maven path |
| `file_name` | string | yes | File name to download |

---

## NuGet

### Push a package

```
PUT /projects/:id/packages/nuget
```

Push via the `dotnet` CLI or `nuget` CLI:

```bash
dotnet nuget push my-package.1.0.0.nupkg --source https://gitlab.example.com/api/v4/projects/:id/packages/nuget/index.json --api-key <token>
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |

The request body is the `.nupkg` file content.

### Download a package

```
GET /projects/:id/packages/nuget/download/:package_name/:package_version/:file_name
```

Install via the `dotnet` CLI after adding the source:

```bash
dotnet nuget add source https://gitlab.example.com/api/v4/projects/:id/packages/nuget/index.json --name gitlab --username <username> --password <token>
dotnet add package my-package --version 1.0.0
```

| Parameter | Type | Required | Description |
|---|---|---|---|
| `id` | integer/string | yes | Project ID or URL-encoded path |
| `package_name` | string | yes | Package name (case-insensitive) |
| `package_version` | string | yes | Package version |
| `file_name` | string | yes | File name (e.g., `my-package.1.0.0.nupkg`) |

---

## Common Parameters

These query parameters are shared across most list endpoints:

| Parameter | Type | Description |
|---|---|---|
| `package_type` | string | Filter by package type |
| `package_name` | string | Filter by package name |
| `order_by` | string | Order by `name`, `created_at`, `version`, or `type` |
| `sort` | string | Sort direction: `asc` or `desc` |
| `per_page` | integer | Results per page (default: 20, max: 100) |
| `page` | integer | Page number for pagination |

## Response Codes

| Code | Description |
|---|---|
| `200` | Success (GET, PUT download) |
| `201` | Created (PUT upload, POST) |
| `204` | No Content (DELETE) |
| `400` | Bad request (invalid parameters) |
| `401` | Unauthorized (missing or invalid token) |
| `403` | Forbidden (insufficient permissions) |
| `404` | Not found (project, package, or file does not exist) |
| `409` | Conflict (duplicate package version) |

# GitLab Flavored Markdown (GLFM) Reference

GitLab Flavored Markdown (GLFM) is the markup language used in all text fields across GitLab — issues, merge requests, comments (notes), epics, milestones, snippets, wiki pages, and repository Markdown files.

All `description` and `body` fields in the GitLab API accept GLFM. Use GLFM formatting when composing text content via the API to ensure proper rendering in the GitLab UI.

**Official documentation:** <https://docs.gitlab.com/ee/user/markdown/>

---

## Quick Reference

### Headings

```markdown
# H1
## H2
### H3
#### H4
```

### Emphasis

```markdown
*italic* or _italic_
**bold** or __bold__
**bold and _italic_**
~~strikethrough~~
```

### Line Breaks

A single newline does **not** create a line break. Use one of:

- Two newlines (empty line) for a new paragraph
- Two trailing spaces or a trailing backslash (`\`) for a soft line break within a paragraph

### Lists

```markdown
- Unordered item
  - Nested item

1. Ordered item
2. Another item
```

### Task Lists

```markdown
- [x] Completed task
- [~] Inapplicable task
- [ ] Incomplete task
  - [x] Sub-task
```

### Tables

```markdown
| Left-aligned | Centered | Right-aligned |
| :----------- | :------: | ------------: |
| Cell 1       | Cell 2   |        Cell 3 |
| Cell 4       | Cell 5   |        Cell 6 |
```

Use `<br>` for multi-line cell content.

### Code Blocks

````markdown
Inline: `code`

Fenced with syntax highlighting:

```python
def hello():
    return "world"
```

```bash
curl -s https://example.com
```
````

### Blockquotes

```markdown
> This is a blockquote.
> It can span multiple lines.
```

### Alerts

```markdown
> [!NOTE]
> Useful information that users should know.

> [!TIP]
> Helpful advice for doing things better or more easily.

> [!IMPORTANT]
> Key information users need to know.

> [!WARNING]
> Urgent info that needs immediate user attention.

> [!CAUTION]
> Advises about risks or negative outcomes.
```

### Inline Diff

```markdown
{+ added text +}
{- removed text -}
[+ also added +]
[- also removed -]
```

### Emoji

```markdown
:tada: :rocket: :thumbsup: :white_check_mark: :construction: :eyes: :bug:
```

Full list: <https://www.webfx.com/tools/emoji-cheat-sheet/> (GitLab supports gemoji names).

### Images

```markdown
![alt text](/uploads/hash/filename.png)
![alt text](https://example.com/image.png)
```

Upload images first via `POST /projects/:id/uploads` (see [projects.md](projects.md#upload-a-file-to-a-project)), then embed the returned `markdown` field.

### Links

```markdown
[Link text](https://example.com)
[Link with title](https://example.com "Title text")
[Relative link to file](path/to/file.md)
[Anchor link to heading](#heading-id)
```

### Collapsible Sections

```markdown
<details>
<summary>Click to expand</summary>

Hidden content here.

- Item 1
- Item 2

</details>
```

> **Note:** An empty line is required after `<summary>` and before `</details>` for Markdown to render inside the collapsible block.

### Horizontal Rule

```markdown
---
```

### Description Lists

```markdown
Term
: Definition 1
: Definition 2
```

---

## GitLab-Specific References

GitLab automatically links the following references when used in any Markdown field:

| Reference | Syntax | Cross-project syntax |
| :--- | :--- | :--- |
| User mention | `@username` | — |
| Group mention | `@groupname` | — |
| Issue | `#123` | `namespace/project#123` |
| Merge request | `!123` | `namespace/project!123` |
| Snippet | `$123` | `namespace/project$123` |
| Epic | `&123` | `group/subgroup&123` |
| Label (by name) | `~bug` or `~"feature request"` | `namespace/project~"label"` |
| Label (scoped) | `~"priority::high"` | `namespace/project~"priority::high"` |
| Milestone | `%v1.0` or `%"release candidate"` | `namespace/project%"milestone"` |
| Commit | `9ba12248` (8+ hex chars) | `namespace/project@9ba12248` |
| Commit range | `9ba12248...b19a04f5` | `namespace/project@9ba12248...b19a04f5` |
| Vulnerability | `[vulnerability:123]` | `[vulnerability:namespace/project/123]` |

### Show Item Title

Append `+` to a reference to display the item title:
- `#123+` renders as "The issue title (#123)"

### Show Item Summary

Append `+s` to display assignees, milestone, and health status:
- `#123+s` renders as "The issue title (#123) • Assignee • v1.0 • On track"

### Escape a Reference

Prefix with backslash to prevent linking: `\#123` renders as literal `#123`.

---

## Formatting Tips for API Usage

When composing `description` or `body` fields via the API:

1. **Use actual newlines** in your JSON strings — not literal `\n` text.
   Use `jq` or a scripting language to build JSON properly:
   ```bash
   # Good: use printf for real newlines, then jq for JSON encoding
   DESCRIPTION=$(printf "## Title\n\nParagraph text.\n\n- Item 1\n- Item 2")
   JSON=$(jq -n --arg desc "$DESCRIPTION" '{description: $desc}')
   ```

2. **Embed uploaded file links** by including the `markdown` field from the upload response directly in the description.

3. **Use collapsible sections** for long content (logs, traces, configs) to keep descriptions readable.

4. **Use task lists** in issue and MR descriptions for trackable checklists.

5. **Use tables** to present structured information clearly.

6. **Reference related items** using GitLab references (`#123`, `!456`) for automatic cross-linking.

---

## Notes

- GLFM extends [CommonMark](https://spec.commonmark.org/current/) and [GitHub Flavored Markdown (GFM)](https://github.github.com/gfm/) with GitLab-specific features.
- Rendering may vary slightly between GitLab versions.
- Some features (epics, scoped labels) require GitLab Premium or Ultimate.
- See the [official GitLab Markdown documentation](https://docs.gitlab.com/ee/user/markdown/) for the complete reference.

# review

Purpose: Implement a code-review skill that performs checklist-based reviews of implementation changes (PRs/SHA ranges). It checks design conformance, static analysis (editorconfig, formatters, linters), language-specific anti-patterns, and security issues. Results are written under docs/{target_repo}/review/ and a summary + checklist status is updated in project.yaml under code_review.reviewers.

Outputs

- docs/{target_repo}/review/round-01.md (and subsequent rounds)
- project.yaml: code_review:
  - review_checklist: (list of checks)
  - rounds: (records per round with status and items)

Checklist (default)

1. Design conformance
   - [ ] Implements the design artifacts in docs/*/design
   - [ ] API/Interface compatibility preserved
2. Static analysis & formatting
   - [ ] .editorconfig honoured for whitespace/indentation
   - [ ] Project formatters (prettier/black/gofmt) configured and applied
   - [ ] Linters (eslint/flake8/golangci-lint) configured and no new errors
3. Language-specific best practices
   - [ ] No obvious anti-patterns per language (JS/TS, Python, Go, Java)
   - [ ] Proper error handling and null checks
4. Security
   - [ ] No secrets committed
   - [ ] Input validation and output encoding where needed
   - [ ] Use of secure defaults (TLS, crypto libraries)
5. Tests & CI
   - [ ] Tests added/updated for new behavior
   - [ ] CI config covers new tests and passes
6. Documentation
   - [ ] Public API documented
   - [ ] CHANGELOG/PR description updated

Workflow

- Invoke review skill against a PR or commit range.
- Skill runs checks (static analysis commands where available), produces a checklist and detailed findings in docs/{target_repo}/review/round-N.md and updates project.yaml with summary and per-item results.
- After developer fixes, re-run review; repeat until all critical items are cleared.

Usage (agent)

- This SKILL file documents expected behavior and templates; implementation is provided by the "review" agent under .claude/skills/review/implementation (not included here).
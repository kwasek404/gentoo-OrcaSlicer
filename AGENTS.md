# AGENTS.md - gentoo-OrcaSlicer

Rules and conventions for AI agents working on this repository.

## Project Overview

Gentoo portage overlay packaging OrcaSlicer and its missing dependencies.
Two-phase approach: local Docker build validation, then GitHub Actions automation.

## Language

- All repository content (ebuilds, metadata, comments, commits, docs): **English**.
- Commit messages: single-line, concise, English.

## Branching & Commits

- Feature branches + PRs against `main`. No direct commits to `main`.
- Split large changes into focused commits (e.g., one per ebuild category).
- Propose commit message before committing - never commit without approval.

## Ebuild Conventions

### General

- EAPI=8 for all ebuilds.
- Follow Gentoo Developer Manual and GLEP standards.
- Use system dependencies from portage wherever available - never bundle what portage provides.
- Each missing dependency gets its own ebuild in the overlay, not vendored into orcaslicer.
- Pin to exact upstream versions matching OrcaSlicer's `deps/` pinning where relevant.

### OrcaSlicer Ebuild

- Stable ebuilds from tags matching `v*.*.*` only (exclude `-rc`, `-beta`, `-dev`, `-alpha`).
- Live `9999` ebuild tracking `main` branch.
- SRC_URI pattern: `https://github.com/OrcaSlicer/OrcaSlicer/archive/refs/tags/v${PV}.tar.gz`
- CMake flags:
  ```
  -DSLIC3R_FHS=ON
  -DSLIC3R_STATIC=OFF
  -DSLIC3R_GUI=ON
  -DSLIC3R_PCH=OFF
  -DSLIC3R_GTK=3
  -DBUILD_TESTS=$(usex test)
  -DORCA_TOOLS=OFF
  -Wno-dev
  ```
- Try system OpenSSL 3.x first; patch only if build breaks.

### wxGTK Slot

- Package: `x11-libs/wxGTK`, slot: `3.3-gtk3-orca`.
- Source: Orca's wxWidgets fork (`SoftFever/Orca-deps-wxWidgets`), NOT vanilla wxWidgets.
- Same package name as system wxGTK to maintain portage consistency.
- Unique slot prevents collision with future official 3.3 packaging.

### Overlay Category Assignments

| Package | Category | Notes |
|---------|----------|-------|
| draco | media-libs | find_package(draco REQUIRED) in OrcaSlicer |
| libnoise | dev-libs | find_package(libnoise REQUIRED) in OrcaSlicer |
| wxGTK (orca) | x11-libs | Orca's wxWidgets fork, slot 3.3-gtk3-orca |
| orcaslicer | media-gfx | Main package |

**Bundled deps (NO ebuilds needed):** clipper2, mcut, md4c, qoi, opencsg, and many others are built unconditionally via `add_subdirectory(deps_src)` in OrcaSlicer's CMakeLists.txt. Only `draco` and `libnoise` use `find_package()` and require system-level packaging.

## Portage Package Research

When investigating available package versions, KEYWORDS, slots, or USE flags:

- **Use portage query tools** (`eix`, `equery`, `portageq`, `qatom`), not raw grep on ebuild files. Ebuilds use eclasses, conditionals, and inherited variables that grep cannot resolve.
  ```bash
  eix -e category/package                    # versions, slots, KEYWORDS, USE
  portageq best_visible / category/package   # best installable version
  equery list -po category/package           # all available versions
  ```
- **Never assume latest-stable is the only option.** Before patching for API incompatibility with a library, check if an older stable version in portage would eliminate the need for the patch. Weigh patching vs version pinning in DEPEND.
- **KEYWORDS are not always at line start.** GCC and other toolchain ebuilds set KEYWORDS inside conditionals with indentation. Grepping `^KEYWORDS=` will miss them.

## Docker Testing

- Base image: `gentoo/stage3:systemd-*` (latest available tag).
- Containerfile and `scripts/test-build.sh` at repo root.
- All builds must succeed in container before merging.

## GitHub Actions Automation

### Workflows

1. **check-release.yml** (daily cron) - detect new stable OrcaSlicer tags via GitHub API.
2. **update-ebuild.yml** (workflow_dispatch) - Copilot CLI analyzes diff between tags, generates/updates ebuild, opens PR.
3. **test-ebuild.yml** (PR trigger) - builds in Gentoo container as CI check.

### Copilot CLI Usage

- Default model: **Claude Sonnet 4.6**, escalate to **Opus 4.6** on failure.
- Allowed tools: `shell(git:*)`, `write`. No `--ask-user`.
- On failure: open GitHub issue with full diagnostics (tag, diff summary, error log). Never fail silently.
- Never commit directly to `main` - always open PR.

### Automation Scope

- ~90% of version bumps are automatable (version number, manifest, basic CMake flag changes).
- ~10% require manual intervention (new deps not in portage, breaking API changes).
- Copilot CLI must detect these edge cases and escalate via issue creation.

## Security

- No secrets in ebuilds or scripts.
- Docker builds run unprivileged where possible.
- PAT for Copilot CLI stored as GitHub Actions secret (`PERSONAL_ACCESS_TOKEN`).

## Code Quality

- No comments unless genuinely necessary for understanding.
- Follow existing Gentoo ebuild formatting conventions.
- Metadata.xml for every package with upstream maintainer info and USE flag descriptions.
- Keep ebuilds minimal and readable - no spaghetti logic.

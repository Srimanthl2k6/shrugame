# Shrugame Production Manifest

## Purpose

This manifest is the Pass 47 source of truth for production readiness. The machine-readable rules live in `docs/PRODUCTION_MANIFEST.json`; `tests/pass47_production_baseline_smoke.gd` recursively audits every covered file and fails when a file has no classification.

## Status Policy

| Status | Meaning | May Ship? |
| --- | --- | --- |
| `blockout` | Temporary layout, stand-in, legacy prototype, or debug presentation | No |
| `draft` | Functional or authored, but still needs substantial production work | No |
| `curated` | Reviewed and suitable for production use, but not release-approved | Only in internal builds |
| `final` | Passed content, visual, technical, accessibility, and export QA | Yes |

`final` is deliberately strict. A file does not become final merely because it exists, is attractive in isolation, or passes a load test.

## Baseline Coverage

The Pass 47 inventory contains 324 production-relevant files:

| Category | Files | Current assessment |
| --- | ---: | --- |
| Godot scenes | 19 | Level 5 blockout; all other scenes draft |
| Runtime visuals and fonts | 235 | Mixed blockout, draft, curated, and licensed-font final |
| Music and sound | 20 | Draft placeholder production |
| Dialogue sets | 5 | Draft |
| Cutscene files | 25 | Catalog curated; sequences draft |
| Non-exported source art | 20 | Draft source material |

The classification uses ordered exact-path and prefix rules. Specific exceptions are evaluated before broad fallbacks. The automated audit reports resolved counts on every run, so later passes can promote files without losing coverage.

## Current Blockers

- `scenes/levels/level_05.tscn` is still a visible blockout.
- Legacy echo/graybox assets remain in the repository and must not appear in final scenes.
- No world scene is yet a production multi-room district.
- Foreground pixel density is inconsistent, especially in Level 1.
- Current audio is placeholder-grade.
- No gameplay scene, boss set, dialogue set, or cutscene sequence is release-approved.
- The Silkscreen font files and license are the only currently final asset family.

## Promotion Gate

A rule may be promoted to `final` only after all of these checks pass:

1. The content is used by the final runtime path.
2. No placeholder or debug dependency remains.
3. Visual/audio/editorial review passes in context.
4. Required animations and state variants exist.
5. Supported resolution, input, and accessibility checks pass.
6. Automated scene/data/export checks pass.
7. The file is confirmed present in the intended package and absent from unintended packages.

## Privacy Boundary

The `shrububu- child/` and `shrububu- older/` directories are private identity references, not production assets. They are ignored by Git, isolated with `.gdignore`, excluded from Godot exports, and intentionally absent from this content manifest. Export QA must scan compiled output for both folder names and source filenames before any release.

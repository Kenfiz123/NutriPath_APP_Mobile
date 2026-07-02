## Project Workflow Notes

- For this repository, Flutter/Dart commands have repeatedly timed out inside the sandbox even when the same commands complete quickly outside it. Start in the sandbox as required, but after the first sandbox timeout or clear sandbox-related hang for `flutter pub get`, `dart format`, `flutter analyze`, or `flutter test`, rerun the same command with `sandbox_permissions: "require_escalated"` and a concise justification instead of retrying repeatedly in the sandbox.
- Use `npm.cmd` instead of `npm` from PowerShell in this repo because `npm.ps1` can be blocked by the Windows execution policy.
- Git commands may fail under the sandbox user because of Git safe-directory ownership. Prefer one-shot commands with `git -c safe.directory=C:/Users/ADMIN/Desktop/PRM/NutriPath_APP_Mobile ...`; do not write global Git config unless the user explicitly asks.
- If GitNexus `detect_changes` needs Git access, pass safe-directory through the command environment or one-shot Git config so it can run without changing global config.

<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **NutriPath_APP_Mobile** (2328 symbols, 5757 relationships, 194 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> Index stale? Run `node .gitnexus/run.cjs analyze` from the project root — it auto-selects an available runner. No `.gitnexus/run.cjs` yet? `npx gitnexus analyze` (npm 11 crash → `npm i -g gitnexus`; #1939).

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows. For regression review, compare against the default branch: `detect_changes({scope: "compare", base_ref: "main"})`.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `rename` which understands the call graph.
- NEVER commit changes without running `detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/NutriPath_APP_Mobile/context` | Codebase overview, check index freshness |
| `gitnexus://repo/NutriPath_APP_Mobile/clusters` | All functional areas |
| `gitnexus://repo/NutriPath_APP_Mobile/processes` | All execution flows |
| `gitnexus://repo/NutriPath_APP_Mobile/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->

# LiftOS 2.0 — Claude Code instructions

Native iOS workout tracker. Xcode 26.4, Swift 6.3, iOS 17+, SwiftUI only, zero third-party deps. Local data via SwiftData. See `docs/PROJECT_PLAN.md` for the data model and feature scope.

---

## Mandatory skills

Two plugins are installed in this repo. **Use them — don't reinvent what they do.**

### `superpowers` — for all engineering work

Invoke the matching skill before/while doing the work. Examples:

| When you're about to... | Use this skill |
|---|---|
| Brainstorm a feature or design before coding | `superpowers:brainstorming` |
| Write a multi-step implementation plan | `superpowers:writing-plans` |
| Execute a written plan | `superpowers:executing-plans` |
| Implement any feature or bugfix | `superpowers:test-driven-development` |
| Debug a bug, test failure, or unexpected behavior | `superpowers:systematic-debugging` |
| Claim work is complete (before commit/PR) | `superpowers:verification-before-completion` |
| Wrap up a development branch | `superpowers:finishing-a-development-branch` |
| Receive code review feedback | `superpowers:receiving-code-review` |
| Need a code review on completed work | `superpowers:requesting-code-review` |
| Run 2+ independent tasks at once | `superpowers:dispatching-parallel-agents` |
| Start isolated feature work | `superpowers:using-git-worktrees` |

**Default behavior:** for any non-trivial task, check whether a `superpowers:` skill applies before proceeding. Bias toward using them.

### `ui-ux-pro-max` — for all UI/UX/design work

Invoke `ui-ux-pro-max` whenever the task involves:
- Building a new view or screen
- Designing a component (cards, sheets, lists, buttons)
- Reviewing or improving existing UI
- Color, typography, spacing, or layout decisions
- Accessibility (contrast, touch targets, Dynamic Type, VoiceOver)
- SwiftUI animation and interaction polish

The skill knows SwiftUI patterns and Apple HIG. **Do not hand-roll design decisions when this skill is available.**

---

## Project conventions (the short list)

Full rules live in `CONTRIBUTING.md`. The non-negotiables:

1. **Every change starts with a GitHub issue.** No issue, no branch.
2. **Branch names encode type + slug:** `feat/`, `fix/`, `chore/`, `refactor/` — e.g. `fix/exercise-picker-blank-popup`.
3. **`main` is protected.** All work lands via PR. Never push directly.
4. **PR titles use Conventional Commits style** (`fix(plan-builder): …`, `feat(workout): …`).
5. **Issue/PR labels use prefixed scheme:** `type:`, `priority:`, `area:`, `status:`. See `.github/labels.json`.
6. **Squash-merge PRs.** One logical change = one commit on main.
7. **Visual/UI changes:** the user (Garrett) tests in the simulator — Claude cannot. Report what was changed and what to verify; never claim a UI feature works without human confirmation.

---

## Architectural guardrails

- **Template side vs. session side are separate.** `Routine`/`RoutineExercise`/`RoutineSet` are the plan template. `WorkoutSession`/`SessionExercise`/`SessionSet` are the log. Session edits **must not** mutate template models. When in doubt, add a session-only override field on the session model.
- **SwiftData migrations:** prefer additive, optional fields. Avoid renames of existing fields without an explicit migration plan.
- **No third-party dependencies.** SwiftUI + SwiftData + Foundation only.
- **HIG compliance is a feature requirement,** not a polish item. Use `ui-ux-pro-max` to validate.

---

## Repo orientation

- `LiftOS/` — app source (Models, Views, Services)
- `AdaptOS.xcodeproj/` — Xcode project (target name: `AdaptOS`, product name: `LiftOS`)
- `.github/` — issue templates, PR template, CI, label scheme
- `docs/` — `PROJECT_PLAN.md`, `BRANCHING.md`, `WORKFLOW_SETUP.md`, `INBOX_SYSTEM.md`
- `LiftOS/Inbox.md` — quick triage notes before promotion to issues

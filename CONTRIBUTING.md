# Contributing to LiftOS

This is the single source of truth for how work flows through this repo.
If you're ever unsure, check here first.

> **Status:** Solo project (Garrett). Written as if onboarding a teammate, because
> future-you *is* a teammate, and because this is what real engineering teams do.

---

## TL;DR — The 90-second version

1. Every change starts with a **GitHub Issue**. No issue, no work.
2. Every issue gets a **branch** whose name encodes type and slug: `feat/live-activity-timer`.
3. Every branch lands on `main` through a **Pull Request** that links the issue.
4. `main` is always shippable. A green PR can become a build at any time.
5. If production is broken, a **hotfix branch** jumps the queue: `fix/hotfix-crash-on-launch`.

---

## Branching model: GitHub Flow (with hotfixes)

We use GitHub Flow, not Git Flow. One long-lived branch (`main`) and many short-lived
feature/fix branches. Git Flow's `develop` branch adds complexity we don't need as a solo dev.

```
main ─────●─────●─────●─────●─────●──────> (always shippable)
           \       \     \       \
            feat    fix   chore   feat/hotfix
```

### Branch naming

Format: `<type>/<short-kebab-slug>`

| Prefix  | When to use                                          | Example                              |
| ------- | ---------------------------------------------------- | ------------------------------------ |
| `feat/` | New user-facing feature                              | `feat/calendar-heatmap`              |
| `fix/`  | Bug fix (non-urgent)                                 | `fix/rest-timer-resumes-on-resume`   |
| `hotfix/` | Urgent fix going to a released build               | `hotfix/crash-on-workout-start`      |
| `chore/`| Tooling, deps, refactors with no user-facing effect  | `chore/theme-color-consolidation`    |
| `docs/` | Documentation only                                   | `docs/add-branching-diagram`         |
| `test/` | Adding or fixing tests                               | `test/progression-engine-coverage`   |

**Rules:**
- Always branch from **up-to-date** `main` (`git pull --rebase origin main` first).
- Keep branches short-lived — aim to merge within a few days.
- One concern per branch. If scope creeps, open a new issue + branch.

---

## Commit messages: Conventional Commits

Format: `<type>(<scope>): <subject>`

| Type       | Meaning                                      |
| ---------- | -------------------------------------------- |
| `feat`     | New feature                                  |
| `fix`      | Bug fix                                      |
| `chore`    | Tooling / housekeeping                       |
| `refactor` | Code change that neither adds nor fixes      |
| `docs`     | Documentation only                           |
| `test`     | Adding or fixing tests                       |
| `perf`     | Performance improvement                      |
| `style`    | Formatting, whitespace (no code change)      |

Scope is optional but encouraged. Examples:

```
feat(history): add calendar heatmap for workout streaks
fix(timer): prevent rest timer skipping when app backgrounds
chore(deps): bump swift tools version to 6.3
refactor(theme): consolidate hardcoded colors into LiftTheme
```

**Why this matters:** Conventional Commits make the git history greppable, enable
auto-generated changelogs later, and are the de-facto standard at most
modern engineering teams. Great muscle memory to build now.

---

## The workflow, step-by-step

### 1. Pick (or open) an issue

- Look at the Project board → `This Week` column.
- If the work isn't captured, open a new issue using the correct template.
- Assign yourself and move it to **In Progress**.

### 2. Create a branch

```bash
git checkout main
git pull --rebase origin main
git checkout -b feat/calendar-heatmap
```

### 3. Commit in small, logical chunks

```bash
git add <files>
git commit -m "feat(history): scaffold CalendarHeatmapView"
```

Commit more often than feels necessary. Each commit should leave the app in
a working state when possible.

### 4. Push and open a PR

```bash
git push -u origin feat/calendar-heatmap
gh pr create --fill --assignee @me
```

Fill out the PR template. **Always link the issue** with `Closes #NN` —
this auto-closes the issue when the PR merges.

### 5. Wait for CI

Every PR runs `xcodebuild` against the project. Red = fix before merging.

### 6. Merge

Use **Squash and merge** for feature branches so `main` stays clean:
one issue → one commit on `main`.

```bash
gh pr merge --squash --delete-branch
```

### 7. Deploy

For this project, "deploy" = cut a TestFlight build from `main`.
Tag releases: `git tag v0.9.0 && git push --tags`.

---

## Hotfix workflow

When a released version is broken:

1. Branch from the **tag** of the broken release (not `main` — `main` may be ahead).
   ```bash
   git checkout -b hotfix/crash-on-workout-start v0.9.0
   ```
2. Fix, commit, push.
3. Open a PR **into `main`**, labeled `priority:P0-now`.
4. After merge, cut a patch release: `v0.9.1`.
5. The fix will naturally flow into the next feature release via `main`.

---

## Issue types & priority

| Label         | Meaning                                                              |
| ------------- | -------------------------------------------------------------------- |
| `type:bug`    | Something is broken or behaves wrong                                 |
| `type:feature`| New user-facing capability                                           |
| `type:enhancement` | Improvement to something that already exists                    |
| `type:tech-debt`   | Code quality / refactor with no user-visible change             |
| `type:chore`  | Tooling, deps, CI, docs                                              |
| `priority:P0-now`  | Drop everything. Prod is broken or data is at risk              |
| `priority:P1-soon` | Important, next up                                              |
| `priority:P2-later`| Planned but not urgent                                          |
| `priority:P3-someday` | Nice to have. Could sit in the backlog forever               |

Area labels (`area:workout-logging`, `area:plan-builder`, etc.) help you
filter the backlog by part of the app.

---

## What "Done" means

A ticket is **Done** when:

- [ ] Code is merged to `main`
- [ ] CI is green on `main`
- [ ] Manual test (the relevant Phase 6 testing step from `PROJECT_PLAN.md`) passes
- [ ] The issue is closed (auto-closed via `Closes #NN` in the PR)
- [ ] If user-visible: it works on a physical device, not just Simulator

---

## Questions this doc answers so you don't have to remember

- **"What should I name this branch?"** → See the Branch Naming table above.
- **"How do I write this commit message?"** → Conventional Commits section.
- **"It's 11pm and the app crashes on launch — what do I do?"** → Hotfix workflow.
- **"How does a bug I found become a fix?"** → Open an issue → branch → PR → merge.

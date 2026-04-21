# Branching strategy (visual)

Short reference card. For the full playbook, see [`/CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## The normal flow — GitHub Flow

```
                                              squash & merge
main ──────●─────────●─────────────●──────────────●────────────●──>
            \                       \              \
             \                       \              \
              └─feat/calendar-heatmap ┘              └─fix/rest-timer-background
                 │   │   │                              │   │
                 │   │   └── commit N                   │   └── commit 2
                 │   └────── commit 2                   └────── commit 1
                 └────────── commit 1
```

**Rules of the road:**

- `main` is **always** shippable. Never commit directly.
- Branch from `main`. Merge back via Pull Request.
- Squash-merge feature branches so `main` reads as one commit per issue.
- Delete the branch immediately after merge (`gh pr merge --squash --delete-branch`).

---

## The hotfix flow

When a **released build** is broken, you don't want to ship whatever half-done feature
is sitting on `main`. You want to ship just the fix.

```
                                                      cherry-free
main ──●─(v0.9.0 tag)─●─────●─────●───────────────●──merge──────●──>
        \                                          \            ^
         \                                          \           │
          └── hotfix/crash-on-workout-start ────────┘           │
                                                                │
tag v0.9.0 ──┐                                                  │
              └── hotfix branches from here ─────────────────> PR into main
                                                                +
                                                                tag v0.9.1, build release
```

**Steps:**

1. `git checkout -b hotfix/<slug> v0.9.0`  *(branch from the broken release's tag)*
2. Fix, commit, push.
3. Open PR into `main` with label `priority:P0-now`.
4. After merge, tag the patch: `git tag v0.9.1 && git push --tags`.
5. Cut a new TestFlight build from that tag.

Because `main` already has the new features in flight, you don't want to release `main` yet
— you release the tag. The fix flows into the next feature release naturally through `main`.

---

## Decision tree: which branch prefix?

```
Is this breaking something users have already seen (released build)?
├── YES ──> hotfix/<slug>   (branch from the release tag)
└── NO
    │
    Is this a new user-facing capability?
    ├── YES ──> feat/<slug>
    └── NO
        │
        Is this fixing incorrect behavior (non-urgent)?
        ├── YES ──> fix/<slug>
        └── NO
            │
            Is this docs-only?
            ├── YES ──> docs/<slug>
            │
            Is this tests-only?
            ├── YES ──> test/<slug>
            │
            Otherwise ───> chore/<slug>
```

---

## Why GitHub Flow over Git Flow?

Git Flow adds a long-lived `develop` branch plus `release/*` and `hotfix/*` branches.
It made sense when shipping was a big scheduled event with a QA team.

As a solo dev shipping to TestFlight whenever something is ready, Git Flow's
extra branches are just bookkeeping with no payoff. GitHub Flow is what most
modern SaaS teams actually use. If you add teammates later, this scales fine
with branch protection rules and required reviews.

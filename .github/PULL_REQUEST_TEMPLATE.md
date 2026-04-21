<!--
Thanks for the PR! Fill this out so future-you (and any reviewers) can
understand the change in 60 seconds.
-->

## What

<!-- One or two sentences: what does this PR do? -->

## Why

<!-- Link the issue. If there isn't one, open one first. -->

Closes #

## How

<!-- Brief overview of the approach. Highlight any tricky bits, trade-offs, or
     things reviewers should look at carefully. -->

## Screenshots / screen recordings

<!-- For any user-facing change, drop a before/after image or a short screen
     recording. SwiftUI changes without a screenshot will be sent back. -->

## Testing

<!-- What did you do to verify this works? Check all that apply. -->

- [ ] Built and ran on **physical device** (required for anything touching haptics, timers, notifications)
- [ ] Built and ran in Simulator
- [ ] Walked through the relevant manual test from `docs/PROJECT_PLAN.md`
- [ ] Added / updated unit tests where it made sense
- [ ] Tested in **Dark Mode**
- [ ] Tested with **Dynamic Type** at XL (accessibility)

## Risk

<!-- What could go wrong? Any migrations, data model changes, or anything
     that could affect existing user data? -->

- [ ] Touches data model / SwiftData schema
- [ ] Touches `ProgressionEngine` or other core logic
- [ ] Touches something used inside an active workout (high blast radius)
- [ ] Pure UI / polish (low risk)

## Checklist

- [ ] Branch name follows convention (`feat/`, `fix/`, `hotfix/`, `chore/`, `docs/`, `test/`)
- [ ] Commits follow [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] `xcodebuild` passes locally
- [ ] No `print`/`dump` debug statements left in
- [ ] No hardcoded colors or spacing (use `LiftTheme`)

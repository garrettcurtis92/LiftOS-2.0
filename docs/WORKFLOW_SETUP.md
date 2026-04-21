# Workflow setup runbook

Run these once, from your Mac's Terminal, inside the repo root (`LiftOS-2.0`).
This turns the files in `.github/` into a live, working GitHub workflow.

**Prereqs:**

- `gh` installed (`brew install gh`) and authenticated (`gh auth login`)
- `jq` installed (`brew install jq`) — used to loop over `labels.json`
- You're on `main` with a clean working tree

> **Tip:** Run each block and watch the output. If something errors, stop and
> read the message before continuing.

---

## Step 1 — Commit and push the `.github/` files

Before `gh` can talk to anything, the templates need to exist on GitHub:

```bash
git status
git add CONTRIBUTING.md .github/ docs/BRANCHING.md docs/WORKFLOW_SETUP.md
git commit -m "chore(repo): establish engineering workflow (templates, labels, CI)"
git push origin main
```

Refresh the repo on github.com — you should see the new **Issues** template picker
when you click "New issue".

---

## Step 2 — Apply labels from `.github/labels.json`

This creates every label in `labels.json`. If a label already exists with the
same name, it updates the color and description.

```bash
# From repo root
jq -c '.[]' .github/labels.json | while read -r row; do
  name=$(echo "$row"    | jq -r '.name')
  color=$(echo "$row"   | jq -r '.color')
  desc=$(echo "$row"    | jq -r '.description')

  if gh label list --limit 200 | grep -q "^${name}\b"; then
    gh label edit "$name" --color "$color" --description "$desc"
    echo "updated: $name"
  else
    gh label create "$name" --color "$color" --description "$desc"
    echo "created: $name"
  fi
done
```

Verify:

```bash
gh label list --limit 200
```

You should see ~28 labels across `type:*`, `priority:*`, `area:*`, `status:*`.

**Optional cleanup:** GitHub creates default labels (`bug`, `enhancement`,
`documentation`, etc.) when the repo is made. You can delete them since we're
using our own prefixed scheme:

```bash
for old in bug documentation duplicate enhancement "good first issue" "help wanted" invalid question wontfix; do
  gh label delete "$old" --yes 2>/dev/null || true
done
```

---

## Step 3 — Create the Project board

GitHub Projects is the Kanban board where you'll drag tickets through columns.

```bash
# Create the project (user-scoped — change --owner if using an org)
gh project create \
  --owner garrettcurtis92 \
  --title "LiftOS Roadmap"
```

Copy the project number it prints (e.g. `#3`). You'll need it below.

Then link it to the repo:

```bash
# Replace 3 with your project number
PROJECT_NUMBER=3
```

Open the project in the browser to customize columns:

```bash
gh project view $PROJECT_NUMBER --owner garrettcurtis92 --web
```

In the UI:

1. Add a **Status** field (if not already there) with these values:
   - `Backlog`
   - `This Week`
   - `In Progress`
   - `In Review`
   - `Done`
2. Switch the view to **Board** layout, grouped by Status.
3. Save.

> You can do this from the CLI too, but the UI is faster for a one-time setup.

---

## Step 4 — Enable branch protection on `main`

This is what makes `main` "always shippable" — GitHub blocks direct pushes and
requires PRs + green CI.

```bash
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  /repos/garrettcurtis92/LiftOS-2.0/branches/main/protection \
  -f "required_status_checks[strict]=true" \
  -f "required_status_checks[contexts][]=Build (iOS Simulator)" \
  -F "enforce_admins=false" \
  -F "required_pull_request_reviews[required_approving_review_count]=0" \
  -F "required_pull_request_reviews[dismiss_stale_reviews]=true" \
  -F "restrictions=null" \
  -F "allow_force_pushes=false" \
  -F "allow_deletions=false"
```

> `enforce_admins=false` and `required_approving_review_count=0` are intentional
> for solo dev — you can still merge your own PRs. Flip both to `true` when
> you add teammates.

---

## Step 5 — Seed the initial backlog

These `gh issue create` commands populate your Project board with real work
drawn from `docs/PROJECT_PLAN.md`. Run them in order — the whole block takes
~60 seconds.

> **Note:** `gh issue create` does not yet support adding to a Project directly
> from the CLI in one step. After creating issues, bulk-add them to the Project
> via the UI (takes 30 seconds) or use `gh project item-add`.

### Phase 7: Polish the Gaps

```bash
gh issue create \
  --title "[Feature]: Onboarding flow for first launch" \
  --label "type:feature,priority:P1-soon,area:onboarding" \
  --body "$(cat <<'EOF'
## Problem
A first-time user lands on an empty Home tab with no guidance. Drop-off risk before
they understand the core workflow (create plan → start workout).

## Proposed solution
A 3-screen onboarding shown on first launch:
1. Welcome + value prop (double progression, local-only privacy)
2. Offer "Create your first plan" → opens Plan Builder OR "Try a quick workout"
3. Optional Sign in with Apple

Dismiss forever after any action.

## Acceptance criteria
- [ ] \`OnboardingView.swift\` created, shown on first launch only
- [ ] State persisted via \`AppStorage\`
- [ ] Skip button available on every screen
- [ ] Works in Dark Mode and at largest Dynamic Type size
- [ ] Does not re-appear after dismissal, even on app relaunch
EOF
)"

gh issue create \
  --title "[Feature]: Calendar heatmap on History tab" \
  --label "type:feature,priority:P1-soon,area:history" \
  --body "$(cat <<'EOF'
## Problem
History tab is a flat list. Users can't see their consistency at a glance.

## Proposed solution
GitHub-style calendar heatmap showing workout intensity per day over the last
12 weeks. Originally planned as \`CalendarHeatmapView\` in PROJECT_PLAN but never built.

Intensity = total volume (sets × reps × weight) normalized to the user's weekly max.

## Acceptance criteria
- [ ] \`CalendarHeatmapView.swift\` in \`LiftOS/Views/History/\`
- [ ] Shows last 12 weeks, 7 days tall
- [ ] Color scale: empty / light / medium / bold (match Apple Fitness activity rings vibe)
- [ ] Tapping a cell opens that day's session detail
- [ ] Performance: smooth scroll with 2+ years of data
EOF
)"

gh issue create \
  --title "[Feature]: Progress Dashboard (weekly volume, streak, tonnage)" \
  --label "type:feature,priority:P1-soon,area:progress" \
  --body "$(cat <<'EOF'
## Problem
No single view answers "am I making progress?" right now. Individual exercise
charts exist but no rollup.

## Proposed solution
New \`ProgressDashboardView\` tab (or section inside History) with:
- Weekly volume chart (bar)
- Muscle group balance (last 4 weeks)
- Current streak
- Total tonnage over time

Uses Swift Charts, no third-party deps.

## Acceptance criteria
- [ ] New view reachable from History tab
- [ ] All charts respect user's weight unit (lbs/kg)
- [ ] Handles <1 week of data gracefully (no crashes, empty state)
EOF
)"

gh issue create \
  --title "[Feature]: Rest timer local notification when app backgrounded" \
  --label "type:feature,priority:P1-soon,area:rest-timer" \
  --body "$(cat <<'EOF'
## Problem
If you leave the app during rest (to change a song, check a text), you miss
the timer hitting zero and either over-rest or rush back.

## Proposed solution
Schedule a \`UNUserNotification\` when the timer starts. Fire at zero.
Cancel if the timer completes while app is foregrounded.

## Acceptance criteria
- [ ] Permission requested on first rest timer start (not on app launch)
- [ ] Notification body shows exercise name + "Set X of Y"
- [ ] Notification is canceled if user returns to app before zero
- [ ] Settings toggle in Profile tab to disable the notification
- [ ] No sound if device is on silent / focus mode
EOF
)"

gh issue create \
  --title "[Feature]: Rest timer Live Activity + Dynamic Island" \
  --label "type:feature,priority:P2-later,area:rest-timer" \
  --body "$(cat <<'EOF'
## Problem
Even with local notifications, the timer is invisible without opening the app.

## Proposed solution
ActivityKit Live Activity that shows the rest timer on lock screen and
Dynamic Island. Updates in real time without needing the app open.

## Acceptance criteria
- [ ] Live Activity appears when rest timer starts
- [ ] Lock screen view shows countdown + exercise name
- [ ] Dynamic Island compact + expanded layouts
- [ ] Ends when timer hits zero OR user returns to app and completes next set
- [ ] Gracefully no-ops on devices without Dynamic Island
EOF
)"

gh issue create \
  --title "[Enhancement]: Empty state polish on History tab" \
  --label "type:enhancement,priority:P3-someday,area:history,good first task" \
  --body "$(cat <<'EOF'
## Problem
History empty state is generic. Doesn't help the user figure out what to do next.

## Proposed solution
Change the message based on whether an active plan exists:
- No plan: "Create a plan to start tracking your workouts"
- Plan exists, no workouts: "Tap Start Workout on the Today tab to log your first session"

## Acceptance criteria
- [ ] Conditional text in HistoryTab empty state
- [ ] Primary CTA button navigates to the right tab
EOF
)"

gh issue create \
  --title "[Enhancement]: Loading skeleton on ExerciseProgressView" \
  --label "type:enhancement,priority:P3-someday,area:progress,good first task" \
  --body "$(cat <<'EOF'
## Problem
\`loadHistory()\` flashes an empty chart briefly on open.

## Proposed solution
Use \`.redacted(reason: .placeholder)\` on the chart and stats rows while loading.

## Acceptance criteria
- [ ] Skeleton appears for the duration of the fetch
- [ ] Smooth fade to real data on load
EOF
)"
```

### Phase 8: App Store Readiness

```bash
gh issue create \
  --title "[Tech debt]: Replace dev-time auto-wipe with versioned schema migrations" \
  --label "type:tech-debt,priority:P0-now,area:data-model" \
  --body "$(cat <<'EOF'
## Current state
\`ModelContainer+LiftOS.swift\` auto-wipes the store on incompatible schema changes.
Safe during dev, but **ships to users = data loss**.

## Why is this a problem?
Once the app is in TestFlight with real users (including you, daily), any schema
change without migrations nukes workout history. This blocks App Store release.

## Proposed refactor
- Convert current schema to \`VersionedSchema\` (e.g. \`LiftOSSchemaV1\`)
- Create \`MigrationPlan\` with stages
- Remove the auto-wipe branch
- Add a SwiftData migration test

## Risk
HIGH — touches persistence. Blast radius = all stored data.
Must be tested with a real populated store before shipping.
EOF
)"

gh issue create \
  --title "[Feature]: App icon + launch screen" \
  --label "type:feature,priority:P1-soon,area:tooling" \
  --body "$(cat <<'EOF'
## Problem
Placeholder icon and no launch screen — blocks TestFlight submission.

## Proposed solution
- Design icon at 1024×1024, export all App Store sizes via Icon Composer
- SwiftUI launch screen with logo on system background

## Acceptance criteria
- [ ] All required icon sizes in Assets.xcassets
- [ ] Launch screen renders correctly in light + dark mode
- [ ] No Apple HIG violations (no text on icon, no transparency)
EOF
)"

gh issue create \
  --title "[Tech debt]: Unit tests for ProgressionEngine and SessionBuilder" \
  --label "type:tech-debt,priority:P1-soon,area:workout-logging" \
  --body "$(cat <<'EOF'
## Current state
Core logic (\`ProgressionEngine\`, \`SessionBuilder\`) has no unit tests. All behavior
is verified manually through the app.

## Why is this a problem?
- Regressions in progression suggestions would silently break training plans
- Refactors are risky without a safety net
- CI has nothing to run

## Proposed refactor
XCTest targets covering:
- Double progression: under range, in range, at max, deload
- SessionBuilder: copies template data correctly, doesn't mutate source
- Edge cases: empty rep range, missing previous session

## Risk
Low — adding tests only.
EOF
)"

gh issue create \
  --title "[Chore]: Privacy manifest (PrivacyInfo.xcprivacy)" \
  --label "type:chore,priority:P1-soon,area:tooling" \
  --body "$(cat <<'EOF'
## What needs to be done
Add \`PrivacyInfo.xcprivacy\` declaring:
- SwiftData usage (NSPrivacyAccessedAPICategoryUserDefaults, etc.)
- No tracking
- No third-party SDKs

## Why now?
Required for App Store submission as of 2024.

## Definition of done
- [ ] PrivacyInfo.xcprivacy added to Xcode project
- [ ] \`xcodebuild\` includes it in the built app bundle
- [ ] Validated via \`diagnose\` in App Store Connect on first upload
EOF
)"
```

---

## Step 6 — Add seeded issues to the Project board

```bash
# Open the Project in your browser and bulk-add open issues:
gh project view $PROJECT_NUMBER --owner garrettcurtis92 --web
```

In the UI: click **+ Add items** → filter by `is:issue is:open repo:garrettcurtis92/LiftOS-2.0` → select all → Add.

Then drag the P1 issues into `This Week`, leave P2/P3 in `Backlog`.

---

## Step 7 — Smoke test

```bash
# Confirm everything is wired:
gh issue list --limit 20
gh label list --limit 30
gh workflow list
```

You should see:
- ~10 open issues
- ~28 labels
- 1 workflow (`CI`)

---

## Done. What the daily workflow looks like now

From this moment on, your loop is:

```
1. Pick an issue from "This Week" column → move to "In Progress"
2. git checkout -b feat/<slug>
3. Code, commit with Conventional Commits
4. git push -u origin feat/<slug>
5. gh pr create --fill
6. Wait for green CI
7. gh pr merge --squash --delete-branch
8. Issue auto-closes via "Closes #NN" in PR body → moves to "Done" column
```

Repeat.

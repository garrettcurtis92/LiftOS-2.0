#!/usr/bin/env bash
# ============================================================
# File 5 GitHub issues from the /impeccable audit of
# LiftOS/Views/Workout/ActiveWorkoutView.swift
#
# Run from the repo root:
#   chmod +x docs/file-audit-issues.sh
#   ./docs/file-audit-issues.sh
#
# Prereqs: gh authenticated  (`gh auth status`)
#          repo:             garrettcurtis92/LiftOS-2.0
# ============================================================

set -euo pipefail
REPO="garrettcurtis92/LiftOS-2.0"

echo "==> Syncing new labels to GitHub..."
for label in \
  'type:fix|e4e669|Targeted code fix — behavior correction that isn'"'"'t a full bug report' \
  'area:accessibility|1d76db|VoiceOver, Dynamic Type, Reduce Motion, tap targets, WCAG compliance'
do
  IFS='|' read -r name color desc <<< "$label"
  if gh label list --repo "$REPO" --limit 200 | grep -q "^${name}"; then
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc"
    echo "  updated: $name"
  else
    gh label create "$name" --repo "$REPO" --color "$color" --description "$desc"
    echo "  created: $name"
  fi
done

echo ""
echo "==> Filing Issue 1 — a11y hardening (P0)..."
ISSUE1=$(gh issue create \
  --repo "$REPO" \
  --title "fix(workout): a11y hardening for ActiveWorkoutView" \
  --label "type:fix,priority:P0-now,area:workout-logging,area:accessibility" \
  --body "$(cat <<'EOF'
## Problem

The `/impeccable` audit of `LiftOS/Views/Workout/ActiveWorkoutView.swift` found multiple accessibility blockers, including one P0 that prevents VoiceOver users from completing the basic workout-logging flow. `PRODUCT.md` commits to **WCAG 2.1 AA minimum across the app** with VoiceOver-complete and 44pt-minimum tap targets as firm requirements; the file currently violates both.

## Acceptance Criteria

- [ ] Manual swipe-to-delete (`DragGesture`, lines 597–617) replaced with system `.swipeActions(edge: .trailing)` so VoiceOver rotor exposes the delete action automatically.
- [ ] Set-completion button (lines 582–593) has `.accessibilityLabel("Set N")`, `.accessibilityValue` reflecting completion state, `.accessibilityHint` describing the toggle.
- [ ] Weight + Reps `TextField`s (lines 549–579) have `.accessibilityLabel` referencing the unit from `UserProfile.weightUnit`.
- [ ] Set-number warmup-toggle (lines 531–540) has `.accessibilityLabel` / `.accessibilityValue` / `.accessibilityHint` describing the warmup toggle.
- [ ] Auto-rest timer toggle (lines 184–193) has `.accessibilityLabel("Auto rest timer")` and `.accessibilityValue("On"/"Off")`.
- [ ] Ellipsis Menu trigger (lines 427–432) has `.accessibilityLabel("Exercise options")`.
- [ ] Decorative column-header checkmark glyph (lines 450–452) marked `.accessibilityHidden(true)`.
- [ ] RIR close button (lines 642–649) has `.accessibilityLabel("Close RIR selector")`.
- [ ] Set row exposes `.accessibilityActions` with rotor entries: Mark complete / Toggle warmup / Delete set.
- [ ] Tap targets ≥44pt on set-number toggle, completion checkmark, and RIR chips (visible glyphs unchanged).
- [ ] Every animation in the file gates on `@Environment(\.accessibilityReduceMotion)` and degrades to `.easeOut(0.15)` or no animation. Covers checkmark spring, row flash, RIR transition, expand/collapse, delete-set, swipe-offset (if retained).
- [ ] Manual VoiceOver pass on a physical device: every set row is fully operable without sighted help.
- [ ] Manual Reduce Motion pass: enable Settings → Accessibility → Motion → Reduce Motion, verify no spring/scale animations play.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift` (run on this branch).
- `PRODUCT.md` § Accessibility & Inclusion (firm requirements: Dynamic Type, VoiceOver, Reduce Motion, Bold Text + Increase Contrast).
- `DESIGN.md` § 6 Do's and Don'ts (Reduce Motion respected; 44pt tap targets in active workout flow).

EOF
)")
echo "  Created: $ISSUE1"

echo ""
echo "==> Filing Issue 2 — previousSets fetch storm (P0)..."
ISSUE2=$(gh issue create \
  --repo "$REPO" \
  --title "perf(workout): eliminate previousSets fetch storm in ActiveWorkoutView" \
  --label "type:fix,priority:P0-now,area:workout-logging" \
  --body "$(cat <<'EOF'
## Problem

`previousSets(for:)` (line 249) runs a `FetchDescriptor<SessionExercise>` query for every exercise on screen, on every body re-render of `ActiveWorkoutView`. The parent re-renders once per second because `elapsedSeconds` is `@State` updated on a 1 Hz `Timer`. Net result: ~N SwiftData fetches per second during an active workout. On a database with months of history this becomes visible jank, directly violating `PRODUCT.md`'s **"Speed of logging is sacred"** principle.

The animation-chain code in `toggleCompletion` (lines 693, 701) also uses `DispatchQueue.main.asyncAfter`, which won't cancel cleanly on rapid re-toggle and can stack during fast logging.

## Acceptance Criteria

- [ ] Elapsed-time display extracted into a child `TimerLabel` view that owns its own `@State` for the tick, so the timer no longer invalidates `ActiveWorkoutView.body`.
- [ ] `previousSets` results cached in parent `@State` keyed by exercise ID; populated `.task` on appear and invalidated when the exercise list changes (add / remove / swap / reorder). No fetch in the body render path.
- [ ] `DispatchQueue.main.asyncAfter` chains in `toggleCompletion` replaced with `.task(id:)` or equivalent structured-concurrency pattern that cancels cleanly on view churn or rapid re-toggle.
- [ ] Manual test: rapid-tap five set checkmarks in two seconds, verify no animation queue lag and no visible frame drops.
- [ ] Manual test: open Instruments → Time Profiler during an active workout with ≥10 historical sessions, confirm `FetchDescriptor` is not in the hot path of the timer-driven re-render.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `PRODUCT.md` § Design Principles #2 (Speed of logging is sacred).

EOF
)")
echo "  Created: $ISSUE2"

echo ""
echo "==> Filing Issue 3 — Dynamic Type AX1+ layout (P1)..."
ISSUE3=$(gh issue create \
  --repo "$REPO" \
  --title "fix(workout): adapt ActiveWorkoutView set row for Dynamic Type AX1+" \
  --label "type:fix,priority:P1-soon,area:workout-logging,area:accessibility" \
  --body "$(cat <<'EOF'
## Problem

The set row uses fixed-width frames (lines 537, 553, 572, 591) and matching column-header widths (lines 443–451). At Dynamic Type AX1+ the input text clips; at AX3+ the row overflows on iPhone SE. `PRODUCT.md` commits to Dynamic Type at all sizes (xSmall through AX5) with explicit guidance to "switch to vertical layouts at AX1+ where needed" — currently no `dynamicTypeSize` check exists.

## Acceptance Criteria

- [ ] Read `@Environment(\.dynamicTypeSize)` in `SetLogRow`.
- [ ] At default sizes (≤ `.xxxLarge`), keep the existing compact tabular `HStack` layout (it's correct there).
- [ ] At `.accessibility1` and above, switch to a vertical (`VStack`-of-rows) layout that wraps the inputs cleanly.
- [ ] Column-header row (`setHeader`) hidden or restructured at AX1+ so it doesn't compete with the new vertical row layout.
- [ ] Simulator test: Dynamic Type slider at xSmall, Large (default), xxxLarge, AX1, AX3, AX5 — no clipped text, no horizontal overflow on iPhone SE width.
- [ ] VoiceOver pass at AX5 confirming row reading order remains logical.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `PRODUCT.md` § Accessibility & Inclusion ("Layouts in `ActiveWorkoutView`, `SetLogRow`, history lists, and plan-builder sheets must hold up at the largest accessibility sizes").

EOF
)")
echo "  Created: $ISSUE3"

echo ""
echo "==> Filing Issue 4 — LiftTheme token routing (P2)..."
ISSUE4=$(gh issue create \
  --repo "$REPO" \
  --title "chore(workout): route ActiveWorkoutView through LiftTheme tokens" \
  --label "type:chore,priority:P2-later,area:workout-logging,area:ui-polish" \
  --body "$(cat <<'EOF'
## Problem

`LiftTheme` exists (`LiftOS/Utilities/Theme.swift`) and is partially adopted across the app, but `ActiveWorkoutView.swift` reaches around it for several values. The visual result is identical today; the risk is that future re-skinning, accent overrides, or token tuning will skip these direct usages.

## Acceptance Criteria

- [ ] `Color.green` (lines 587, 596) → `LiftTheme.success`.
- [ ] `Color.orange` for warmup context (line 536) → `LiftTheme.warmup`.
- [ ] `Color.accentColor` (lines 399, 634) → `LiftTheme.accent`.
- [ ] `Color.secondarySystemBackground` (lines 555, 574, 634) → `LiftTheme.cardBackground`.
- [ ] `RoundedRectangle(cornerRadius: 6)` (lines 523, 556, 575, 636) → `RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius)`.
- [ ] Padding literals: `4` → `LiftTheme.listItemSpacing`, `8` → `LiftTheme.compactSpacing`, `16` → `LiftTheme.cardSpacing` where literal matches token. Leave genuinely off-grid values alone.
- [ ] Visual regression: side-by-side simulator comparison shows zero pixel difference vs. `main`.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `LiftOS/Utilities/Theme.swift`.
- `DESIGN.md` § 2 Colors (Semantic-Only Rule).

EOF
)")
echo "  Created: $ISSUE4"

echo ""
echo "==> Filing Issue 5 — DESIGN.md ultraThinMaterial reconciliation (P2)..."
ISSUE5=$(gh issue create \
  --repo "$REPO" \
  --title "docs(design): reconcile DESIGN.md ultraThinMaterial usage with code" \
  --label "type:chore,priority:P2-later,area:ui-polish,discussion" \
  --body "$(cat <<'EOF'
## Problem

`DESIGN.md` § 4 Elevation ("The Sheet-Material Rule") describes `.ultraThinMaterial` as "the lone application of frosted material in the app," referring to the auto-rest toggle bar. In practice, `ActiveWorkoutView`'s `workoutHeader` (line 197) also uses `.ultraThinMaterial` as floating chrome over scrolling content — same functional justification, but a second instance not acknowledged in the spec.

**A decision is required before this issue is started.**

## Acceptance Criteria

Pick **(a)** or **(b)**:

- [ ] **(a)** Update `DESIGN.md` § 4 Elevation to list both documented uses of `.ultraThinMaterial` (workout header chrome AND auto-rest toggle bar) as the spec'd exceptions, with a brief test defining what qualifies as "functional chrome over scrolling content."
- [ ] **(b)** Remove `.ultraThinMaterial` from the workout header (revert to `Color(.systemBackground)` or no background, letting the system nav bar handle chrome) so the spec's "lone application" claim stays accurate.

Decision lives with Garrett before work begins.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `DESIGN.md` § 4 Elevation.

EOF
)")
echo "  Created: $ISSUE5"

echo ""
echo "============================================================"
echo "All 5 issues filed:"
echo "  Issue 1 (P0 — a11y):          $ISSUE1"
echo "  Issue 2 (P0 — perf):          $ISSUE2"
echo "  Issue 3 (P1 — Dynamic Type):  $ISSUE3"
echo "  Issue 4 (P2 — LiftTheme):     $ISSUE4"
echo "  Issue 5 (P2 — DESIGN.md):     $ISSUE5"
echo ""
echo "Next step: add all 5 to the LiftOS Roadmap project board."
echo "  gh project view 3 --owner garrettcurtis92 --web"
echo "============================================================"

#!/usr/bin/env bash
# File issues 3-5 from the /impeccable audit.
# Uses temp files for issue bodies to avoid heredoc quoting issues.
set -euo pipefail
REPO="garrettcurtis92/LiftOS-2.0"
TMPDIR_CUSTOM=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR_CUSTOM"; }
trap cleanup EXIT

# ── Issue 3 ──────────────────────────────────────────────────────────────────
echo "==> Filing Issue 3 — Dynamic Type AX1+ layout (P1)..."
cat > "$TMPDIR_CUSTOM/issue3.md" << 'BODY'
## Problem

The set row uses fixed-width frames (lines 537, 553, 572, 591) and matching column-header widths (lines 443-451). At Dynamic Type AX1+ the input text clips; at AX3+ the row overflows on iPhone SE. `PRODUCT.md` commits to Dynamic Type at all sizes (xSmall through AX5) with explicit guidance to "switch to vertical layouts at AX1+ where needed" — currently no `dynamicTypeSize` check exists.

## Acceptance Criteria

- [ ] Read `@Environment(\.dynamicTypeSize)` in `SetLogRow`.
- [ ] At default sizes (.xxxLarge and below), keep the existing compact tabular HStack layout — it is correct there.
- [ ] At `.accessibility1` and above, switch to a vertical VStack layout that wraps the inputs cleanly.
- [ ] Column-header row (`setHeader`) hidden or restructured at AX1+ so it does not compete with the new vertical row layout.
- [ ] Simulator test: Dynamic Type slider at xSmall, Large (default), xxxLarge, AX1, AX3, AX5 — no clipped text, no horizontal overflow on iPhone SE width.
- [ ] VoiceOver pass at AX5 confirming row reading order remains logical.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `PRODUCT.md` Accessibility & Inclusion: "Layouts in `ActiveWorkoutView`, `SetLogRow`, history lists, and plan-builder sheets must hold up at the largest accessibility sizes."
BODY

ISSUE3=$(gh issue create \
  --repo "$REPO" \
  --title "fix(workout): adapt ActiveWorkoutView set row for Dynamic Type AX1+" \
  --label "type:fix,priority:P1-soon,area:workout-logging,area:accessibility" \
  --body-file "$TMPDIR_CUSTOM/issue3.md")
echo "  Created: $ISSUE3"

# ── Issue 4 ──────────────────────────────────────────────────────────────────
echo ""
echo "==> Filing Issue 4 — LiftTheme token routing (P2)..."
cat > "$TMPDIR_CUSTOM/issue4.md" << 'BODY'
## Problem

`LiftTheme` exists (`LiftOS/Utilities/Theme.swift`) and is partially adopted across the app, but `ActiveWorkoutView.swift` reaches around it for several raw values. The visual result is identical today; the risk is that future re-skinning, accent overrides, or token tuning will skip these direct usages.

## Acceptance Criteria

- [ ] `Color.green` (lines 587, 596) replaced with `LiftTheme.success`.
- [ ] `Color.orange` for warmup context (line 536) replaced with `LiftTheme.warmup`.
- [ ] `Color.accentColor` (lines 399, 634) replaced with `LiftTheme.accent`.
- [ ] `Color.secondarySystemBackground` (lines 555, 574, 634) replaced with `LiftTheme.cardBackground`.
- [ ] `RoundedRectangle(cornerRadius: 6)` (lines 523, 556, 575, 636) replaced with `RoundedRectangle(cornerRadius: LiftTheme.inputCornerRadius)`.
- [ ] Padding literals: `4` to `LiftTheme.listItemSpacing`, `8` to `LiftTheme.compactSpacing`, `16` to `LiftTheme.cardSpacing` where the literal matches the token. Leave genuinely off-grid values alone.
- [ ] Visual regression: side-by-side simulator comparison shows zero pixel difference vs. `main`.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `LiftOS/Utilities/Theme.swift`.
- `DESIGN.md` Section 2 Colors (Semantic-Only Rule).
BODY

ISSUE4=$(gh issue create \
  --repo "$REPO" \
  --title "chore(workout): route ActiveWorkoutView through LiftTheme tokens" \
  --label "type:chore,priority:P2-later,area:workout-logging,area:ui-polish" \
  --body-file "$TMPDIR_CUSTOM/issue4.md")
echo "  Created: $ISSUE4"

# ── Issue 5 ──────────────────────────────────────────────────────────────────
echo ""
echo "==> Filing Issue 5 — DESIGN.md ultraThinMaterial reconciliation (P2)..."
cat > "$TMPDIR_CUSTOM/issue5.md" << 'BODY'
## Problem

`DESIGN.md` Section 4 Elevation ("The Sheet-Material Rule") describes `.ultraThinMaterial` as "the lone application of frosted material in the app," referring to the auto-rest toggle bar. In practice, `ActiveWorkoutView`s `workoutHeader` (line 197) also uses `.ultraThinMaterial` as floating chrome over scrolling content — same functional justification, but a second instance not acknowledged in the spec.

A decision is required before this issue is started.

## Acceptance Criteria

Pick **(a)** or **(b)**:

- [ ] **(a)** Update `DESIGN.md` Section 4 Elevation to list both documented uses of `.ultraThinMaterial` (workout header chrome AND auto-rest toggle bar) as the spec exceptions, with a brief rule defining what qualifies as "functional chrome over scrolling content."
- [ ] **(b)** Remove `.ultraThinMaterial` from the workout header (revert to `Color(.systemBackground)` or no background, letting the system nav bar handle chrome) so the spec's "lone application" claim stays accurate.

Decision lives with Garrett before work begins.

## References

- `/impeccable` audit report on `ActiveWorkoutView.swift`.
- `DESIGN.md` Section 4 Elevation.
BODY

ISSUE5=$(gh issue create \
  --repo "$REPO" \
  --title "docs(design): reconcile DESIGN.md ultraThinMaterial usage with code" \
  --label "type:chore,priority:P2-later,area:ui-polish,discussion" \
  --body-file "$TMPDIR_CUSTOM/issue5.md")
echo "  Created: $ISSUE5"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "Issues 3-5 filed:"
echo "  Issue 3 (P1 — Dynamic Type):  $ISSUE3"
echo "  Issue 4 (P2 — LiftTheme):     $ISSUE4"
echo "  Issue 5 (P2 — DESIGN.md):     $ISSUE5"
echo ""
echo "Full set:"
echo "  Issue 1 (P0 — a11y):   https://github.com/garrettcurtis92/LiftOS-2.0/issues/12"
echo "  Issue 2 (P0 — perf):   https://github.com/garrettcurtis92/LiftOS-2.0/issues/13"
echo "  Issue 3 (P1):          $ISSUE3"
echo "  Issue 4 (P2):          $ISSUE4"
echo "  Issue 5 (P2):          $ISSUE5"
echo "============================================================"

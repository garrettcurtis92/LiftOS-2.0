# LiftOS 2.0 -- Native iOS Workout Tracker

## Context

Building a greenfield native iOS workout tracking app that lets users create multi-week training plans (with deload weeks), organize daily routines, and log every set/rep/weight session-by-session. The killer feature is **double progression** -- showing previous session data inline so users know exactly what to beat. The app must look and feel like Apple built it (strict HIG compliance). Data is local-only via SwiftData to avoid backend costs. Inspired by Hevy, RP Hypertrophy, and MacroFactor Workouts.

**Environment:** Xcode 26.4, Swift 6.3, iOS 17+ target, SwiftUI only, zero third-party dependencies.

**Installed skill:** `swiftui-expert` (AvdLee) -- covers state management, Liquid Glass, performance, view composition patterns.

---

## Data Model Schema

```
WorkoutPlan ──┐
              ├──> [PlanWeek] ──> [Routine] ──> [RoutineExercise] ──> [RoutineSet]
              │                                        │
              │                                        ▼
              │                                    Exercise (shared library, ~150 seeded)
              │                                        ▲
              │                                        │
WorkoutSession ──> [SessionExercise] ──> [SessionSet]
```

**Key design:** Template side (Plan/Week/Routine) and logging side (Session) are intentionally separate. `SessionBuilder` copies template data at workout start so plan edits never corrupt historical records.

### Models (all `@Model` classes)

| Model | Key Fields | Notes |
|-------|-----------|-------|
| `Exercise` | name, muscleGroup (enum), equipmentType (enum), isCustom | Shared across templates and sessions |
| `WorkoutPlan` | name, numberOfWeeks, deloadFrequency, deloadPercentage, isActive | Only one active plan at a time |
| `PlanWeek` | weekNumber, isDeloadWeek | Cascade from plan |
| `Routine` | name, dayOfWeek, sortOrder | A single day's template |
| `RoutineExercise` | sortOrder, restSeconds | Links Routine to Exercise |
| `RoutineSet` | setNumber, targetReps, targetRepRangeMax, targetWeight | The prescription |
| `WorkoutSession` | startedAt, completedAt, isQuickWorkout | Actual logged workout |
| `SessionExercise` | sortOrder, notes | What was actually performed |
| `SessionSet` | setNumber, reps, weight, rpe, isWarmup, isDropSet, completedAt | The logged data |
| `UserProfile` | appleUserID, displayName, weightUnit (lbs/kg) | Local identity |

### Enums (raw String, Codable)
- `MuscleGroup`: chest, back, shoulders, quads, hamstrings, glutes, arms, core, fullBody
- `EquipmentType`: barbell, dumbbell, cable, machine, smithMachine, bodyweight, band, other
- `WeightUnit`: lbs, kg

---

## Navigation Architecture

### Tab Bar (4 tabs)
| Tab | SF Symbol | Label | Purpose |
|-----|-----------|-------|---------|
| 1 | `figure.run` | Today | Today's routine, quick start |
| 2 | `list.bullet.clipboard` | Plans | Browse/manage workout plans |
| 3 | `clock.arrow.circlepath` | History | Past sessions, calendar heatmap |
| 4 | `person.crop.circle` | Profile | Settings, Sign in with Apple |

### Key Flows
- **Start Workout:** HomeTab -> tap "Start Workout" -> `ActiveWorkoutView` (`.fullScreenCover` to prevent accidental nav-away) -> Complete -> Review -> Dismiss
- **Quick Workout:** HomeTab -> "Quick Workout" -> `ActiveWorkoutView` with no plan reference
- **Build Plan:** PlansTab -> New/Edit Plan -> Weeks -> Routines -> Exercises -> Sets
- **View Progress:** HistoryTab -> Calendar + Session List -> Session Detail -> Exercise Chart

---

## Double Progression Engine (`ProgressionEngine.swift`)

```
For each working set, given target rep range (e.g., 8-12) and previous session:
1. prev reps < range min  -> suggest SAME weight, aim for range min
2. prev reps >= min AND < max -> suggest SAME weight, aim for prev reps + 1
3. prev reps >= range max -> suggest weight + increment, reset to range min
   Increments: 5 lbs barbell, 5 lbs dumbbell, 2.5 lbs isolation/cable
```

Deload override: multiply suggested weight by `plan.deloadPercentage`, cap reps at range min.

Previous session data displayed inline as gray text: "Last: 135 x 8" next to input fields.

---

## HIG Compliance Strategy

- **Typography:** System semantic styles only (`.largeTitle`, `.headline`, `.body`, etc.), `.monospacedDigit()` for weight/reps alignment, never hardcode font sizes
- **Colors:** `.primary`/`.secondary`/`.tertiary` for text, system backgrounds for surfaces, system blue accent, no hardcoded colors
- **SF Symbols:** `dumbbell.fill`, `figure.strengthtraining.traditional`, `checkmark.circle.fill`, `timer`, `arrow.up.right` (progression)
- **Interactions:** Swipe actions on rows, context menus, `.confirmationDialog` for destructive actions, `.sensoryFeedback` on set completion
- **Layout:** `List`/`Form` for data entry, `GroupBox` for cards, `LazyVStack` for custom scrolling, no hardcoded spacing under 8pt
- **Accessibility:** All icons labeled, min 44pt tap targets, Dynamic Type support, Bold Text support

### SwiftUI Best Practices (from swiftui-expert skill)
- `@Observable` + `@MainActor` for view models (not `ObservableObject`)
- `@State` (private) with `@Observable`, `@Bindable` for injected observables needing bindings
- Extract complex views to separate structs (not `@ViewBuilder` functions)
- Value-based `NavigationStack` navigation
- `#available(iOS 26, *)` checks with fallbacks for Liquid Glass (future polish)

---

## File Structure

```
LiftOS/
  LiftOSApp.swift
  Models/
    Exercise.swift, WorkoutPlan.swift, PlanWeek.swift, Routine.swift,
    RoutineExercise.swift, RoutineSet.swift, WorkoutSession.swift,
    SessionExercise.swift, SessionSet.swift, UserProfile.swift
  ViewModels/
    PlanBuilderViewModel.swift, ActiveWorkoutViewModel.swift,
    HistoryViewModel.swift, ProgressionViewModel.swift, ExerciseLibraryViewModel.swift
  Views/
    Tabs/ (HomeTab, PlansTab, HistoryTab, ProfileTab)
    PlanBuilder/ (PlanDetailView, WeekDetailView, RoutineEditorView, ExercisePickerView)
    ActiveWorkout/ (ActiveWorkoutView, SetRowView, RestTimerView, PreviousSessionBanner)
    History/ (SessionListView, SessionDetailView, CalendarHeatmapView)
    Progress/ (ExerciseProgressView, ProgressDashboardView)
    Components/ (ExerciseRowView, MuscleGroupBadge, RPESlider, EmptyStateView, ProgressionSuggestionBanner)
    Auth/ (SignInView, OnboardingView)
  Services/
    ProgressionEngine.swift, SeedDataService.swift, SessionBuilder.swift
  Utilities/
    DateFormatter+Extensions.swift, View+Extensions.swift, Color+LiftOS.swift, ModelContainer+LiftOS.swift
  Resources/
    ExerciseLibrary.json (~150 seeded exercises)
  Preview Content/
    PreviewSampleData.swift
```

---

## Completed Phases

- **Phase 1: Foundation** — Models, tabs, seed data (93 exercises), SwiftData config
- **Phase 2: Plan Builder** — Plan creation, week management, routine editor, exercise picker with config sheet
- **Phase 3: Active Workout** — Live session logging, rest timer, workout summary, mid-workout swap/remove
- **Phase 4: History & Progress** — Workout detail view, PREV column, exercise progress charts with Swift Charts, PRs
- **Phase 5: Smart Features** — ProgressionEngine wired in, week tracking, RIR input (0–5 scale), warmup toggle, workout notes, profile rest timer fallback
- **Plan Sync** — Week 1 as template, auto-replicate routines, "All weeks" vs "This week only" prompts
- **Exercise Config** — Sets/reps/rep range/weight configured when adding exercise to routine
- **Phase 6: UX Polish** — Haptics across the app, set completion micro-interaction (bounce + flash + RIR slide-in), rest timer polish (entrance animation, last-5s urgency, completion flash), theme system, entrance animations on summary and home, sheet polish (drag indicators, detents, rounded corners), empty state animation
- **Mid-Workout Controls** — Swipe-to-delete sets, toggle auto-rest-timer from header
- **Dev Tooling** — ModelContainer auto-recovers from incompatible schema changes during development

---

## Phase 6: UX Polish

### Context
The app is functionally complete but has minimal visual polish — no haptics, limited animations, ad-hoc colors, and no micro-interactions. This phase transforms LiftOS from "works great" to "feels great." Ordered by impact on daily workout usage.

---

### 6A: Haptic Feedback (Highest Impact, Lowest Effort)

Zero haptics → well-placed haptics transforms the feel overnight. Uses iOS 17's `.sensoryFeedback` modifier — one line per interaction, no UIKit.

**Files:** All view files (one-line additions each)

| Interaction | Haptic | File |
|---|---|---|
| Set completion checkmark | `.success` on complete | `ActiveWorkoutView.swift` (SetLogRow) |
| Set un-check | `.impact(.light)` | `ActiveWorkoutView.swift` (SetLogRow) |
| RPE button tap | `.selection` | `ActiveWorkoutView.swift` (RPE selector) |
| Warmup toggle | `.selection` | `ActiveWorkoutView.swift` (set number tap) |
| Rest timer hits zero | `.notification(.warning)` | `RestTimerView.swift` |
| Rest timer ±15s | `.impact(.light)` | `RestTimerView.swift` |
| Exercise card expand/collapse | `.impact(.soft)` | `ActiveWorkoutView.swift` |
| Finish Workout | `.notification(.success)` | `ActiveWorkoutView.swift` |
| Start Workout / Quick Workout | `.impact(.medium)` | `HomeTab.swift` |
| Week advancement | `.impact(.light)` | `HomeTab.swift` |
| Add Set / Add Exercise | `.impact(.light)` | `ActiveWorkoutView.swift` |

---

### 6B: Set Completion Micro-Interaction (Most-Tapped Element)

The checkmark is tapped 50+ times per workout. Currently just swaps icons with no feedback.

**File:** `ActiveWorkoutView.swift` (SetLogRow)

1. **Scale bounce** on checkmark icon — shrink to 0.5, spring back to 1.0 (response: 0.3, damping: 0.5)
2. **Color fade** — animate green color in rather than snapping
3. **Row flash** — brief green tint (0.08 opacity) on completion, fades after 0.6s
4. **RPE slide-in** — add `.transition(.move(edge: .bottom).combined(with: .opacity))` so RPE bar animates in smoothly

---

### 6C: Rest Timer Polish

**Files:** `RestTimerView.swift`, `ActiveWorkoutView.swift`

1. **Entrance animation** — overlay fades in with slight scale (0.95 → 1.0) instead of popping
2. **Last 5 seconds** — time text scales up slightly (1.05x), circle stroke shifts to orange
3. **Completion pulse** — circle flashes green, brief delay before auto-dismiss
4. **Progress ring glow** — subtle `.shadow` on the accent-colored arc

---

### 6D: Theme System (Visual Consistency)

**New file:** `LiftOS/Utilities/Theme.swift`

Define semantic colors, corner radii, and spacing constants:
- `LiftTheme.primary`, `.success`, `.warning`, `.warmup`, `.deload`
- `LiftTheme.cardBackground`, `.elevatedBackground`
- `LiftTheme.cornerRadius` (12), `.smallCornerRadius` (8)
- `LiftTheme.cardSpacing` (16), `.sectionSpacing` (20)

**Refactor pass:** Replace all inline `Color.secondarySystemBackground`, `Color.accentColor`, scattered corner radii, and inconsistent spacing with theme constants. Move `MuscleGroup.accentColor` from `ExerciseLibraryView.swift` into Theme or Exercise model.

**Files touched:** All 14 view files + new Theme.swift

---

### 6E: Entrance Animations

**WorkoutSummaryView.swift** (the "reward" screen):
- Trophy icon: scale-up bounce on appear (0 → 1.0 with spring)
- Stats grid: staggered fade-in (0.2s, 0.3s, 0.4s delays)
- Exercise breakdown: fade + slide up after stats

**HomeTab.swift:**
- "Start Workout" button: subtle breathing pulse (scale 1.0 ↔ 1.02, repeating)
- Active session card: slide in from top

**ActiveWorkoutView.swift:**
- Set rows cascade in with slight stagger when expanding an exercise card

---

### 6F: Sheet & Navigation Polish

Add consistent sheet styling across all `.sheet` presentations:

| Sheet | Detent |
|---|---|
| `NewRoutineSheet` | `.medium` |
| `NewExerciseSheet` | `.medium` |
| `EditPlanSheet` | `.medium, .large` |
| `ExercisePickerView` | `.large` + `.presentationDragIndicator(.visible)` |
| `WorkoutSummaryView` | `.large` (already dismiss-disabled) |

Add `.presentationDragIndicator(.visible)` and `.presentationCornerRadius(20)` to all sheets.

---

### 6G: Empty State Improvements

- Add fade + scale entrance animation to all empty states
- `HomeTab` "No Active Plan": change icon to `figure.strengthtraining.traditional`, add subtle opacity pulse
- `ExerciseProgressView`: add `.redacted(reason: .placeholder)` loading skeleton during `loadHistory()` fetch
- `HistoryTab`: contextual nudge text based on whether an active plan exists

---

## Implementation Status

| Step | What | Status |
|---|---|---|
| 6A | Haptics | ✅ Complete |
| 6B | Set completion micro-interaction | ✅ Complete |
| 6C | Rest timer polish | ✅ Complete |
| 6D | Theme system | ✅ Complete (Theme.swift created) |
| 6E | Entrance animations | ✅ Complete (WorkoutSummaryView, HomeTab) |
| 6F | Sheet polish | ✅ Complete (all sheets) |
| 6G | Empty states | ✅ Complete (HomeTab) |
| -- | ModelContainer auto-recovery | ✅ Added (dev-time schema reset) |

---

## Phase 6 Testing Walkthrough

**⚠️ Haptics require a physical device — the Simulator does not produce haptic feedback.**

### Test 1: Full Workout Flow (covers 6A, 6B, 6C, 6F)

1. Open the app → **Home tab**
2. Tap **"Start Workout"** (or Quick Workout if no plan) → feel **medium impact** haptic, confirmation dialog appears
3. Confirm → ActiveWorkoutView opens
4. Tap an **exercise card header** to expand/collapse → feel **soft impact** haptic, smooth animation
5. Enter a weight in Set 1 → tap out of the field → verify remaining sets **auto-fill** that weight
6. Enter reps → tap the **checkmark** to complete a set:
   - ✅ Checkmark should **bounce** (shrink then spring back)
   - ✅ Row should briefly **flash green**
   - ✅ **RPE selector** should slide in from below
   - ✅ Feel **success** haptic
7. Tap an RPE value → feel **selection** haptic, RPE bar dismisses
8. **Un-check** the set → feel **soft impact** haptic, RPE disappears
9. Tap the **set number** (e.g., "1") to toggle **warmup** → number changes to "W" in orange, feel **selection** haptic
10. Tap **"Add Set"** → feel **light impact** haptic
11. Tap **"Add Exercise"** → feel **light impact** haptic, picker sheet slides up with **drag indicator** and rounded corners
12. Complete a set to trigger the **rest timer**:
    - ✅ Timer overlay should **fade in** (not pop)
    - ✅ Tap **±15s buttons** → feel **solid impact** haptic
    - ✅ Wait for **last 5 seconds** → time text should **scale up slightly**, progress ring turns **orange**
    - ✅ At 0:00 → ring flashes **green**, feel **warning** haptic, brief pause then auto-dismiss
13. Tap **"Finish Workout"** → feel **success** haptic, confirmation dialog appears
14. Confirm → **WorkoutSummaryView** appears:
    - ✅ Trophy should **bounce in** with spring animation
    - ✅ Stats grid should **fade up** after a short delay
    - ✅ Exercise breakdown should **fade up** after stats

### Test 2: Plan Builder Sheets (covers 6F)

1. Go to **Plans tab** → create a new plan → sheet has **drag indicator** + rounded corners
2. Open a plan → add a routine → **NewRoutineSheet** appears at **medium** detent
3. Open a routine → add an exercise → **ExercisePickerView** at **large** detent with drag indicator
4. After picking → **ExerciseConfigSheet** appears with drag indicator
5. Edit plan → **EditPlanSheet** at **medium/large** detent with drag indicator

### Test 3: Week Navigation (covers 6A)

1. On Home tab with an active plan → tap **"Next Week"** → feel **solid impact** haptic
2. On final week → tap **"Restart"** → feel same haptic

### Test 4: Empty State (covers 6G)

1. Delete all plans (or fresh install) → Home tab shows **"No Active Plan"** with `figure.strengthtraining.traditional` icon
2. The empty state should **fade + scale in** smoothly on appear

### Test 5: Dark Mode

1. Switch device to **Dark Mode** in Settings
2. Run through Tests 1-4 again — verify all animations and colors look correct

### Test 6: Rapid Set Logging (Performance)

1. Start a workout → **rapidly** complete 5-6 sets in a row by tapping checkmarks quickly
2. Verify: animations don't stack up, lag, or block input — speed is critical during a real workout

---

## Upcoming Phases

The app is fully functional through Phase 6. Everything below is **optional** and grouped by intent.

---

### Phase 7: Polish the Gaps (~1–2 days)

The missing pieces a real user would notice. Mostly filling holes from the original plan plus small quality-of-life upgrades.

- **Onboarding flow** — first-launch walkthrough: create your first plan or jump into a quick workout
- **Calendar heatmap on HistoryTab** — GitHub-style activity grid (originally planned as `CalendarHeatmapView`, never built)
- **Progress Dashboard** — weekly volume chart, muscle group balance, workout streak, total tonnage over time
- **Rest timer local notifications** — when the app is backgrounded mid-rest, fire a local notification at zero so the user doesn't miss it
- **Rest timer completion sound** — optional chime (with a mute toggle in Profile)
- **HistoryTab contextual empty state** — nudge text changes based on whether an active plan exists
- **ExerciseProgressView loading skeleton** — `.redacted(reason: .placeholder)` while `loadHistory()` fetches

**Files:** New `CalendarHeatmapView.swift`, `ProgressDashboardView.swift`, `OnboardingView.swift`. Modifications to `HistoryTab`, `RestTimerView`, `ActiveWorkoutView`, `ProfileTab`.

---

### Phase 8: App Store Readiness (~1–2 days)

Everything required to ship to TestFlight / the App Store.

- **App Icon** — design and export all required sizes
- **Launch screen** — SwiftUI launch screen with logo
- **Versioned schema migrations** — replace the dev-time auto-wipe in `ModelContainer+LiftOS.swift` with a proper `VersionedSchema` + `MigrationPlan` chain so updates don't destroy user data
- **Privacy manifest** — `PrivacyInfo.xcprivacy` declaring SwiftData usage, no tracking, no third-party SDKs
- **App Store metadata** — description, keywords, screenshots, preview video, support URL, privacy policy
- **TestFlight setup** — App Store Connect configuration, build signing, beta testers
- **Unit tests** — at minimum: `ProgressionEngine`, `SessionBuilder`, `PlanSyncService`
- **Crash reporting** — Apple's built-in crash reports (or MetricKit) — no third-party dependencies
- **Accessibility audit** — VoiceOver pass, Dynamic Type at all sizes, Bold Text, Reduce Motion

---

### Phase 9: Power Features (scope varies per feature)

The "what makes people pay" tier. Each is independent — pick based on what you'd use most.

#### High impact for gym use
- **Apple Watch companion** — log sets from the wrist, haptic rest timer, glanceable "next set" screen. Huge win since you don't want your phone out mid-set.
- **Rest timer Live Activity / Dynamic Island** — timer visible on lock screen and Dynamic Island without opening the app
- **Home Screen widget** — today's routine, last workout, current streak

#### Workout quality
- **Supersets / circuits** — group exercises together with shared rest logic and paired logging
- **Plate calculator** — visualize which plates to load for the current weight on a barbell
- **Exercise demo images/videos** — tap an exercise to see form cues; could use Apple's SF Symbols + custom exercise illustrations
- **Drop sets & AMRAP logic** — first-class support beyond the current `isDropSet` field
- **Exercise notes per-session** — in addition to workout-level notes

#### Data & sync
- **iCloud sync (CloudKit)** — SwiftData + CloudKit integration so data follows the user across devices
- **Export** — JSON/CSV backup, share sheet support
- **Import from Hevy / MacroFactor** — parse their export format

#### Body tracking
- **Body measurements** — weight, waist, biceps over time with charts
- **Progress photos** — side-by-side comparison view

#### Social / motivation
- **PR notifications** — toast when you hit a new 1RM / volume PR mid-workout
- **Share a workout** — generate an image of a completed session to share
- **Weekly summary notification** — Sunday recap of the week's training

---

### Phase 10: AI Assistant & Social Features (long-term)

These features need careful design and iteration. No rush — build them right.

#### AI Training Assistant
- **Chat-based plan builder** — conversational interface that generates full workout plans based on goals, available equipment, days per week, and experience level. Powered by Claude API.
- **Smart exercise substitution** — mid-workout "equipment taken?" button suggests alternatives with the same muscle group and a different equipment type, with reasoning for why
- **AI-powered deload & volume recommendations** — intelligent suggestions based on training history and fatigue signals

#### Social / Coaching
- **Plan & routine sharing** — share a full plan or single routine with another user via iOS Share Sheet, link, or QR code
- **Import shared plans** — recipient taps a shared file or link and LiftOS imports the plan with all weeks, routines, exercises, and sets intact
- **Coach-to-client workflow** — a coach builds a plan and sends it to a client's LiftOS install

---

## Recommended Next Steps

**If shipping to TestFlight soon:** Phase 7 + Phase 8. ~1 week of focused work.

**If using personally before release:** Skip ahead to the power features that matter most for your training. Top picks for solo use:
1. Apple Watch companion (massive workflow improvement)
2. Rest timer Live Activity / notifications (never miss the beep)
3. Progress Dashboard (motivation via visible progress)

**If building a polished product for a broader audience:** Phase 7 → Phase 9 selectively → Phase 8. Don't ship without onboarding or the Progress Dashboard — they're what make first impressions work.

# Reorder exercises during an active workout — design spec

**Issue:** [#2](https://github.com/garrettcurtis92/LiftOS-2.0/issues/2)
**Date:** 2026-05-02
**Status:** Approved
**Branch (planned):** `feat/reorder-active-workout-exercises`

## Goal

Allow the user to reorder exercises in an in-progress workout without losing logged data, persisting the new order across app backgrounding and resumes.

## Non-goals

- Reordering sets within an exercise (out of scope; existing per-set add/delete already covers it)
- Drag-to-reorder routines on the template side (separate feature)
- Renaming/swapping exercise during reorder (existing menu still handles swap)

## User experience

- The user taps **Edit** (top-right of the navigation toolbar) during a workout. The list enters edit mode: each `ExerciseLogCard` collapses, drag handles appear on the trailing edge, and the **Add Exercise** button hides (it stays out of edit mode and reappears when Done is tapped).
- The user drags an exercise by its handle to a new position. SwiftUI's native `List` reorder animation runs. A soft haptic fires on pickup; a success haptic fires on drop.
- The user taps **Done** to exit edit mode. The list returns to its normal interactive state with the new ordering preserved.
- If the user backgrounds the app mid-workout and returns, the reordered sequence persists (SwiftData writes through `sortOrder` immediately on `.onMove`).
- The rest timer overlay is independent of the list and continues running undisturbed.

## Architecture

### Models — no schema changes

`SessionExercise.sortOrder: Int` already exists. The implementation reindexes the field on every move. No migration is required.

### View changes — `ActiveWorkoutView`

Replace:

```swift
ScrollView {
    LazyVStack(spacing: 16) {
        ForEach(session.sortedExercises) { ... ExerciseLogCard ... }
        addExerciseButton
    }
    .padding()
}
```

With:

```swift
List {
    Section {
        ForEach(session.sortedExercises) { ... ExerciseLogCard ... }
            .onMove(perform: moveExercises)
    }
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

    if !isEditMode {
        Section {
            addExerciseButton
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
    }
}
.listStyle(.plain)
.scrollContentBackground(.hidden)
.environment(\.editMode, $editMode)
```

`isEditMode` is derived from `editMode?.wrappedValue.isEditing` so we conditionally hide the Add Exercise button (so users can't drop an exercise below it).

### Reorder action

```swift
private func moveExercises(from source: IndexSet, to destination: Int) {
    var reordered = session.sortedExercises
    reordered.move(fromOffsets: source, toOffset: destination)
    for (index, exercise) in reordered.enumerated() {
        exercise.sortOrder = index
    }
    reorderTrigger.toggle()  // drives sensoryFeedback(.success)
}
```

A `@State private var reorderTrigger = false` paired with `.sensoryFeedback(.success, trigger: reorderTrigger)` provides the drop haptic. Pickup haptic is automatic on iOS 17+ via `List`.

### Edit mode

- Add `@State private var editMode: EditMode = .inactive` and `.environment(\.editMode, $editMode)` on the `List`.
- Place `EditButton()` in the navigation toolbar's `.navigationBarTrailing` slot.
- On transition to `.active`, call `expandedExerciseID = nil` inside `.onChange(of: editMode?.wrappedValue)` to collapse all cards.

### Set-row swipe gesture — risk and fallback

`SetLogRow` uses a custom `DragGesture(minimumDistance: 20)` for swipe-to-delete. `List` rows can intercept horizontal drags during edit mode and may also interfere when not in edit mode. Two outcomes are possible:

1. **Custom gesture still works** in `.plain` `List` outside edit mode. Keep it. Verify in simulator.
2. **Custom gesture conflicts.** Migrate `SetLogRow` to native `.swipeActions(edge: .trailing) { Button(role: .destructive, action: onDelete) {...} }`. This is the more iOS-native solution anyway and removes ~30 lines of manual gesture state.

Decision will be made during implementation based on simulator behavior. Spec authorizes either path.

## Data flow

```
User drags row
  → List calls onMove(IndexSet, Int)
  → moveExercises updates sortOrder on each SessionExercise
  → SwiftData autosaves (modelContext is live)
  → session.sortedExercises returns new order on next read
  → reorderTrigger toggles → success haptic
```

## Edge cases

- **Reordering completed exercises:** allowed. No data is touched on the sets — only `sortOrder` changes. Acceptance criterion explicitly covers this.
- **Reordering during rest timer:** rest timer is in an `.overlay`, independent of the list. Unaffected.
- **Single exercise:** `.onMove` is a no-op; List won't show drag handles for one item. No special-casing needed.
- **Mid-drag app backgrounding:** SwiftData writes happen at `onMove` completion, not mid-drag. Backgrounding mid-drag cancels the gesture; no partial state.
- **Add Exercise visibility flicker:** removing the button from the list when entering edit mode causes a section to disappear. This is acceptable UX (matches Reminders/Notes behavior) and avoids letting users drop an exercise below the action button.

## Testing strategy

- **Manual (Garrett, simulator):** the seven acceptance criteria from the issue.
- **Unit (if feasible):** a `moveExercises` helper extracted as a free function or static method on `SessionExercise` so it can be tested without UI. Verifies that given a starting order and a move op, `sortOrder` is reindexed correctly.
- **Build:** `xcodebuild -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16'` must succeed warning-free.

## Acceptance criteria (from issue)

- [ ] Long-press drag handle enters reorder mode (native List behavior, surfaced via EditButton)
- [ ] Haptic feedback on pickup and drop
- [ ] Completed exercises can be reordered (no data loss)
- [ ] `sortOrder` persists if you background the app and return
- [ ] Rest timer is not interrupted by reorder
- [ ] Swipe-to-delete on set rows still works after List refactor (or replaced by `.swipeActions`)
- [ ] Visual appearance matches current card layout (no visible regression)

## Out-of-scope follow-ups

- If implementing `.swipeActions`, file a small refactor follow-up to remove dead drag-state in `SetLogRow`.
- Consider adding a "Reset to template order" button in a future iteration (not part of this spec).

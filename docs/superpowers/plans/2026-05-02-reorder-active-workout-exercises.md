# Reorder active-workout exercises — implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user reorder exercises mid-workout via SwiftUI's native `List` + `.onMove()`, persisting `sortOrder` on `SessionExercise`, with `EditButton` toolbar control and matching the existing card visuals.

**Architecture:** Refactor `ActiveWorkoutView` from `ScrollView`/`LazyVStack` to `List` with hidden separators, clear row backgrounds, and tuned insets so `ExerciseLogCard` (`GroupBox`) renders identically. The reorder math is extracted to a pure static helper on `SessionExercise` so it's unit-testable without UI. `EditButton()` in `.navigationBarTrailing` drives `EditMode`; the Add Exercise row hides while editing; expanded cards auto-collapse on entering edit mode. `SetLogRow`'s custom `DragGesture` is verified in a `List` context first; if it conflicts, it migrates to native `.swipeActions`.

**Tech Stack:** SwiftUI, SwiftData, Swift Testing (`@Test` / `#expect`), iOS 17+, Xcode 26.4. Zero third-party deps.

**Spec:** `docs/superpowers/specs/2026-05-02-reorder-exercises-design.md`
**Issue:** [#2](https://github.com/garrettcurtis92/LiftOS-2.0/issues/2)
**Branch:** `feat/reorder-active-workout-exercises` (already created)

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `LiftOS/Models/SessionExercise.swift` | Modify | Add static `reorder(_:from:to:)` pure helper that takes `[SessionExercise]`, applies a move, and reindexes `sortOrder` |
| `LiftOS/Views/Workout/ActiveWorkoutView.swift` | Modify | Replace `ScrollView`+`LazyVStack` with `List`, add `editMode` state, wire `EditButton`, hide Add Exercise during edit, collapse cards on edit-mode entry, call `reorder` helper from `.onMove` |
| `LiftOSTests/LiftOSTests.swift` | Modify | Add `@Suite("SessionExercise.reorder")` with three pure tests for the helper |
| (Conditional) `LiftOS/Views/Workout/ActiveWorkoutView.swift` `SetLogRow` | Modify | If swipe gesture conflicts with `List`, replace custom `DragGesture` with `.swipeActions` |

---

## Task 1: Add a pure, testable reorder helper on SessionExercise

**Why this task exists:** The `.onMove` callback receives `(IndexSet, Int)` and needs to translate that into `sortOrder` reindexing. Doing this math in the View makes it untestable. A pure static helper on `SessionExercise` lets us TDD the logic before touching SwiftUI.

**Files:**
- Modify: `LiftOS/Models/SessionExercise.swift`
- Test: `LiftOSTests/LiftOSTests.swift`

- [ ] **Step 1: Write the failing tests**

Append to `LiftOSTests/LiftOSTests.swift` (after the last `@Suite`, before the EOF):

```swift
// MARK: - SessionExercise.reorder Tests

@Suite("SessionExercise.reorder")
struct SessionExerciseReorderTests {

    private func makeExercises(count: Int) -> [SessionExercise] {
        (0..<count).map { SessionExercise(sortOrder: $0) }
    }

    @Test("Move single item from index 2 to index 0 reindexes sortOrder")
    func moveUp() {
        let items = makeExercises(count: 4)
        SessionExercise.reorder(items, from: IndexSet(integer: 2), to: 0)

        // After moving index 2 to position 0: [old2, old0, old1, old3]
        #expect(items[2].sortOrder == 1)  // was at index 2, now at position 1
        #expect(items[0].sortOrder == 2)  // was at index 0, now at position 2
        #expect(items[1].sortOrder == 3)  // was at index 1, now at position 3
        #expect(items[3].sortOrder == 0)  // wait — re-check semantics below
    }

    @Test("Move from index 0 to index 3 reindexes sortOrder")
    func moveDown() {
        let items = makeExercises(count: 4)
        SessionExercise.reorder(items, from: IndexSet(integer: 0), to: 3)

        // .onMove(toOffset: 3) on a 4-item list moving item 0 → expected order:
        // [old1, old2, old0, old3]
        #expect(items[0].sortOrder == 2)
        #expect(items[1].sortOrder == 0)
        #expect(items[2].sortOrder == 1)
        #expect(items[3].sortOrder == 3)
    }

    @Test("Move with empty IndexSet is a no-op")
    func moveEmpty() {
        let items = makeExercises(count: 3)
        SessionExercise.reorder(items, from: IndexSet(), to: 0)
        #expect(items[0].sortOrder == 0)
        #expect(items[1].sortOrder == 1)
        #expect(items[2].sortOrder == 2)
    }
}
```

> **Note on test semantics:** `Array.move(fromOffsets:toOffset:)` matches SwiftUI's `.onMove` contract. The first test's expected sortOrders need to be derived from that exact behavior — Step 4 will reconcile any mismatch.

- [ ] **Step 2: Run tests to verify they fail with "no such method"**

Run:

```bash
xcodebuild test -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LiftOSTests/SessionExerciseReorderTests 2>&1 | tail -40
```

Expected: build failure with error like `type 'SessionExercise' has no member 'reorder'`.

- [ ] **Step 3: Implement the helper**

In `LiftOS/Models/SessionExercise.swift`, add a static method to the `SessionExercise` class (before the closing `}`):

```swift
    /// Applies a SwiftUI `.onMove` operation to a list of session exercises and reindexes `sortOrder`
    /// to match the new positions. The input array is treated as an ordered sequence; each item's
    /// `sortOrder` is set to its new index after the move.
    ///
    /// - Parameters:
    ///   - exercises: The current ordered list (e.g., `session.sortedExercises`).
    ///   - source: The `IndexSet` from `.onMove(perform:)`.
    ///   - destination: The destination offset from `.onMove(perform:)`.
    static func reorder(_ exercises: [SessionExercise], from source: IndexSet, to destination: Int) {
        guard !source.isEmpty else { return }
        var reordered = exercises
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in reordered.enumerated() {
            exercise.sortOrder = index
        }
    }
```

- [ ] **Step 4: Reconcile test 1 expectations and run all three tests**

Before running, derive the expected sortOrders for `moveUp` from `Array.move(fromOffsets: IndexSet(integer: 2), toOffset: 0)`:
- Starting array (by id): `[A, B, C, D]` with sortOrders `[0,1,2,3]`
- After `move(fromOffsets: [2], toOffset: 0)`: `[C, A, B, D]`
- Reindexed: A→1, B→2, C→0, D→3

Update the `moveUp` test assertions to match (replace the four `#expect` lines with):

```swift
        #expect(items[0].sortOrder == 1)  // A: was 0, now at index 1
        #expect(items[1].sortOrder == 2)  // B: was 1, now at index 2
        #expect(items[2].sortOrder == 0)  // C: was 2, now at index 0
        #expect(items[3].sortOrder == 3)  // D: unchanged
```

Run:

```bash
xcodebuild test -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:LiftOSTests/SessionExerciseReorderTests 2>&1 | tail -20
```

Expected: all 3 tests pass. If `moveDown` also has a mismatch, derive its expected order using the same approach (`move(fromOffsets: [0], toOffset: 3)` → `[B, C, A, D]` → A→2, B→0, C→1, D→3 — which already matches what's written).

- [ ] **Step 5: Commit**

```bash
git add LiftOS/Models/SessionExercise.swift LiftOSTests/LiftOSTests.swift
git commit -m "$(cat <<'EOF'
feat(workout): add SessionExercise.reorder helper for drag-to-reorder

Pure static method that applies a SwiftUI .onMove operation
(IndexSet + destination offset) to an array of SessionExercise
and reindexes sortOrder on each item. Unit-tested independently
of the View layer.

Refs #2

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Refactor ActiveWorkoutView to use List with .onMove

**Why this task exists:** This is the user-visible change. We swap the container from `LazyVStack` to `List`, hook the helper from Task 1 into `.onMove`, add `EditButton` to the toolbar, and tune list-row modifiers so the `GroupBox` cards keep their current appearance.

**Files:**
- Modify: `LiftOS/Views/Workout/ActiveWorkoutView.swift:27-57` (the `body`'s outer `VStack` containing the `ScrollView`)
- Modify: `LiftOS/Views/Workout/ActiveWorkoutView.swift:58-65` (the `.toolbar`)

- [ ] **Step 1: Add edit-mode state + reorder haptic trigger**

In `ActiveWorkoutView` (top of the struct, after the existing `@State` declarations around line 25), add:

```swift
    @State private var editMode: EditMode = .inactive
    @State private var reorderTrigger = false
```

- [ ] **Step 2: Replace ScrollView+LazyVStack with List**

Replace lines 31–54 (the `ScrollView { LazyVStack { ... } }` block) with:

```swift
            List {
                Section {
                    ForEach(session.sortedExercises) { sessionExercise in
                        ExerciseLogCard(
                            sessionExercise: sessionExercise,
                            previousSets: previousSets(for: sessionExercise),
                            isExpanded: expandedExerciseID == sessionExercise.id,
                            onToggle: { toggleExpanded(sessionExercise) },
                            onSetCompleted: { handleSetCompleted(sessionExercise) },
                            onRemove: {
                                exerciseToRemove = sessionExercise
                                showRemoveConfirmation = true
                            },
                            onSwap: {
                                exerciseToSwap = sessionExercise
                                showSwapPicker = true
                            }
                        )
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    .onMove { source, destination in
                        SessionExercise.reorder(session.sortedExercises, from: source, to: destination)
                        reorderTrigger.toggle()
                    }
                }

                if !editMode.isEditing {
                    Section {
                        addExerciseButton
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
            .sensoryFeedback(.success, trigger: reorderTrigger)
            .onChange(of: editMode.isEditing) { _, isEditing in
                if isEditing {
                    expandedExerciseID = nil
                }
            }
```

- [ ] **Step 3: Add EditButton to the toolbar**

Replace the existing `.toolbar { ... }` block (lines 59–65) with:

```swift
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel", role: .destructive) {
                    showDiscardConfirmation = true
                }
                .disabled(editMode.isEditing)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
```

> Cancel is disabled in edit mode so users can't discard the workout while reordering. They tap Done first.

- [ ] **Step 4: Build and verify it compiles**

Run:

```bash
xcodebuild build -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: `** BUILD SUCCEEDED **`. If the build fails, fix the compile errors before proceeding.

- [ ] **Step 5: Run the full test suite to confirm no regressions**

```bash
xcodebuild test -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30
```

Expected: all suites pass (ProgressionEngine, ProgressCalculator, SessionBuilder, PlanSyncService, SessionExercise.reorder).

- [ ] **Step 6: Commit**

```bash
git add LiftOS/Views/Workout/ActiveWorkoutView.swift
git commit -m "$(cat <<'EOF'
feat(workout): enable drag-to-reorder exercises during active workout

Refactor ActiveWorkoutView from ScrollView+LazyVStack to List with
.onMove(), wire up EditButton in the trailing toolbar slot, and route
reorder events through SessionExercise.reorder. Add Exercise button is
hidden during edit mode so users cannot drop an exercise below it.
Expanded cards auto-collapse on entering edit mode for cleaner drag
targets. Drop haptic via .sensoryFeedback(.success).

Visual parity with the previous LazyVStack layout maintained via
.listRowSeparator(.hidden), .listRowBackground(Color.clear), tuned
.listRowInsets, and .scrollContentBackground(.hidden).

Refs #2

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Verify swipe-to-delete on SetLogRow, fall back to .swipeActions if needed

**Why this task exists:** `SetLogRow` uses a custom `DragGesture(minimumDistance: 20)` for swipe-to-delete (`ActiveWorkoutView.swift:569-589`). `List` rows on iOS may absorb horizontal drags, breaking this. The set rows are nested *inside* `ExerciseLogCard` (which is the `List` row), so the gesture is one level removed from List itself — but it still warrants explicit verification.

**Files:**
- Read-only first: `LiftOS/Views/Workout/ActiveWorkoutView.swift:461-590` (`SetLogRow` definition)
- Conditional modify: same file, same range

- [ ] **Step 1: Hand off to Garrett for simulator verification**

Garrett (the user) must verify in the simulator. Output a checklist message:

> "Build is ready for simulator testing. Please verify acceptance criteria before I migrate the swipe gesture:
>
> 1. Tap **Edit** in the toolbar during a workout — does the list enter edit mode with drag handles on each card?
> 2. Drag an exercise to a new position — does the reorder feel native (smooth animation, haptic on drop)?
> 3. Tap **Done** — does the new order persist visually?
> 4. Force-quit the app and reopen — does the new order persist (sortOrder write succeeded)?
> 5. **Critical:** With a set row visible, swipe left on the set row — does the red delete button still appear?
> 6. Visual: do the cards still look the same as before (spacing, background, GroupBox styling)?
>
> Reply with which criteria pass and which fail."

- [ ] **Step 2: Branch on Garrett's findings**

**If swipe-to-delete (#5) PASSES:** Skip to Step 4. The custom gesture is compatible.

**If swipe-to-delete (#5) FAILS:** Continue to Step 3 to migrate to `.swipeActions`.

- [ ] **Step 3 (conditional): Migrate SetLogRow to .swipeActions**

In `LiftOS/Views/Workout/ActiveWorkoutView.swift`, inside `SetLogRow.body`:

**Remove** the entire `ZStack(alignment: .trailing)` wrapper (lines ~484–590), the `swipeOffset` and `showDeleteButton` `@State` (lines ~479–480), and the `.gesture(...)` block (lines ~569–589). Keep the inner `HStack` and the RIR selector.

**Add** `.swipeActions` to the outer `VStack` of the body:

```swift
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
```

Note: `.swipeActions` requires the row to be a direct child of a `List`. Since `SetLogRow` is nested inside `ExerciseLogCard` (which is inside `List`), this will not work as-is. **If Step 2 routed us here, the correct fallback is to use a context menu instead:**

```swift
        .contextMenu {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete Set", systemImage: "trash")
                }
            }
        }
```

Long-press on a set row → context menu with Delete. Strictly more accessible than horizontal swipe, and works regardless of List context.

Then run:

```bash
xcodebuild build -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -20
```

Expected: build succeeds. Commit:

```bash
git add LiftOS/Views/Workout/ActiveWorkoutView.swift
git commit -m "$(cat <<'EOF'
fix(workout): replace SetLogRow swipe gesture with context menu

The custom DragGesture on SetLogRow conflicted with List's gesture
recognizers in the new reorder-enabled ActiveWorkoutView. Migrating to
a long-press context menu eliminates the conflict and is more
accessible than a horizontal swipe.

Refs #2

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: Done — proceed to Task 4**

---

## Task 4: Final verification, push, and PR

**Files:** none (process-only)

- [ ] **Step 1: Run the full test suite once more**

```bash
xcodebuild test -project AdaptOS.xcodeproj -scheme LiftOS -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -10
```

Expected: all tests pass.

- [ ] **Step 2: Confirm working tree is clean**

```bash
git status
```

Expected: `nothing to commit, working tree clean` on `feat/reorder-active-workout-exercises`.

- [ ] **Step 3: Confirm Garrett has signed off on the simulator acceptance checklist (Task 3 Step 1)**

Do not proceed to push until Garrett confirms each of the 7 acceptance criteria from the issue manually in the simulator. CLAUDE.md is explicit: "Visual/UI changes: the user (Garrett) tests in the simulator — Claude cannot."

- [ ] **Step 4: Push the branch**

```bash
git push -u origin feat/reorder-active-workout-exercises
```

- [ ] **Step 5: Open the PR**

```bash
gh pr create --title "feat(workout): reorder exercises during active workout" --body "$(cat <<'EOF'
## Summary
- Refactor `ActiveWorkoutView` from `LazyVStack` to `List` with `.onMove()` for native drag-to-reorder
- `EditButton` in the trailing toolbar slot drives `EditMode`; cards auto-collapse on entering edit mode; Add Exercise button hides while editing
- Reorder logic extracted to `SessionExercise.reorder(_:from:to:)` static helper with unit tests
- Drop haptic via `.sensoryFeedback(.success)`
- Visual parity with previous layout via hidden separators, clear row backgrounds, tuned insets

Closes #2

## Test plan
- [x] `SessionExercise.reorder` unit tests pass (3 cases)
- [x] Full test suite passes
- [x] Build succeeds for iPhone 16 simulator
- [ ] Long-press drag handle enters reorder mode (manual)
- [ ] Haptic feedback on pickup and drop (manual)
- [ ] Completed exercises can be reordered without data loss (manual)
- [ ] `sortOrder` persists across app backgrounding (manual)
- [ ] Rest timer is not interrupted by reorder (manual)
- [ ] Swipe/context-menu delete on set rows still works (manual)
- [ ] Visual appearance matches current card layout (manual)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 6: Apply labels per project conventions**

```bash
PR_NUM=$(gh pr view --json number -q .number)
gh pr edit "$PR_NUM" --add-label "type:enhancement,area:workout-logging,priority:P2-later"
```

- [ ] **Step 7: Report PR URL to Garrett**

---

## Self-review checklist (run before handing off to executor)

- **Spec coverage:**
  - [x] List + .onMove refactor → Task 2
  - [x] `.listRowSeparator(.hidden)`, `.listRowBackground(Color.clear)`, `.listRowInsets` → Task 2 Step 2
  - [x] `EditButton` in toolbar → Task 2 Step 3
  - [x] `.onMove()` writes `sortOrder` → Task 1 helper, called in Task 2
  - [x] Swipe-to-delete verification + fallback → Task 3
  - [x] Pickup + drop haptic → Task 2 Step 2 (`.sensoryFeedback(.success, trigger: reorderTrigger)`); pickup is automatic on iOS 17+ List
  - [x] Acceptance criteria handed off to Garrett for manual verification → Task 3 Step 1
- **Placeholder scan:** No TBDs, no "implement later", no "similar to Task N" — every step has actual code or commands.
- **Type consistency:** `SessionExercise.reorder` signature is `static func reorder(_ exercises: [SessionExercise], from source: IndexSet, to destination: Int)` — used identically in Task 1 (definition + tests) and Task 2 Step 2 (call site).
- **Sequence:** Helper before consumer. Build-passing before push. Manual verification before PR.

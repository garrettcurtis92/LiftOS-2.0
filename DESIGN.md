---
name: LiftOS
description: A premium native iOS workout tracker for serious progressive-overload lifters
colors:
  accent: "Color.accentColor"
  success: "Color.green"
  warning: "Color.orange"
  warmup: "Color.orange"
  deload: "Color.orange"
  highlight: "Color.yellow"
  card-background: "Color(.secondarySystemBackground)"
  elevated-background: "Color(.tertiarySystemBackground)"
  text-primary: ".primary"
  text-secondary: ".secondary"
  text-tertiary: ".tertiary"
typography:
  large-title:
    fontFamily: "SF Pro Display (system)"
    fontSize: ".largeTitle"
    fontWeight: "regular"
  title2:
    fontFamily: "SF Pro Display (system)"
    fontSize: ".title2"
    fontWeight: "medium"
  title3:
    fontFamily: "SF Pro Display (system)"
    fontSize: ".title3"
    fontWeight: "regular"
  headline:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".headline"
    fontWeight: "semibold"
  body:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".body"
    fontWeight: "regular"
  body-medium:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".body"
    fontWeight: "medium"
  subheadline:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".subheadline"
    fontWeight: "regular"
  caption:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".caption"
    fontWeight: "regular"
  caption-semibold:
    fontFamily: "SF Pro Text (system)"
    fontSize: ".caption"
    fontWeight: "semibold"
  numeric-display:
    fontFamily: "SF Mono (system, design: .monospaced)"
    fontSize: "48"
    fontWeight: "bold"
  numeric-readout:
    fontFamily: "SF Mono (system, design: .monospaced)"
    fontSize: ".title2"
    fontWeight: "medium"
rounded:
  input: "6"
  small: "8"
  card: "12"
  sheet: "20"
spacing:
  list-item: "4"
  compact: "8"
  card: "16"
  section: "20"
components:
  card:
    backgroundColor: "{colors.card-background}"
    rounded: "{rounded.card}"
    padding: "16"
  button-primary:
    backgroundColor: "{colors.accent}"
    textColor: "white"
    rounded: "{rounded.card}"
    padding: "16"
  set-row-checkmark-incomplete:
    textColor: "{colors.text-secondary}"
  set-row-checkmark-complete:
    textColor: "{colors.success}"
  numeric-input:
    backgroundColor: "{colors.card-background}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.input}"
    padding: "8"
  rir-chip-unselected:
    backgroundColor: "{colors.card-background}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.input}"
  rir-chip-selected:
    backgroundColor: "{colors.accent}"
    textColor: "white"
    rounded: "{rounded.input}"
  sheet:
    backgroundColor: "{colors.elevated-background}"
    rounded: "{rounded.sheet}"
---

# Design System: LiftOS

## 1. Overview

**Creative North Star: "The Pro Athlete's Tool"**

LiftOS dresses like a first-party iOS app and behaves like a clinical-grade fitness instrument. It speaks Apple's visual vocabulary — system semantic colors, SF Pro Text/Display, SF Symbols, system-native lists and sheets, system blue as the single accent — and pushes past Apple's own defaults exactly where a stock app would settle. Monospaced digits anywhere a number lives. Editorial weight contrast in row-level data. Spring-and-easeOut motion at the moments that matter, never as decoration. The result reads like Halide for cameras or Things 3 for tasks: clearly built on Apple's stack, just visibly more deliberate than what Apple ships in the same category.

The system is **flat by default, expressive on cue.** Surfaces use tonal layering (`secondarySystemBackground` over `systemBackground`, `tertiarySystemBackground` for elevated overlays) instead of decorative shadows. The only literal `.shadow` lives on the rest-timer progress ring, where the colored glow is functional — it tells the user the timer is alive. Everywhere else, depth is implied by background tone, never by drop shadow.

LiftOS explicitly **rejects** the over-stylized brutalist fitness aesthetic (Whoop-style neon-on-black, sci-fi HUD, all-caps masculine "beast mode" tone), the generic SaaS-dashboard cliché (hero-metric cards with big number / tiny label / decorative gradient, purple-to-blue gradients, glassmorphism as default, gradient text), and the spreadsheet-tracker failure mode (gray-on-gray rows, no hierarchy, accounting-software flat). The strategic line from PRODUCT.md carries through every decision below.

**Key Characteristics:**
- First-party iOS feel, elevated through deliberate craft (not invented from scratch)
- System semantic colors only; system blue as the single accent
- Tabular monospaced digits for every weight, rep count, time, and RPE/RIR readout
- Tonal layering for depth; literal shadows are rare and functional
- Spring-and-easeOut motion that enhances feedback, never gates input
- Quiet rewards — no confetti, no streak banners, no celebratory modals
- Density is composed and editorial, not flat or crowded
- HIG compliance is the floor, not the ceiling

## 2. Colors

The palette is Apple's, used with discipline. There is one true accent (system blue), one success color (system green) reserved for set-completion and finish moments, and one alert color (system orange) shared across warmup sets, deload weeks, and rest-timer urgency. Yellow exists for PRs and top-set highlights and appears on screen at most a few times per session. Everything else is system semantic backgrounds and `.primary` / `.secondary` / `.tertiary` text styles, which adapt automatically to Dark Mode and Increase Contrast.

### Primary
- **System Blue** (`Color.accentColor`): the single brand accent. Worn by the Start Workout button, RIR chip selection, link affordances, the rest-timer progress ring at rest, the active-week badge on Home, and the muted "PREV" column highlight when the user beats last session. Used sparingly — never as a wash, never as a gradient, never on more than ~10% of any given screen at once.

### Secondary
- **System Green** (`Color.green`): set-completion checkmark color, Finish Workout success haptic affordance, rest-timer completion pulse, brief row-flash tint (`Color.green.opacity(0.08)`) on a completed set. The reward color. Never used decoratively; always tied to a logged moment.

### Tertiary
- **System Orange** (`Color.orange`): warmup set indicator (set number renders as "W" in orange when toggled), deload-week badge on plan rows, rest-timer last-five-seconds urgency (numeric digits scale up, ring stroke shifts to orange), and inline warmup tags in the workout summary. One color, three cousin roles.
- **System Yellow** (`Color.yellow`): PR markers, top-set / trophy moments on the Workout Summary screen. The most restrained color — it should be rare enough that it earns the eye when it shows up.

### Neutral
- **Primary Background** (system, implicit via `Color(.systemBackground)`): root page backdrop. Adapts to Dark Mode automatically.
- **Secondary System Background** (`Color(.secondarySystemBackground)`): card surfaces, set-row inputs, exercise card backgrounds, RIR chips at rest, the auto-rest-timer toggle bar. The default "card" surface for the whole app.
- **Tertiary System Background** (`Color(.tertiarySystemBackground)`): elevated surfaces — modal sheets at full presentation, overlay panels, the rest-timer overlay's interior fill. Use only when a surface explicitly sits on top of a Secondary card.
- **Primary Text** (`.primary`): all main copy, set numbers, weight/rep values when entered.
- **Secondary Text** (`.secondary`): row labels (Set, Reps, Weight column headers), inactive states, supplementary metadata, last-session "prev" annotations.
- **Tertiary Text** (`.tertiary`): unit labels (lbs, kg), placeholder digits in unfilled inputs, decorative metadata that should fade into the page.

### Named Rules

**The One Accent Rule.** System blue carries the brand. It is never paired with a second hue as a "secondary brand" — every other color in the palette has a literal functional role (success, warning, warmup, PR). If a visual element needs color and isn't tied to one of those roles, it stays neutral. No purple, no teal, no cyan. The accent is rare and it stays rare.

**The Semantic-Only Rule.** Never use a literal hex value for text or background. Every color is a system semantic (`Color.accentColor`, `.primary`, `Color(.secondarySystemBackground)`) or a single tinted role exposed through `LiftTheme` (`success`, `warning`, `warmup`, `deload`, `highlight`). This is what makes the app adapt to Dark Mode, Increase Contrast, and tinted accent overrides without code changes. Hardcoded colors are forbidden.

**The Reward-Color Rule.** Green and yellow only appear in response to a user's logged action — completing a set, hitting a PR, finishing a workout. They are *never* decorative. If you find yourself reaching for green on a static label, it is wrong. Switch to neutral.

## 3. Typography

**Display Font:** SF Pro Display (system, used implicitly at `.largeTitle`, `.title`, `.title2`, `.title3` via Dynamic Type)
**Body Font:** SF Pro Text (system, used implicitly at `.headline`, `.body`, `.subheadline`, `.callout`, `.caption`, `.caption2` via Dynamic Type)
**Numeric Font:** SF Mono / system monospaced (`design: .monospaced`) for every digit that represents weight, reps, time, RPE, RIR, set count, or volume

**Character.** The pairing is Apple's — but used with editorial discipline. Type sizes always come from the semantic Dynamic Type scale (`.headline`, `.body`, `.caption`); fixed point sizes appear only for the rest-timer numeric display (48pt monospaced bold, the one true exception). Hierarchy is built through weight contrast (regular → medium → semibold → bold), not through size alone. Numbers wear monospaced everywhere they live so columns of weights and reps align cleanly without the eye doing arithmetic on glyph widths.

### Hierarchy

- **Large Title** (regular, `.largeTitle`, system line-height): screen titles in the navigation bar (`Today`, `Plans`, `History`, `Profile`).
- **Title 2** (medium, `.title2`, often `design: .monospaced`): the active-workout running clock, prominent numeric readouts. Monospaced when it carries a number; default when it carries a label.
- **Title 3** (regular, `.title3`): primary stat figures on the Workout Summary, large interactive icons.
- **Headline** (semibold, `.headline`): exercise name on the active set row, section headers, sheet titles, navigation row labels. The single most-used hierarchy step.
- **Body** (regular, `.body`): default running copy, descriptive lines.
- **Body Medium** (medium, `.body`): emphasized inline values — entered weight/reps in a set row before completion, the active week label.
- **Subheadline** (regular, `.subheadline`): secondary descriptive lines under a Headline (e.g. "3 exercises · 12 sets" under a routine name).
- **Caption** (regular, `.caption`): row metadata, "lbs" / "kg" units inline next to numbers, last-session "prev" annotations.
- **Caption Semibold** (semibold, `.caption`): column headers above set tables ("SET", "REPS", "WEIGHT", "RIR"), small inline labels that need to read as labels rather than data.
- **Numeric Display** (bold, 48pt, `design: .monospaced`): the rest-timer countdown — the one place the system uses a fixed point size. Scales 1.05x in the last five seconds.
- **Numeric Readout** (medium, `.title2`, `design: .monospaced`): the active-workout running clock and similar prominent timers.

### Named Rules

**The Monospaced-Digits Rule.** Every numeric value in the app — weight, reps, RIR, RPE, set number, total volume, time elapsed, time remaining — uses `design: .monospaced` or `.monospacedDigit()`. Tabular alignment is non-negotiable. A column of "135 / 140 / 145" must read as a vertical stack, not a ragged line of glyphs. This is the single highest-leverage typographic decision in the app.

**The Semantic-Scale Rule.** Type sizes come from the Dynamic Type scale (`.headline`, `.body`, etc.), never hardcoded points. The rest-timer 48pt display is the *only* documented exception (large enough to read at arm's length under bright gym light). If a new view "needs" a hardcoded size, the answer is almost always to combine an existing scale step with a weight change.

**The Weight-Contrast Rule.** Hierarchy between adjacent text elements uses ≥1 weight step difference (regular vs. medium, medium vs. semibold). Same-weight stacks read as flat — that's the spreadsheet failure mode.

## 4. Elevation

LiftOS is **flat by default** and uses **tonal layering** (Apple's `systemBackground` → `secondarySystemBackground` → `tertiarySystemBackground` ramp) for depth instead of literal shadows. A card on the Home screen sits on the page because its background is one tonal step lighter (in light mode) or darker (in dark mode) than the page beneath it — there is no `.shadow` on it.

Material backgrounds (`.ultraThinMaterial`) are used sparingly: the auto-rest-timer toggle bar at the bottom of the active workout uses `.ultraThinMaterial` so it reads as floating chrome over scrolling content. This is the lone application of frosted material in the app and it's functional, not decorative.

Literal shadows appear in exactly one documented place: the rest-timer progress ring carries a colored glow shadow (`.shadow(color: accent.opacity(0.4), radius: 6)`) so the timer feels alive at a glance from across the gym. The shadow color shifts to orange in the last five seconds. If a future feature wants to use `.shadow`, it needs an equally specific functional reason.

### Named Rules

**The Flat-By-Default Rule.** No `.shadow` on cards, rows, sheets, buttons, or any surface at rest. Depth is conveyed by the tonal ramp (`systemBackground` → `secondarySystemBackground` → `tertiarySystemBackground`). If a card "looks flat against the background," the answer is the next tonal step, not a drop shadow.

**The Functional-Glow Rule.** The only legitimate uses of `.shadow` are (a) the rest-timer progress ring at rest and during urgency, and (b) any future moment where the shadow is doing real work (e.g. a Live Activity element that needs to lift off the lock screen). Decorative ambient shadows under cards are forbidden.

**The Sheet-Material-Rule.** Modal sheets use the system's default surface — they sit on `tertiarySystemBackground` with `presentationCornerRadius(20)` and `presentationDragIndicator(.visible)`. No custom shadow under the sheet, no glassmorphic blur except `.ultraThinMaterial` on the auto-rest toggle bar, no decorative outline.

## 5. Components

### Buttons
- **Shape:** rounded rectangle, 12pt corner radius (`LiftTheme.cornerRadius`).
- **Primary:** filled with `Color.accentColor`, white text, `.headline` weight, vertical padding ~16pt. Used for the Start Workout / Quick Workout / Finish Workout call-to-action and the rest-timer "Skip" button.
- **Secondary / Ghost:** plain text in `Color.accentColor` at `.body` weight, no fill — for "Add Set", "Add Exercise", and similar inline affordances inside cards. They sit *inside* a card surface and don't compete with it.
- **Tertiary / Destructive:** the swipe-to-delete row uses a system red filled background with a white trash icon, exposed only on swipe. Confirmation dialogs (`.confirmationDialog`) handle every destructive action — never a silent tap.
- **Hover / Pressed:** system default press feedback. Don't override.

### Cards / Containers
- **Corner Style:** 12pt (`LiftTheme.cornerRadius`).
- **Background:** `Color(.secondarySystemBackground)`. Always.
- **Border:** none.
- **Shadow:** none (per Flat-By-Default Rule).
- **Internal Padding:** 16pt (`LiftTheme.cardSpacing`).
- **Use:** the standard surface for routine rows on Home, exercise cards in the active workout, plan rows in the Plans tab, summary stat blocks. Cards never nest inside other cards.

### Set Row (the signature component)
The most-tapped, most-looked-at element in the app. One row contains: set number (or "W" for warmup, in orange), weight input, reps input, prev-session annotation in `.tertiary` text, completion checkmark, and an expanding RIR/RPE selector that slides in below on tap.

- **Layout:** horizontal `HStack` with column alignment that matches the column headers ("SET", "REPS", "WEIGHT", "RIR") above. Tabular monospaced digits.
- **Numeric inputs:** 6pt corner radius (`LiftTheme.inputCornerRadius`), `secondarySystemBackground` fill, `.body.weight(.medium)` text, `design: .monospaced`. Tap targets remain ≥44pt.
- **Set number tap toggles warmup:** number → "W", color → `.orange`, with `.sensoryFeedback(.selection)`.
- **Completion checkmark:** SF Symbol `checkmark.circle.fill` at `.title3`, `.secondary` when incomplete, `.green` when complete. On tap: bounce (scale 0.5 → 1.0 via spring), color fade-in, brief row tint flash (`Color.green.opacity(0.08)`, 0.6s decay), `.sensoryFeedback(.success)`.
- **RIR selector:** appears below the row on completion via `.transition(.move(edge: .bottom).combined(with: .opacity))`. Six chips (0–5) using `inputCornerRadius` (6pt) — selected chip fills with `Color.accentColor`, unselected sits on `secondarySystemBackground`.

### Inputs / Numeric Fields
- **Style:** `secondarySystemBackground` fill, 6pt corner radius (`inputCornerRadius`), `.body.weight(.medium)` monospaced.
- **Focus:** system default keyboard focus styling. No custom glow.
- **Auto-fill:** entering a weight in Set 1 auto-fills the same weight in remaining sets — that interaction is part of the speed-of-logging principle.
- **Error / Disabled:** disabled inputs read at `.tertiary` text color; error states are vanishingly rare in this app and use system orange + a `.confirmationDialog` rather than inline error chrome.

### Sheets
- **Corner Style:** 20pt (`presentationCornerRadius(20)`) on every sheet.
- **Drag Indicator:** `presentationDragIndicator(.visible)` on every sheet.
- **Detents:** purposeful per sheet — `NewRoutineSheet` and `NewExerciseSheet` use `.medium`; `EditPlanSheet` uses `.medium, .large`; `ExercisePickerView` uses `.large`; `WorkoutSummaryView` uses `.large` (and is dismiss-disabled).
- **Background:** system default. No custom material, no custom shadow.

### Rest Timer Overlay (signature component)
A full-screen overlay that fades in over the active workout when a set completes (if auto-rest is enabled). Centered: a circular progress ring (system blue at rest, orange in the last five seconds) and the 48pt monospaced bold countdown. Below the ring: ±15s buttons on `systemGray3`, a Skip button on `accentColor`. The ring carries a colored glow shadow — the lone documented `.shadow` in the app.

- **Entrance:** fade + scale (0.95 → 1.0) over 0.25s easeOut. No pop.
- **Urgency state:** at ≤5 seconds, the digit text scales 1.0 → 1.05, ring stroke transitions to `Color.orange` over 0.3s easeInOut, glow color follows.
- **Completion:** ring flashes green, brief 0.5s pause, then auto-dismiss with fade.
- **Haptics:** `.impact(.light)` on ±15s, `.notification(.warning)` at zero.

### Tab Bar
- **Style:** system default `TabView` with SF Symbol icons (`figure.run`, `list.bullet.clipboard`, `clock.arrow.circlepath`, `person.crop.circle`).
- **Active state:** system default tinting (system blue under default accent).
- **Don't:** customize the tab bar background or shape. The system handles this correctly across iOS versions and Liquid Glass; overriding it breaks more than it improves.

### Lists
- **Style:** prefer `List` (`.insetGrouped` style) and `Form` for any data-entry / settings flow. Lean on system list semantics — swipe actions, context menus, drag-to-reorder, section headers — instead of hand-rolling row layouts.
- **Custom rows** appear inside `List` rows when the data shape demands it (the active-workout exercise cards, for instance), but the *container* stays a system list whenever possible.

## 6. Do's and Don'ts

### Do:
- **Do** use system semantic colors only: `Color.accentColor`, `.primary` / `.secondary` / `.tertiary`, `Color(.secondarySystemBackground)`, `Color(.tertiarySystemBackground)`, and the named roles in `LiftTheme` (`success`, `warning`, `warmup`, `deload`, `highlight`). The app must adapt to Dark Mode and Increase Contrast without code changes.
- **Do** apply `design: .monospaced` (or `.monospacedDigit()`) to every numeric value: weight, reps, RPE, RIR, set number, time elapsed, time remaining, total volume.
- **Do** drive hierarchy through font weight contrast (regular → medium → semibold → bold), not size alone.
- **Do** use the four-step `LiftTheme` corner radii deliberately: 6 for inline numeric inputs, 8 for small chips, 12 for cards and primary buttons, 20 for modal sheets.
- **Do** put `.sensoryFeedback` on every confirmation moment: set completion, RPE selection, warmup toggle, finish workout, rest timer ±15s, rest timer at zero.
- **Do** use `.transition(.move(edge: .bottom).combined(with: .opacity))` for inline reveals like the RIR selector — they read as content arriving, not as a panel popping open.
- **Do** use `easeOut(duration: 0.2–0.4)` for state changes and `spring(response: 0.5, dampingFraction: 0.6)` for the small handful of "rewarding" moments (trophy bounce, set-completion checkmark).
- **Do** present every modal with `.presentationDragIndicator(.visible)` and `.presentationCornerRadius(20)`.
- **Do** respect Reduce Motion: every spring/bounce/scale-in animation must check `@Environment(\.accessibilityReduceMotion)` and degrade to a simple opacity fade or no animation.
- **Do** keep tap targets ≥44pt in the active-workout flow. No exceptions.

### Don't:
- **Don't** use hardcoded hex colors anywhere. If a color isn't a system semantic or a `LiftTheme` role, it doesn't belong in the app. (Per the Semantic-Only Rule.)
- **Don't** use `.shadow` on cards, rows, sheets, or buttons at rest. Depth comes from the tonal ramp, not drop shadows. (Per the Flat-By-Default Rule.)
- **Don't** introduce a second brand color alongside system blue. The accent stays rare and stays alone. (Per the One-Accent Rule.)
- **Don't** use green or yellow decoratively. They appear only in response to a logged user action — set complete, workout finished, PR hit. (Per the Reward-Color Rule.)
- **Don't** use `background-clip: text` equivalents (no gradient text via `.foregroundStyle(LinearGradient(...))`). One solid color, period.
- **Don't** wrap a colored stripe down the side of a card or row (any `border-leading` greater than 1pt as a colored accent). Use full borders, background tints, or leading icons instead.
- **Don't** build hero-metric cards: big number / tiny label / decorative gradient. That's the SaaS-dashboard cliché PRODUCT.md explicitly rejects.
- **Don't** build identical-looking icon-heading-text card grids. Each card type should look like itself.
- **Don't** use glassmorphism / `.ultraThinMaterial` decoratively. The one allowed use is the auto-rest toggle bar where it functions as floating chrome over scrolling content.
- **Don't** congratulate the user on a light set. No coach voice, no streak guilt, no "you haven't trained in 3 days" notifications. (Per PRODUCT.md's Trust the User's Expertise principle.)
- **Don't** hardcode font point sizes. The rest-timer 48pt monospaced display is the only documented exception. Everything else uses Dynamic Type scale (`.headline`, `.body`, etc.).
- **Don't** use all-caps for body text or button labels. SF Pro is not a display font that wants caps. The only acceptable caps are short metadata labels (column headers like "SET" / "REPS") at `.caption.weight(.semibold)`.
- **Don't** use emojis or trophy-style iconography in product copy. SF Symbols only, used semantically.
- **Don't** present a fullscreen confetti / celebratory animation on PR or workout completion. The Workout Summary screen carries the moment; no extra ceremony layered on top. (Per the Quiet Rewards principle.)
- **Don't** stack animations during rapid set logging. If a user taps five checkmarks in two seconds, animations must not queue, lag, or block input. Speed of logging is sacred.

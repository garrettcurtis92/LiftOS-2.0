# Product

## Register

product

## Users

Serious progressive-overload lifters. People who follow structured multi-week training plans, care about double progression (beating last session's reps before adding weight), and understand concepts like RPE, deload weeks, and rep ranges without needing them explained. They're disciplined, often training 4–6 days per week, and have used apps like Hevy, RP Hypertrophy, or MacroFactor Workouts before — and have opinions about what those apps got wrong.

**Use context:** in a gym, mid-workout, between sets. Phone in one hand, sometimes sweaty. The app is opened many times per session and must be glanceable, fast to log into, and forgiving of a quick tap. Sessions last 45–90 minutes with the screen returning to focus dozens of times.

**Job to be done:** log every set, rep, and weight against a planned routine; see what was done last session inline; know exactly what to beat today; review progress over weeks without ceremony.

## Product Purpose

LiftOS is a native iOS workout tracker built around the **double-progression** model: previous session's reps/weight are shown inline next to the input fields so the user always knows the target to beat. Plans organize multi-week training (with deload weeks) → daily routines → exercises → prescribed sets. The template side (plan) and the logging side (session) are intentionally separate so plan edits never corrupt historical records. Data is local-only via SwiftData (no backend, no account required beyond Sign in with Apple).

**Success looks like:** a serious lifter installs LiftOS, imports or builds a plan in 10 minutes, and finds it genuinely faster and more pleasant to log a workout than whatever they were using before — without losing any data fidelity, and without the social/gamified noise of Hevy or the spreadsheet feel of Strong.

## Brand Personality

**Three words:** premium, native, expert.

**Voice and tone:** quiet competence. Speaks to the user as a peer who already knows the vocabulary (RPE, deload, rep range, double progression). No congratulatory copy on light sets. No emojis in product copy. No fitness-bro language ("crush it," "beast mode," "GAINS"). When the app does speak — empty states, completion summary, an unprompted observation — the line is short, plain, and useful.

**Emotional goals:** the user opens it and feels *this is how Apple would build a workout tracker if they cared more*. Not stock. Not novelty. Refined first-party feel — the kind of polish that signals craft without announcing itself. Logging a set should feel mechanical and satisfying; finishing a workout should feel earned, not celebrated at you.

## Anti-references

**Over-stylized / brutalist fitness apps** (Whoop-style dark-mode-only with neon accents, sci-fi HUD vibe, all-caps everywhere, aggressive masculine "beast mode" tone). LiftOS is for people who take training seriously enough that they don't need the app to perform seriousness on their behalf.

**Generic SaaS dashboards.** No hero-metric cards (big number / tiny label / decorative gradient). No purple-to-blue brand gradients. No identical icon-heading-text card grids. No glassmorphism used decoratively. No gradient text. No side-stripe colored borders on cards.

**Spreadsheet-aesthetic trackers** (Strong, FitNotes). Dense gray-on-gray rows with no hierarchy, no breathing room, no sense that anyone made deliberate visual choices — that's the failure mode to avoid. LiftOS *is* dense by necessity (prev session, target reps, RPE, weight all visible at once) but the density should feel composed and editorial, not accounting-software flat.

## Design Principles

1. **First-party feel, elevated craft.** HIG compliance is the floor, not the ceiling. Use system semantic styles (`.headline`, `.body`, `.primary`, system blue accent), system-native components (`List`, `Form`, `GroupBox`), and Apple's own gestures (swipe actions, context menus, confirmation dialogs). Then push past the defaults with deliberate typography weight pairings, monospaced digits for all numbers, considered spacing rhythm, and subtle motion that Apple's stock apps don't bother with. The bar is *Things 3 / Halide* level of polish, expressed through Apple's vocabulary — not invented from scratch.

2. **Speed of logging is sacred.** The set-completion checkmark is tapped 50+ times per session, often quickly, sometimes one-handed. Every interaction in the active-workout flow is judged by *how fast can a focused lifter log a set?* — not by how interesting the animation is. Animations must enhance feedback (haptics, color flash, micro-bounce), never block input or stack up under rapid taps. If a polish layer adds even 100ms of perceived friction during logging, it's wrong.

3. **Trust the user's expertise.** No tooltips explaining RPE. No coach-voice congratulating a 95 lb warm-up set. No nudges, no streak guilt, no "you haven't trained in 3 days!" notifications. The user is competent and self-motivated; the app's job is to record accurately, surface previous-session data clearly, and stay out of the way. Empty states are calm, not anxious.

4. **Quiet rewards beat loud ones.** Hitting a PR is noted with a small inline accent (a subtle badge, a number that gains weight, a single haptic), not celebrated with confetti or a fullscreen modal. The genuine reward is the data: previous session beaten, target range hit, weight progressed. Visible progress is the prize — the app doesn't perform congratulation on top of it.

5. **Density should feel composed, not crowded.** Lifters need to see prev-session reps/weight, target rep range, current input fields, and RPE simultaneously — that's a lot in one row. The answer is editorial typographic hierarchy (weight, color, leading), not extra cards or expanding panels. Information density is a feature; visual noise is the bug. Think a well-typeset table, not a stat dashboard.

## Accessibility & Inclusion

WCAG 2.1 AA minimum across the app. All four firm requirements:

- **Dynamic Type at every size, xSmall through AX5.** Layouts in `ActiveWorkoutView`, `SetLogRow`, history lists, and plan-builder sheets must hold up at the largest accessibility sizes. No clipped text, no broken horizontal stacks — switch to vertical layouts at AX1+ where needed.
- **VoiceOver complete.** Every set/rep/weight/RPE is readable in logical order. Every icon-only button has an accessibility label. Custom accessibility actions on set rows (complete, mark warmup, delete) so blind users can log without fighting the row layout.
- **Reduce Motion respected.** All Phase 6 polish — checkmark bounce, RPE slide-in, rest-timer entrance, breathing pulse on Start Workout, summary stats stagger — gracefully degrades to a simple opacity fade or no animation when Reduce Motion is enabled.
- **Bold Text + Increase Contrast.** All UI text thickens correctly. Custom Theme colors meet 4.5:1 against their backgrounds in normal mode and continue to pass under Increase Contrast.

Sweaty hands and gym lighting are an inclusion concern even outside formal a11y: 44pt minimum tap targets are firm (no exceptions in the active workout flow), and the rest timer remains legible from arm's length under bright fluorescent gym light.

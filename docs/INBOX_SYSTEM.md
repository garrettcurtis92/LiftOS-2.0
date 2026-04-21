# The Inbox System

A zero-friction pipeline from "ugh, this is broken" (mid-workout) to a well-structured
GitHub issue (later, with Claude's help).

---

## The idea

Two rails:

1. **Capture rail** — fast, dumb, voice-driven. Just get the thought out of your head.
2. **Processing rail** — slow, thoughtful, happens when you're at your desk with Claude.

Never mix them. Trying to write a "proper" bug report mid-set is how ideas get lost.

```
iPhone                iCloud Drive              Mac / Cowork             GitHub
─────                 ─────────────             ────────────             ──────
 Siri → Shortcut ──>  LiftOS/inbox.md  ─┐
                                         │
 Tap home icon ────>  LiftOS/inbox.md  ──┤──>  Claude reads file  ──>  gh issue create
                                         │        (in Cowork)                │
                                        sync                                 ▼
                                         │                            issues in backlog
                                         ▼
                                 Mac also sees file
                                (same inbox.md everywhere)
```

---

## Part 1 — One-time Mac setup (2 minutes)

Open Terminal on your Mac and run:

```bash
# Create the inbox folder inside your iCloud Drive
ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
mkdir -p "$ICLOUD/LiftOS"

# Seed the two files (inbox = unread, archive = processed)
cat > "$ICLOUD/LiftOS/inbox.md" <<'EOF'
# LiftOS Inbox

Raw capture. Don't worry about structure — just dump.
Claude will read this file in Cowork, ask clarifying questions,
and turn each entry into a properly-structured GitHub issue.

---

EOF

cat > "$ICLOUD/LiftOS/inbox-archive.md" <<'EOF'
# LiftOS Inbox — Archive

Processed entries, by date. Kept for reference so you can see the
original raw thought vs. the final issue.

---

EOF

echo "Done. Files created at: $ICLOUD/LiftOS/"
```

**Verify in Finder:** `Cmd+Shift+G` → paste `~/Library/Mobile Documents/com~apple~CloudDocs/LiftOS/` → you should see both files.

You can also find it in the Files app on iPhone under **iCloud Drive → LiftOS**.

---

## Part 2 — Build the Siri Shortcut on your iPhone (10 minutes, once)

The goal: say "Hey Siri, log LiftOS" → dictation appears → you speak → the Shortcut
appends a timestamped entry to `inbox.md`.

### Steps

1. Open the **Shortcuts** app on iPhone (pre-installed).
2. Tap **+** (top right) to create a new Shortcut.
3. Tap the name at the top and call it **"Log LiftOS"**.
4. Add actions in order — tap **+ Add Action** between each:

   | # | Action (search this in the action picker) | Configuration |
   |---|-------------------------------------------|---------------|
   | 1 | **Dictate Text** | Language: English (US). Stop Listening: **After Pause** (or **After 30 seconds** if you tend to think mid-sentence). |
   | 2 | **Get Current Date** | *(no config needed)* |
   | 3 | **Format Date** | Tap the date variable → Format: **ISO 8601**. Or use Custom: `yyyy-MM-dd HH:mm`. |
   | 4 | **Text** | Type this exactly (with a blank line above/below to make it a clean entry): <br><pre>- [ ] [Formatted Date] &mdash; [Dictated Text]<br><br></pre>Where `[Formatted Date]` and `[Dictated Text]` are variables you insert by tapping the text field → **Select Variable**. |
   | 5 | **Get File** | Service: **iCloud Drive**. Path: `LiftOS/inbox.md`. Turn OFF "Show Document Picker." |
   | 6 | **Combine Text** | Combine: *the file from step 5* + *the text from step 4*. Separator: *None*. <br>**Important:** file first, new text second — so new entries append to the bottom. |
   | 7 | **Save File** | Service: **iCloud Drive**. Path: `LiftOS/inbox.md`. Turn OFF "Ask Where to Save". Turn ON **Overwrite**. |

5. Tap **Done** (top right) to save.
6. Test: tap the Shortcut's tile. It should ask for Microphone, Files, and iCloud Drive access the first time — grant all three.
7. Set up Siri: hold down the Shortcut tile → **Add to Siri** → record yourself saying "Log LiftOS".
8. **Bonus:** Long-press the Shortcut tile → **Details → Add to Home Screen** so you can tap an icon too.

### First test

- Say: **"Hey Siri, log LiftOS"**
- Siri shows a dictation box → say something like *"testing the inbox system"*
- Open Files app → iCloud Drive → LiftOS → inbox.md → you should see your entry at the bottom.

---

## Part 3 — How you use it day-to-day

### Capture (anytime, anywhere)

- Mid-workout: *"Hey Siri, log LiftOS"* → speak → done.
- Phone in hand: tap the home screen icon → speak.
- Driving: Siri via CarPlay → speak.

Don't edit. Don't structure. Don't worry about duplicates. **Just capture.**

### Process (whenever you open Cowork)

Open Cowork. Say (or type):

> **"Process my inbox."**

Claude will:

1. Read `~/Library/Mobile Documents/com~apple~CloudDocs/LiftOS/inbox.md`
2. Parse each entry (the `- [ ]` bullets)
3. For each one, do one of:
   - **Clear cases** (obvious bug / feature): propose an issue title + labels + body, ask "create this?"
   - **Ambiguous cases**: ask 1-2 clarifying questions first
   - **Duplicates of existing issues**: point out the existing issue, ask whether to add a comment or close
4. After each entry: run `gh issue create` (or give you the exact command if you want to run it yourself)
5. Move the processed entry to `inbox-archive.md` with the created issue number, then clear it from `inbox.md`

### Example

**Inbox:**
```
- [ ] 2026-04-20 09:41 — rest timer dies when i background the app no notification
- [ ] 2026-04-20 10:15 — would be cool if the home tab showed yesterdays volume
- [ ] 2026-04-20 18:03 — add protien tracking maybe??
```

**In Cowork:**

> **You:** Process my inbox.
>
> **Claude:** Found 3 entries.
>
> **#1** is a bug report about the rest timer — matches an issue we already seeded from your PROJECT_PLAN (issue #N: "Rest timer local notification when app backgrounded"). I'll add a comment noting you hit this in the wild, and archive the entry. OK?
>
> **#2** is a feature idea. Proposed issue:
> - Title: `[Feature]: Show yesterday's total volume on Home tab`
> - Labels: `type:feature`, `priority:P2-later`, `area:ui-polish`
> - Area dropdown: I'm guessing `ui-polish` — could also be `progress`. Which fits better?
>
> **#3** is scope-adjacent. Protein tracking is food/nutrition — that's arguably a separate app, not LiftOS. Want me to:
> (a) open a "discussion" issue to capture the thought for later debate,
> (b) archive it without an issue, or
> (c) something else?

---

## Part 4 — Connecting Cowork to the inbox file

Because the inbox lives in iCloud Drive (not inside the repo), Claude needs a way
to read it. You have three options:

1. **Point Cowork's workspace folder at iCloud temporarily.** When you want to process,
   switch the Cowork workspace to `~/Library/Mobile Documents/com~apple~CloudDocs/LiftOS/`.
   Claude reads + archives directly. When done, switch back to the repo. *(Cleanest,
   Claude can write to the files.)*

2. **Copy-paste into chat.** Open `inbox.md` on your Mac, copy all, paste into Cowork
   with "process this." Claude reads, you archive manually afterward.
   *(Works without switching workspaces.)*

3. **Symlink inbox.md into the repo** (advanced):
   ```bash
   ln -s "$HOME/Library/Mobile Documents/com~apple~CloudDocs/LiftOS/inbox.md" \
         "$HOME/path/to/LiftOS-2.0/.inbox.md"
   echo ".inbox.md" >> .gitignore
   echo ".inbox-archive.md" >> .gitignore  # if you also symlink the archive
   ```
   Then Claude reads `.inbox.md` inside the mounted repo, no workspace switching needed.
   *(Best UX long-term, slight setup complexity.)*

Start with option 2 today. Upgrade to option 1 or 3 once you're sure the capture
habit sticks.

---

## Why this design?

- **Separation of concerns.** Capture is fast + sloppy. Processing is slow + structured. One tool per job.
- **Plain text.** Works forever, survives every tool migration, greppable.
- **Human in the loop.** Claude never silently creates issues. You approve each one. This keeps your backlog signal-to-noise high.
- **Preserves context.** The archive file keeps your raw thought next to the polished issue number, which is surprisingly useful months later when you're wondering why an issue exists.

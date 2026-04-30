# Demo Video Script and Checklist

**Status date:** April 29, 2026
**Target file:** `Team34_Omnilore_Scheduler_D7_Demo.mp4` (in this folder)
**Target length:** ~6 minutes (within the spec's 4–8-minute window)
**Recording target:** 1080p, clear voice audio, on-screen reading speed (no rapid clicking)

This is a shot-by-shot script for the final demo video. Read the script with screen-share running. Times are approximate and assume a steady reading pace. The sample data are the canonical fixtures (`test/resources/course.txt`, `test/resources/people.txt`) — never use real stakeholder data.

---

## 0. Pre-recording setup (2 minutes — do *before* hitting record)

- [ ] Browser: Chrome (full `showSaveFilePicker` support) at 100% zoom.
- [ ] One clean Chrome window. Close all other tabs.
- [ ] Disable extensions that overlay the page (password manager auto-fill, ad blockers showing badges, etc.).
- [ ] Hide bookmarks bar (`Cmd-Shift-B` to toggle on macOS).
- [ ] Test microphone level (target -12 dBFS peaks). Use a wired or quality headset mic.
- [ ] Quit Slack, Discord, Mail, anything that can ding mid-take.
- [ ] Close any GitHub/AWS console tabs that might display tokens.
- [ ] On the desktop, hide files containing real PII or keys.
- [ ] Pre-load `test/resources/course.txt` and `test/resources/people.txt` into a known location (e.g., `~/Demo/`).
- [ ] Pre-write the bundled save file once (run the workflow end-to-end, save it, then revert) so the **Load** demo step works on the first take.
- [ ] Open the live site once first to warm the browser cache: http://scheduler.omnilore.org.

Recording tool suggestions: macOS Screenshot (`Cmd-Shift-5`) for full-screen capture, OBS for a more polished composite. Either is fine for D7.

---

## 1. Voiceover script (read on camera-off; show screen-share only)

### Section 1 — Context (≈ 0:00–0:40)

> "Hi, this is Team 34 from CSCI 401 — Xavier Wisniewski, Derick Walker, Andrew Chang, Aiden Yan, and Alex Wan. This is the final demo of the Omnilore Scheduling Program web migration, our deliverable 7 handoff."
>
> "Omnilore is a member-run lifelong-learning organization in Rancho Palos Verdes. Every term, members rank course preferences and declare availability. The administrators run a small Flutter app that turns those preferences into class rosters, schedules, coordinator assignments, and a mail-merge file."
>
> "When we picked up this project, the existing app was desktop-only. Our mandate was to migrate it to a web-based system, fix two longstanding bugs, add intermediate save and load, and stand up automated cloud deployment. Everything you'll see today runs at scheduler.omnilore.org, deployed automatically from GitHub Actions to AWS EC2."

> *On screen during this section:* the live site `http://scheduler.omnilore.org` open in the foreground, then briefly the GitHub repo `Omnilore-DB/Scheduler` to show the green CI badges.

### Section 2 — What we built (≈ 0:40–1:30)

Quickly point at each capability before going deep:

> "Here's what landed across deliverables 3 through 6:"
>
> "First — a Flutter web build that runs the same scheduling engine the desktop app used to run, with conditional imports keeping desktop-only code out of the web bundle. We have a static gating script that fails CI if anyone accidentally imports `dart:io` outside the allowlist."
>
> "Second — browser file loading and downloads. The user uploads `course.txt` and `people.txt` from their machine; exports use `showSaveFilePicker` where the browser supports it and fall back to normal downloads otherwise."
>
> "Third — the drop-split-schedule-coordinator pipeline. The Show Splits feature is a non-destructive preview now: admins can rebalance groups before committing. Coordinators have two explicit modes, `Set C and CC` and `Set CC1 and CC2`, both with clearing-on-reentry."
>
> "Fourth — Save, Save As, Load, autosave, and restore. A single bundled file holds the original course data, the original people data, and the entire scheduler state. One file restores the whole session."
>
> "Fifth — four export actions: an early roster, a final roster with `(C)` and `(CC)` labels, mail merge, and unmet wants. The early roster uses the phone-roster style output."
>
> "And finally — automated deployment to AWS EC2 via GitHub Actions, with temporary security-group ingress that revokes itself even if the deploy fails."

### Section 3 — End-to-end demo (≈ 1:30–5:00)

This is the bulk of the video. Walk steadily; let the screen speak.

> "Let's run a full term."
>
> "I'll load courses first." *Click File → Import Course → choose `course.txt`.* "The status indicator goes from `Need Courses` to `Need People`."
>
> "Now people." *File → Import People → choose `people.txt`.* "The overview panel populates with first choices, backups, and unmet counts. Twenty-four courses, 267 members."
>
> "We've got at least one undersize class; I'll drop it." *Open the drop control on a flagged course; confirm.*
>
> "And at least one oversize class. This is the Show Splits preview the stakeholder asked for — I'll move one person between groups, hit Cancel just to prove the cancel is non-destructive, then come back and Implement." *Open Show Splits → drag one person → Cancel → reopen → Implement.*
>
> "Schedule time. Twenty slots — five days, two terms, AM/PM. I'll assign every surviving class. Watch this slot here — if I click the same slot twice, it deselects, and the class returns to unscheduled." *Demonstrate the click-twice deselect on one slot, then re-select.*
>
> "Coordinators. One main coordinator and a co-coordinator on this class — the `(C)` and `(CC)` labels will show up in the final roster." *Set C and CC.* "And two equal co-coordinators on this one." *Set CC1 and CC2.*
>
> "We're at the output state. All exports are unlocked." *Pop open File → Export…*
>
> "Final roster — note the `(C)` and `(CC)` annotations." *Save as the suggested timestamped `final_roster_...txt`; open it in a text editor briefly.*
>
> "Mail merge — tab-delimited, one row per person, with extra columns to support up to six wanted classes." *Save and open briefly.*
>
> "Unmet wants — total unmet plus a per-person breakdown." *Save and open briefly.*
>
> "Now Save As. This produces a single bundled file with three sections — `CourseFile:`, `PeopleFile:`, and `Setting:`." *Save the bundle and open it briefly to show the three section markers.*
>
> "Refresh the page." *Refresh.* "Browser autosave offers a restore — I'll decline, then use Load to bring back the bundled save instead." *Decline restore → File → Load → choose the saved bundle.*
>
> "Everything is restored: drops, splits, schedule, coordinators." *Click around to confirm.*

### Section 4 — What's next and where the docs live (≈ 5:00–6:00)

> "What's next is the operational work. The full handoff lives in `Project_Docs_D7/` in the repo. There's a quick-start, an architecture write-up with diagrams, a deploy guide, an operations runbook, an API and data reference, a test summary, security and privacy notes, a prioritized backlog, this changelog, and the handoff checklist."
>
> "Top remaining items: the stakeholder takes over GitHub and AWS ownership, we rotate AWS keys and the EC2 SSH key, and we add TLS via Let's Encrypt in the next 30 days. Everything is documented end-to-end."
>
> "Thanks for watching — and thanks to our stakeholder Omnilore and our mentor for guiding the project. The repo is github.com/Omnilore-DB/Scheduler. The live site is scheduler.omnilore.org."

---

## 2. Recording checklist (during the take)

- [ ] Begin recording. State the project name and date in the first three seconds (useful if the take is reused).
- [ ] Browser zoom at 100%, window maximized, browser controls (URL bar) visible the whole time so viewers can see the live URL.
- [ ] Cursor visible. macOS preference: `System Settings → Accessibility → Display → Pointer size` slightly enlarged for screen capture.
- [ ] Move slowly. Pause for 1–2 seconds after each click so viewers can register the change.
- [ ] When opening files in a text editor, render at a font size visible at 1080p (≈ 18 pt).
- [ ] If a take goes wrong, finish the section and start that section over rather than stopping the whole take.

## 3. Post-production checklist

- [ ] Trim dead air at the start and end.
- [ ] Cut any takes where you fumbled.
- [ ] Normalize audio to ~ -16 LUFS (broadcast-friendly).
- [ ] Add a 1-second title card with project name + team + date (optional).
- [ ] Verify no real secrets, no real stakeholder data, and no third-party usernames are visible in any frame.
- [ ] Export 1080p H.264 MP4. Target file size < 500 MB.
- [ ] Save as `Team34_Omnilore_Scheduler_D7_Demo.mp4` in `Project_Docs_D7/`.
- [ ] Update the `Live URL / Demo video` line in `README_QuickStart.md` and `Handoff_Package_Manifest.md`.
- [ ] If linking the video instead of including the file (e.g., USC Box, Drive), use a stakeholder-controlled link, not a personal account, and note the visibility settings.

## 4. What to demo if the live site is down at recording time

If `scheduler.omnilore.org` is down when you sit down to record:

1. Open `Setup_and_Deployment_Guide.md` §9 (Rollback) on screen and explain the recovery path.
2. Run the same demo locally with `flutter run -d chrome`.
3. Verbally note that the demo is on the local build and that the deployment workflow is identical to what production runs.
4. Triage and redeploy *after* recording, then add a closing note in this document that the demo was recorded locally on `<date>`.

## 5. Alternate cuts (if stakeholder requests)

| Cut | Length | What to drop |
| --- | --- | --- |
| Quick (4 min) | Skip Section 2's overview; combine drop/split into a single example. |
| Long (8 min) | Section 2 expands to show the codebase: `lib/scheduling.dart` facade, `compute/` modules, the gating script, and the `deploy.yml` workflow. |
| Audio-only handoff podcast | Drop screen-share and walk the same script. Useful as a backup audio file. |

## 6. Sign-off line for the cover email

When the video is recorded and uploaded:

> "The Deliverable 7 demo video is at `Project_Docs_D7/Team34_Omnilore_Scheduler_D7_Demo.mp4` (or `<link>`). It walks the full pipeline at scheduler.omnilore.org using the canonical sample data, and points to `Project_Docs_D7/` for everything else."

# ChangeLog and Version History

**Status date:** April 29, 2026
**Repository:** https://github.com/Omnilore-DB/Scheduler
**Final tag (target):** `d7-final-handoff`

This is the project-level change log for CSCI 401 Team 34's 2026 contribution to the Omnilore Scheduler. For program-behavior deviations from the previous desktop application (e.g., 6-class support, mail-merge column changes), see the repository-root `CHANGES.md`.

## How to tag the final D7 release

After the stakeholder approves the handoff package, create the canonical tag:

```bash
git checkout main
git pull
git tag -a d7-final-handoff -m "CSCI 401 Team 34 — Deliverable 7 final handoff"
git push origin d7-final-handoff
```

If subsequent stakeholder edits land before the course closes, advance the tag:

```bash
git tag -fa d7-final-handoff -m "CSCI 401 Team 34 — Deliverable 7 final handoff (rev N)"
git push origin d7-final-handoff --force
```

The README, the manifest, and this changelog should reference `d7-final-handoff` once the tag exists.

## Per-deliverable history

### Deliverable 1 — Requirements and schedule (submitted 2026-01-25)

- Project assigned: USC CSCI 401 Project 34 (Omnilore).
- Team formed: Xavier Wisniewski, Derick Walker, Andrew Chang, Aiden Yan, Alex Wan.
- Requirements documented:
  1. Convert Omnilore Scheduler from desktop to web.
  2. Fix the Co-Coordinator assignment bug.
  3. Fix the Show Splits bug.
  4. Add intermediate state save/load aligned with stakeholder expectations.
  5. *(Optional, deferred)* AI-assisted scheduling — minimize unmet first choices.
- Prospective schedule for D2–D7 published.

### Deliverable 2 — Codebase review and plan (submitted 2026-02-08)

- Local environments set up; existing Flutter desktop codebase reviewed.
- Web-porting feasibility confirmed; `dart:io`, `desktop_window`, and OS file dialogs identified as the conversion blockers.
- Task breakdown and per-developer assignments finalized.
- Working notes: `docs/deliverable2_codebase_review.md`, `docs/platform_gating_rules.md`.

### Deliverable 3 — Web migration begins (submitted 2026-02-22)

- First Flutter Web build runs.
- Conditional-import pattern adopted for I/O, downloads, autosave, and window sizing (`*_factory.dart` + `*_stub.dart` + `*_io.dart` / `*_web.dart` triples).
- `scripts/check_platform_gating.sh` introduced as a static guard; matched by `test/platform_gating_test.dart`.
- Initial CI (`.github/workflows/test.yml`) introduced: gating check + analyze + test.
- Working notes: `docs/deliverable3_progress_update.md`.

### Deliverable 4 — Bug fixes and intermediate state (submitted 2026-03-08)

- **Save / Save As / Load / Autosave / Restore** implemented.
  - Bundled save format introduced (`CourseFile:` + `PeopleFile:` + `Setting:`).
  - Browser `localStorage` autosave with debounce; six keys defined.
  - Restore prompt on app open.
- **Show Splits preview** workflow shipped: non-destructive preview with manual rebalancing, Cancel, Implement.
- **Co-Coordinator** investigation: integration tests pass through coordinator → output; final defect closure validated in D5.
- Test suite grew to ~13 test files; ~1,900 LOC of test coverage.
- Repository-state baseline at submission: commit `f191326`.
- Working notes: `docs/deliverable4_fact_set.md`, `docs/deliverable4_progress_update.md`.

### Deliverable 5 — Stabilization and AWS prep (submitted 2026-04-05)

- **Coordinator workflow corrected.** `Set C and CC` and `Set CC1 and CC2` now clear stale highlights on re-entry; tap a highlighted name to clear an assignment.
- **Equal-coordinator export** corrected: both names get the `(CC)` label in the final roster.
- **Schedule recomputation** corrected: class-size and availability counts now refresh after scheduling and drop events.
- Persistence regressions verified absent after the above changes.
- Test suite stabilized at 57 passing tests on commit `c814861`.
- AWS deployment preparation begun (initial discussions with Al Ortiz, account access secured).
- Working notes: `docs/deliverable5_info_set.md`, `docs/deliverable5_work_division.{html,pdf,txt}`.

### Deliverable 6 — Feature finalization and AWS deployment (submitted 2026-04-19)

- **Schedule deselection** shipped: clicking the same time slot a second time unschedules.
- **Unmet-wants export** shipped (per-person Wants/Unmet/Assigned blocks; .txt artifact).
- **Filename-on-export consistency**: `early_roster_YYYY-MM-DD_HHMM.txt`, `final_roster_YYYY-MM-DD_HHMM.txt`, `mail_merge_YYYY-MM-DD_HHMM.txt`, `unmet_wants_YYYY-MM-DD_HHMM.txt` all route through the unified `exportTextFile()` helper and `defaultExportFilename()`. Web exports now open `showSaveFilePicker` where supported and fall back to a normal download otherwise.
- **AWS deployment automation** shipped: `.github/workflows/deploy.yml` builds the web target, briefly opens runner-IP SSH ingress on `AWS_SG_ID`, SCPs `build/web/*` to `/var/www/html` on `EC2_HOST`, and revokes the ingress with `if: always()`.
- D6 final-state validation: `flutter analyze` (pass), `flutter test` (pass), `flutter build web --release` (pass with non-blocking advisories).

### Deliverable 7 — Handoff (this submission, due 2026-05-03)

- **Project_Docs_D7/** comprehensive handoff package created (this folder), including:
  - `README_QuickStart.md`, `.env.example`
  - `System_Overview_and_Architecture.md` with PNG/SVG diagrams
  - `Setup_and_Deployment_Guide.md`
  - `Operations_Runbook.md`
  - `API_and_Data_Reference.md`
  - `Testing_and_QA_Summary.md`
  - `Security_Privacy_Accessibility_UX_Notes.md`
  - `Backlog_Known_Issues_Roadmap.md`
  - `ChangeLog_and_Version_History.md` (this file)
  - `Demo_Video_Script_and_Checklist.md`
  - `Handoff_Checklist_and_Verification_Log.md`
  - `Handoff_Package_Manifest.md`
  - `Stakeholder_Email_Cover_Note.md`
- **Live URL** confirmed: http://scheduler.omnilore.org.
- **Demo video** scripted (recording is the remaining D7 work).
- **Final tag** `d7-final-handoff` to be created after stakeholder sign-off.
- **D7 docs reconciliation**: handoff documentation aligned with official `origin/main` (initial alignment at commit `624c6c9`; reconciled after PR #9 merged at `8a38334`); test count updated to 21 files / 90 passing tests; timestamped export filenames and current export menu behavior documented.
- Outstanding handoff items (ownership transfer, key rotation, monitoring) listed in `Backlog_Known_Issues_Roadmap.md` §P0 / §P1.

## Behavior changes vs. the previous desktop application

For program-level deviations (input encoding, splitting/dropping interplay, coordinator UX, mail-merge column count, intermediate-state file format), see the repository-root `CHANGES.md`. Key items captured there:

- **Input files** must be UTF-8; up to 6 wanted classes (was 3).
- **Splitting and dropping** can now be performed interchangeably; split controls are scoped to the resulting class row only.
- **Coordinator UX** uses two explicit modes (`Set C and CC`, `Set CC1 and CC2`) with clearing-on-reentry semantics and tap-to-clear.
- **Save/load** uses a readable, editable, single-file bundle.
- **Mail-merge** has nine extra columns per row to accommodate >3 wanted classes.

## Repository revisions of note

| Tag / commit | Stage | Notes |
| --- | --- | --- |
| `f191326` | D4 baseline | Save/load + autosave landed. |
| `c814861` | D5 baseline | 57 tests passing; coordinator and recomputation fixes landed. |
| (D6 baseline) | AWS deploy + filename consistency landed. |
| `d7-final-handoff` *(target)* | D7 final | Tag once stakeholder approves. |

## How to write a new entry

When a new feature lands post-handoff, append an entry under a new heading **dated and one-line-summarized**, in the same shape as the D4–D6 entries above. Keep the repository-root `CHANGES.md` for end-user-visible behavior changes; keep this file for project-level milestones.

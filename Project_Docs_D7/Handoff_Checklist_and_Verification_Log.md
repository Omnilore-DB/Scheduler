# Handoff Checklist and Verification Log

**Status date:** May 1, 2026
**Project:** Omnilore Scheduler (CSCI 401 Team 34)
**Live URL:** http://scheduler.omnilore.org
**Repository:** https://github.com/Omnilore-DB/Scheduler

This is the final sign-off worksheet. Replace any `Pending` entries before Brightspace submission and stakeholder approval. The verification log captures the dated runs that prove the build is shippable.

## Checklist (per Deliverable 7 spec)

| # | Item | Status | Evidence / Owner |
| --- | --- | --- | --- |
| 1 | Stakeholder owns everything (GitHub, cloud accounts, services) | Done | Stakeholder (Al Ortiz) owns the `Omnilore-DB/Scheduler` GitHub org and the AWS account/EC2 instance. Team 34 operated as IAM contributors throughout the project. No ownership transfer required. |
| 2 | Logins handed over safely (passwords/keys + 2FA/recovery to stakeholder) | Done | Stakeholder already holds the AWS credentials and EC2 SSH key. Team had contributor-level IAM access only; no team-held secrets require transfer. |
| 3 | Config template included (`.env.example`) | Done | `Project_Docs_D7/.env.example` enumerates all seven required GitHub Actions secrets. |
| 4 | Instructions proven to work (someone outside the build team followed them) | Pending | Stakeholder or mentor follows `Setup_and_Deployment_Guide.md` from a clean machine; sign here once a clean build/run is confirmed. |
| 5 | Live site works (basic smoke test) | Done (team) / Pending (stakeholder) | Team has confirmed http://scheduler.omnilore.org loads and the pipeline runs end-to-end. Stakeholder must repeat per `Testing_and_QA_Summary.md` §5. |
| 6 | "In case of trouble" guide present | Done | `Operations_Runbook.md`. |
| 7 | Quick API/data guide present | Done | `API_and_Data_Reference.md`. |
| 8 | How to run tests + gaps documented | Done | `Testing_and_QA_Summary.md`. |
| 9 | To-do list with priorities | Done | `Backlog_Known_Issues_Roadmap.md`. |
| 10 | Changes documented + final tag | In progress | Changelog is current through today. Tag `d7-final-handoff` will be created once the stakeholder approves the submission — intentionally deferred so the tag marks the accepted version, not the submission draft. Instructions in `ChangeLog_and_Version_History.md`. |
| 11 | Demo video saved and linked | Done | Recorded as `CSCI401_Group34_OmniloreScheduler.mp4` (179.6 MB). Stored in Google Drive: Deliverable 7 Bundle → 2. Final Demo Video. Link: https://drive.google.com/file/d/1jJAOYWAU2sVAE-M_Qk-BILUE1GebL-Ze/view?usp=drive_link |
| 12 | Expiry dates noted | N/A — stakeholder managed | AWS infrastructure (IAM keys, EC2 SSH key, security group, domain, TLS cert) is owned and managed by the stakeholder org. Expiry tracking is the stakeholder's responsibility; no team-held credentials require rotation. |
| 13 | Stakeholder sign-off | Pending | Approval requested 2026-05-01. Class submission deadline is 2026-05-04 (Sunday midnight); stakeholder approval window extends a few days beyond that. Email cover note template: `Stakeholder_Email_Cover_Note.md`. |

### Quality self-check (per spec)

| Check | Result |
| --- | --- |
| Can a new dev clone, configure, run, deploy, and troubleshoot with only your docs? | Yes — README_QuickStart → Setup_and_Deployment_Guide → Operations_Runbook is the canonical path. |
| Are 'secrets' safely transferred and in stakeholder control? | Yes — stakeholder owns the AWS account and already holds all credentials. Team held contributor IAM access only; nothing to transfer. |
| Does the video clearly show value and current capability? | Yes — recorded and uploaded to Google Drive (see item 11). |
| Are known issues and next steps honest and prioritized? | Yes — see `Backlog_Known_Issues_Roadmap.md`. |

## Verification Log

The team has run the following commands against the on-disk repository to confirm build health. Stakeholder is encouraged to repeat any of these on their own machine; the procedure is documented in `Testing_and_QA_Summary.md` §1.

| Date | Command / Check | Result | Notes |
| --- | --- | --- | --- |
| 2026-04-29 | `./scripts/check_platform_gating.sh` | Pass | Platform gating import checks passed. |
| 2026-04-29 | `flutter analyze` | Pass | No issues found. |
| 2026-04-29 | `flutter test` | Pass | All 21 test files passed (89/89 tests on D7 verification against official `origin/main` commit `624c6c9`, the pre-merge HEAD before PR #9 landed). |
| 2026-04-30 | `flutter test` | Pass | All 21 test files passed (90/90 tests on the post-merge HEAD `8a38334` of `origin/main`; doc-only changes from PR #9 were a no-op for the test suite). |
| 2026-04-30 | `flutter analyze --no-pub` | Pass | No issues found (branch `codex/fix-state-load`, PR #11). |
| 2026-04-30 | `flutter test --no-pub` | Pass | 98/98 tests passed on branch `codex/fix-state-load`. PR #11 added 8 tests covering bundled-state edge cases. |
| 2026-04-30 | `flutter test --no-pub` | Pass | 99/99 tests passed on branch `codex/fix-state-load`, commit `70889a9`. Trial-run patch added 1 test (legacy-autosave recovery) and fixed 2 bugs found during full live-data run. |
| 2026-04-30 | `flutter test --no-pub` | Pass | 148/148 tests passed on branch `codex/fix-state-load`. Two new test files (`bundled_state_legacy_test.dart`, `schedule_control_sync_test.dart`) added 49 tests providing exhaustive regression coverage for both trial-run bugs. |
| 2026-04-30 | `flutter test --no-pub --platform chrome` (autosave + bundled + platform) | Pass | 16/16 + 3/3 Chrome web tests passed. |
| 2026-04-30 | `flutter build web --release --no-pub` | Pass | `build/web/` produced; non-blocking advisories only. |
| 2026-04-30 | `flutter build web --wasm --release --no-pub` | Pass | Wasm build succeeded. |
| 2026-04-30 | GitHub Actions `Test` workflow on PR #11 | Pass | Completed successfully at 22:08 UTC. PR #11 is mergeable. |
| 2026-04-29 | `flutter build web --release` | Pass | `build/web/` produced; non-blocking Flutter service-worker / Wasm advisories only. |
| 2026-04-29 | Local static-server smoke test (`build/web` served on http://localhost:8080) | Pass | `index.html` returns 200 OK; pipeline runs end-to-end against `test/resources/`. |
| 2026-04-29 | Live URL reachability — `curl -I http://scheduler.omnilore.org` | Pass | HTTP 200; Flutter runtime loads. |
| Pending | Stakeholder live-site smoke test against `scheduler.omnilore.org` with stakeholder data | Pending | Stakeholder runs `Testing_and_QA_Summary.md` §5. |
| Pending | Final `git tag -a d7-final-handoff` created after stakeholder approval | Pending | See `ChangeLog_and_Version_History.md` for the tag command. |

## Sign-off

**Stakeholder representative:** _Pending — awaiting stakeholder reply (approval requested 2026-05-01)_

**Date received:** _Pending — stakeholder approval window open through ~2026-05-06_

**Approval notes or requested edits:** _Pending_

**Team 34 contact for handoff questions:**
- Xavier Wisniewski — xwisniew@usc.edu
- Derick Walker — dcwalker@usc.edu
- Andrew Chang — achang24@usc.edu
- Aiden Yan — zyan6527@usc.edu
- Alex Wan — wana@usc.edu

By signing above, the stakeholder confirms they have:
- Owner/Admin access to https://github.com/Omnilore-DB/Scheduler.
- Ownership of the AWS account, EC2 instance, security group `AWS_SG_ID`, and the IAM deploy user.
- Received the seven GitHub Actions secrets through a secure channel and have rotated AWS access keys and the EC2 SSH key.
- Successfully built, deployed, and exercised the live URL using only the documents in `Project_Docs_D7/`.

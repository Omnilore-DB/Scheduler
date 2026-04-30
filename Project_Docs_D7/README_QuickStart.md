# Omnilore Scheduler — D7 Quick Start

**Project:** Omnilore Scheduling Program — Web-Based System
**Team:** CSCI 401 Team 34 (Xavier Wisniewski, Derick Walker, Andrew Chang, Aiden Yan, Alex Wan)
**Stakeholder:** Omnilore (lifelong-learning organization, Rancho Palos Verdes, CA)
**Status date:** April 29, 2026
**Live URL:** http://scheduler.omnilore.org
**Repository:** https://github.com/Omnilore-DB/Scheduler
**Final tag (target):** `d7-final-handoff` (created after stakeholder sign-off)

## Purpose

Omnilore administrators use this app to convert two text files — a **course offerings file** and a **member preferences file** — into a complete term schedule: dropped/split classes, time-slot assignments, coordinator assignments, and four export artifacts (early roster, final roster, mail-merge, unmet wants). Team 34's 2026 contribution migrated the previous desktop-only Flutter app into a browser-deployable web application, fixed two stakeholder-reported defects (Co-Coordinator and Show Splits), added save/load of intermediate state, and stood up automated AWS deployment.

## Stack (one line)

Flutter 3.41.0 stable (Dart), client-side scheduling engine, browser file picker + `showSaveFilePicker`, browser `localStorage` autosave, GitHub Actions CI/CD, AWS EC2 static hosting at `/var/www/html`.

## 5-Step Local Run

```bash
# 1. Verify toolchain (Flutter 3.41.0 stable)
flutter doctor

# 2. Clone and enter
git clone https://github.com/Omnilore-DB/Scheduler.git
cd Scheduler

# 3. Install dependencies and run platform-gating check
flutter pub get
./scripts/check_platform_gating.sh

# 4. Lint and test
flutter analyze
flutter test

# 5. Run the web app
flutter run -d chrome
```

Smoke-test inputs are bundled at `test/resources/course.txt` (24 courses) and `test/resources/people.txt` (267 people).

## 5-Step Deploy

```bash
# 1. Confirm the seven GitHub Actions secrets are set (see .env.example)
#    AWS_ACCESS_KEY_ID  AWS_SECRET_ACCESS_KEY  AWS_REGION  AWS_SG_ID
#    EC2_HOST  EC2_USERNAME  EC2_SSH_KEY

# 2. Open a PR from your feature branch into main; CI runs test.yml
#    (platform_gating + analyze + test must pass).

# 3. Merge to main. .github/workflows/deploy.yml fires automatically.
#    The job: builds web → whitelists runner IP in AWS_SG_ID → SCPs
#    build/web/* to /var/www/html on EC2_HOST → revokes the IP.

# 4. Tail the GitHub Actions run; verify each step is green.

# 5. Smoke-test the live URL
open http://scheduler.omnilore.org
#    Load test/resources/course.txt + people.txt → run drop/split/schedule
#    → assign coordinators → export all four files → Save As → reload → Load.
```

## Document Map

| Document | What it covers |
| --- | --- |
| [`README_QuickStart.md`](README_QuickStart.md) | This page. |
| [`.env.example`](.env.example) | Names of the seven GitHub Actions secrets needed for deploy. |
| [`System_Overview_and_Architecture.md`](System_Overview_and_Architecture.md) | Problem, audience, features, architecture/data-flow diagrams, design choices, limits. |
| [`Setup_and_Deployment_Guide.md`](Setup_and_Deployment_Guide.md) | Prereqs, env vars, local run, build, CI, deploy walkthrough, smoke test, rollback. |
| [`Operations_Runbook.md`](Operations_Runbook.md) | Monitoring, common incidents, backup/restore, key rotation, scaling, expirations. |
| [`API_and_Data_Reference.md`](API_and_Data_Reference.md) | Input/output file formats, scheduler-state grammar, time-slot index map, localStorage keys, public Dart surface. |
| [`Testing_and_QA_Summary.md`](Testing_and_QA_Summary.md) | What's tested (21 test files, 89 passing tests on the latest D7 verification run), how to run, manual QA script, known gaps. |
| [`Security_Privacy_Accessibility_UX_Notes.md`](Security_Privacy_Accessibility_UX_Notes.md) | Threat model, secrets handling, PII in exports, a11y/UX recommendations. |
| [`Backlog_Known_Issues_Roadmap.md`](Backlog_Known_Issues_Roadmap.md) | Prioritized backlog (P0 handoff → P3 a11y), known issues. |
| [`ChangeLog_and_Version_History.md`](ChangeLog_and_Version_History.md) | D1–D7 history, semantic-version-style entries, tagging. |
| [`Demo_Video_Script_and_Checklist.md`](Demo_Video_Script_and_Checklist.md) | Shot-by-shot voiceover script, recording checklist, post-production notes. |
| [`Handoff_Checklist_and_Verification_Log.md`](Handoff_Checklist_and_Verification_Log.md) | Sign-off worksheet + dated verification log. |
| [`Handoff_Package_Manifest.md`](Handoff_Package_Manifest.md) | Everything that ships in the Brightspace ZIP. |
| [`Stakeholder_Email_Cover_Note.md`](Stakeholder_Email_Cover_Note.md) | Cover note template for the handoff email. |
| [`diagrams/`](diagrams/) | Architecture, data-flow, and state-machine diagrams (PNG + SVG). |

## Demo Video

The recorded walkthrough should be saved as `Team34_Omnilore_Scheduler_D7_Demo.mp4` in `Project_Docs_D7/` and linked here once recorded. The shot-by-shot script lives in [`Demo_Video_Script_and_Checklist.md`](Demo_Video_Script_and_Checklist.md). Length target: 6 minutes (within the 4–8-minute spec).

## Where things live

| You want to… | Look at |
| --- | --- |
| Run the app | `lib/main.dart` → `lib/widgets/screen.dart` |
| Understand the pipeline | `lib/scheduling.dart` (facade, 809 LOC) |
| Change splitting rules | `lib/compute/split_control.dart` (John Taber's algorithm) |
| Change drop / class-size rules | `lib/compute/course_control.dart` |
| Add a new export | `lib/io/export_text_file.dart`, `lib/io/default_filename.dart`, + a method on `Scheduling` |
| Add a web-only API safely | Use the `*_factory.dart` + `*_stub.dart` + `*_io.dart`/`*_web.dart` triple; then add it to `scripts/check_platform_gating.sh` |
| See real test inputs | `test/resources/course.txt`, `test/resources/people.txt` |
| Read the deploy wiring | `.github/workflows/deploy.yml` |

## What's *not* in this repo (handed off separately)

Real AWS access keys, the EC2 SSH private key, and any production stakeholder data. These move through the stakeholder-approved secure channel, not email or the repository. See [`Operations_Runbook.md`](Operations_Runbook.md) §Key Rotation for the rotation procedure.

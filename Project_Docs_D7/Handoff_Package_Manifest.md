# Handoff Package Manifest

**Status date:** April 29, 2026
**Project:** Omnilore Scheduler — Web-Based System
**Team:** CSCI 401 Team 34 (Xavier Wisniewski, Derick Walker, Andrew Chang, Aiden Yan, Alex Wan)
**Live URL:** http://scheduler.omnilore.org
**Repository:** https://github.com/Omnilore-DB/Scheduler

This manifest enumerates everything that ships with Deliverable 7. Use it as the receipt for the Brightspace ZIP and the stakeholder handoff email.

## What's in this folder (`Project_Docs_D7/`)

### Markdown sources

| File | Purpose |
| --- | --- |
| `README_QuickStart.md` | One-page quick start: live URL, 5-step run, 5-step deploy, document map. |
| `.env.example` | The seven GitHub Actions secrets the deploy workflow needs. |
| `System_Overview_and_Architecture.md` | Problem, audience, features, architecture/data-flow diagrams, design choices, limits. |
| `Setup_and_Deployment_Guide.md` | Prereqs, env vars explained, local run, build, CI, deploy walkthrough, smoke test, rollback. |
| `Operations_Runbook.md` | Monitoring, common incidents, backup/restore, key rotation, scaling, expirations, recovery checklist. |
| `API_and_Data_Reference.md` | Input/output file formats, scheduler-state grammar, time-slot index reference, browser localStorage keys, public Dart surface. |
| `Testing_and_QA_Summary.md` | What's tested (21 files, 89 passing tests on the latest D7 verification run), how to run, manual QA script, known gaps. |
| `Security_Privacy_Accessibility_UX_Notes.md` | Threat model, secrets handling, PII in exports, a11y/UX recommendations. |
| `Backlog_Known_Issues_Roadmap.md` | Prioritized backlog (P0 handoff → P3 a11y) and known issues. |
| `ChangeLog_and_Version_History.md` | D1–D7 history; how to tag the final release. |
| `Demo_Video_Script_and_Checklist.md` | Shot-by-shot voiceover script, recording checklist, post-production notes. |
| `Handoff_Checklist_and_Verification_Log.md` | Sign-off worksheet + dated verification log. |
| `Handoff_Package_Manifest.md` | This file. |
| `Stakeholder_Email_Cover_Note.md` | Cover email template for the stakeholder + cc'd mentor. |

### Rendered PDFs (one per Markdown doc that the spec calls out as `.pdf`)

| File | Source |
| --- | --- |
| `System_Overview_and_Architecture.pdf` | from the corresponding `.md` |
| `Setup_and_Deployment_Guide.pdf` | from the corresponding `.md` |
| `Operations_Runbook.pdf` | from the corresponding `.md` |
| `API_and_Data_Reference.pdf` | from the corresponding `.md` |
| `Testing_and_QA_Summary.pdf` | from the corresponding `.md` |
| `Security_Privacy_Accessibility_UX_Notes.pdf` | from the corresponding `.md` |
| `Backlog_Known_Issues_Roadmap.pdf` | from the corresponding `.md` |
| `Demo_Video_Script_and_Checklist.pdf` | from the corresponding `.md` |
| `Handoff_Checklist_and_Verification_Log.pdf` | from the corresponding `.md` |
| `Handoff_Package_Manifest.pdf` | from the corresponding `.md` |
| `Stakeholder_Email_Cover_Note.pdf` | from the corresponding `.md` |

`README_QuickStart.md`, `.env.example`, and `ChangeLog_and_Version_History.md` are markdown-only per the spec's filename guidance.

### Diagrams

| File | Purpose |
| --- | --- |
| `diagrams/architecture.svg` / `architecture.png` | System architecture (UI → Facade → Compute → Stores → IO + CI/CD). |
| `diagrams/data_flow.svg` / `data_flow.png` | Data flow from input files through the pipeline to the export actions + bundled save. |
| `diagrams/state_machine.svg` / `state_machine.png` | `StateOfProcessing` pipeline with branch states. |

### Demo video

| File | Status |
| --- | --- |
| `Team34_Omnilore_Scheduler_D7_Demo.mp4` (or stakeholder-approved link) | Pending — recording workflow in `Demo_Video_Script_and_Checklist.md`. Update README + this manifest once filmed. |

## What's in the source repository (https://github.com/Omnilore-DB/Scheduler)

| Path | Notes |
| --- | --- |
| `lib/` | Application code (~6,500 Dart LOC across compute/model/store/io/widgets). |
| `test/` | 21 Dart test files (+ `test_util.dart`). Canonical fixtures in `test/resources/`. |
| `.github/workflows/test.yml` | CI: gating + analyze + test on PR/push to `main`. |
| `.github/workflows/deploy.yml` | CD: builds web → SCP to `/var/www/html` on EC2. |
| `scripts/check_platform_gating.sh` | Static guard against `dart:io` / desktop-only imports outside the allowlist. |
| `pubspec.yaml`, `pubspec.lock` | Dependency manifests; pinned to Flutter 3.41.0 stable. |
| `analysis_options.yaml` | Lints (Flutter recommended set + `prefer_single_quotes`). |
| `CHANGES.md` | End-user-visible behavior changes vs. the previous desktop app. |
| `README.md` | Top-level repo readme; points at `Project_Docs_D7/`. |
| `docs/` | Earlier-deliverable working notes (`deliverable2_codebase_review.md`, `platform_gating_rules.md`, etc.). |
| `Project_Docs_D7/` | This handoff folder. |

## What's in the Brightspace submission

A single ZIP (or top-level link) containing:

1. `Project_Docs_D7/` (this folder, complete with PDFs and diagrams).
2. `Team34_Omnilore_Scheduler_D7_Demo.mp4` (or a stakeholder-approved link, embedded in README and this manifest).
3. The repo URL: https://github.com/Omnilore-DB/Scheduler.
4. The completed checklist (`Handoff_Checklist_and_Verification_Log.md` / `.pdf` with signatures replacing the `Pending` rows).

## What's *not* in the repository (handed off separately and securely)

These move through a stakeholder-approved secure channel — never email, chat, or commit:

- Real `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for the deploy IAM user.
- Real `EC2_SSH_KEY` (the full PEM contents).
- The deploy IAM user's console login + recovery codes (if applicable).
- Any SSH config files that include the EC2 host alias on a developer's machine.
- Any Omnilore production member data ever used for live testing.

## Final-tag plan

After stakeholder sign-off:

```bash
git tag -a d7-final-handoff -m "CSCI 401 Team 34 — Deliverable 7 final handoff"
git push origin d7-final-handoff
```

Then update `README_QuickStart.md` (in the repo and this folder) to reference the tag.

## Trial / credit / expiration notes

No free trials, student credits, sandbox accounts, or temporary tokens are required for production operation. The deploy workflow uses the stakeholder's standing AWS account. See `Operations_Runbook.md` §10 for the expirations table the stakeholder must keep current.

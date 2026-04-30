# Setup and Deployment Guide

**Status date:** April 29, 2026
**Live URL:** http://scheduler.omnilore.org
**Repository:** https://github.com/Omnilore-DB/Scheduler

This guide takes a brand-new developer from a clean machine to a green deploy. Every command is copy-pastable. Browser-specific quirks are called out where they matter.

## 1. Prerequisites

| Tool | Version | Why |
| --- | --- | --- |
| Flutter | **3.41.0 stable** (matches `subosito/flutter-action@v2` pin in CI) | Build, test, run, build-web. |
| Dart | Bundled with Flutter (do not install separately) | Language. |
| Git | Recent (>=2.30) | Clone + push. |
| Chrome (or Chromium-based browser) | Recent | `flutter run -d chrome` and the live site. |
| GitHub account | — | Repo + Actions secrets. |
| AWS account access | — | Required only for deploy: read/write on the EC2 instance, the security group `AWS_SG_ID`, and IAM for the deploy user. |
| (Optional) macOS / Linux / Windows desktop toolchain | — | Only needed if you want a native desktop build; the web build is the production target. |

Verify Flutter:

```bash
flutter --version          # expect: Flutter 3.41.0 • channel stable
flutter doctor             # resolve any reported issues before continuing
```

If `flutter doctor` flags a missing platform you don't intend to ship to (e.g., Android Studio, Xcode), you can ignore it; CI only exercises the web target.

## 2. Local Setup

```bash
git clone https://github.com/Omnilore-DB/Scheduler.git
cd Scheduler
flutter pub get
./scripts/check_platform_gating.sh   # must print "Platform gating import checks passed."
flutter analyze                       # 0 issues expected
flutter test                          # full suite
```

> **Tip.** If `check_platform_gating.sh` fails, it is almost always because someone added `import 'dart:io';` or `import 'package:desktop_window/desktop_window.dart';` outside the explicit allowlist. Move the import behind the matching `_factory.dart` triple instead of relaxing the script.

### Run the app locally

```bash
flutter run -d chrome             # the production target
# alternatives:
flutter run -d macos              # native desktop, if needed
flutter run -d linux
flutter run -d windows
```

`Chrome` is the recommended target while developing; the web build is what production serves.

## 3. Local Smoke Test

Use `test/resources/course.txt` and `test/resources/people.txt` (24 courses, 267 people).

1. `flutter run -d chrome`
2. **File → Import Course** → choose `course.txt`. The status indicator advances from `needCourses` to `needPeople`.
3. **File → Import People** → choose `people.txt`. The overview/stat panel populates.
4. Walk through the pipeline as the UI directs you:
   - Drop any course flagged as undersize, or change its min/max size.
   - For oversize courses, open **Show Splits**, optionally rebalance preview groups, and **Implement** or **Cancel**.
   - Open the schedule grid; assign every surviving course to a 20-slot index. Click an assigned slot a second time to **deselect** it (it should revert to unscheduled).
   - Set a `C / CC` on one course and `CC1 / CC2` on another.
5. **Export** → Early Roster, Final Roster, Mail Merge, Unmet Wants. Verify the browser save dialog (or download fallback) produces non-empty files with timestamped names.
6. **Save As** → bundled save file. Refresh the tab. The autosave/restore prompt should offer to restore. Decline; instead **Load** the bundled file you just saved.
7. Confirm the restored state preserves drops, splits, schedule, and coordinators exactly.

If any step regresses: **stop and triage before pushing**. The smoke test is the contract every release must hold.

## 4. Build for Web

```bash
flutter build web --release
```

Build output:

```text
build/web/
├── index.html
├── main.dart.js
├── flutter.js
├── manifest.json
├── assets/
└── canvaskit/
```

Non-blocking advisories may appear (service-worker / Wasm). They are safe to ignore unless they appear as `error:`.

To preview the production bundle locally (matches what EC2 serves):

```bash
cd build/web
python3 -m http.server 8080         # or any static server
open http://localhost:8080
```

## 5. Continuous Integration (`.github/workflows/test.yml`)

Triggers: push or PR to `main`. Steps:

1. `actions/checkout@v4`
2. `./scripts/check_platform_gating.sh`
3. `subosito/flutter-action@v2` with `flutter-version: 3.41.0`, `channel: stable`
4. `flutter pub get`
5. `flutter analyze`
6. `flutter test`

A failing CI run blocks merge.

## 6. Continuous Deployment (`.github/workflows/deploy.yml`)

Trigger: push to `main` (i.e., merge of an approved PR). Required GitHub Actions secrets are documented in `.env.example`. The workflow:

1. **Checkout** the repo at the merge commit.
2. **Setup Flutter** at version 3.41.0 stable.
3. `flutter pub get`.
4. `flutter build web --release` → `build/web/`.
5. **Read public IP** of the GitHub-hosted runner (`haythem/public-ip@v1.3`).
6. **Configure AWS credentials** from `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION` (`aws-actions/configure-aws-credentials@v4`).
7. **Whitelist the runner IP** by adding a temporary ingress rule on TCP/22 to security group `AWS_SG_ID`:
   ```bash
   aws ec2 authorize-security-group-ingress \
     --group-id "$AWS_SG_ID" --protocol tcp --port 22 --cidr "<runner-ip>/32"
   ```
8. **SCP build artifacts** to the EC2 host (`appleboy/scp-action@v0.1.7`):
   - `host: $EC2_HOST`, `username: $EC2_USERNAME`, `key: $EC2_SSH_KEY`
   - `source: build/web/*`, `target: /var/www/html`, `strip_components: 2`
9. **Revoke the runner IP** (runs even if step 8 fails, via `if: always()`).

The deploy job is idempotent: a clean re-run from the same commit produces the same `/var/www/html` contents.

### Per-secret reference

See `.env.example` for the seven required secrets and how to set them in `Settings → Secrets and variables → Actions`.

| Secret | Used by |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | step 6 |
| `AWS_SECRET_ACCESS_KEY` | step 6 |
| `AWS_REGION` | step 6 |
| `AWS_SG_ID` | steps 7, 9 |
| `EC2_HOST` | step 8 |
| `EC2_USERNAME` | step 8 |
| `EC2_SSH_KEY` | step 8 (full PEM contents) |

## 7. Deployment Smoke Test

Run after every deploy:

```bash
# 1. Confirm the workflow green-lit
gh run list --workflow=deploy.yml --limit 5     # if gh is installed

# 2. Hit the live URL
curl -I http://scheduler.omnilore.org           # expect HTTP/1.1 200 OK
open http://scheduler.omnilore.org

# 3. Functional smoke test (manual)
#    - Load test/resources/course.txt + people.txt
#    - Walk pipeline through to output
#    - Export early_roster_YYYY-MM-DD_HHMM.txt, final_roster_YYYY-MM-DD_HHMM.txt,
#      mail_merge_YYYY-MM-DD_HHMM.txt, unmet_wants_YYYY-MM-DD_HHMM.txt
#    - Save As → reload the page → Load the saved bundle
```

If any export is empty or the restore fails, **roll back immediately** (§9) and triage in a branch.

## 8. Database, Migrations, Seed Data

Not applicable. The application is fully client-side: no server, no DB, no migrations. Test fixtures (`test/resources/`) double as seed data:

- `course.txt` — 24-course canonical course offering.
- `people.txt` — 267-person canonical roster (synthetic-but-realistic).
- `course_split.txt`, `course_whitespace.txt`, `people_*` — edge-case inputs used by the test suite.
- `malformed_*` directories — failure-path inputs.

## 9. Rollback

There is no purpose-built rollback workflow. Choose the option that fits the situation:

| Situation | Action |
| --- | --- |
| Bad commit on `main` | `git revert <bad-sha>` → push → `deploy.yml` redeploys the reverted state. |
| Broken commit hard to revert (e.g., merge conflicts) | Force-push `main` to the last known-good commit (only if the team agrees). The deploy workflow re-runs and overwrites `/var/www/html`. |
| Flutter SDK pin moved unexpectedly | Re-pin `subosito/flutter-action@v2` to `flutter-version: 3.41.0` and re-run. |
| EC2 itself is the problem | See `Operations_Runbook.md` §Common Incidents. The current build artifacts on EC2 are the only on-disk copy, so re-running deploy from the last green commit is the canonical recovery. |

A future improvement (P1 in `Backlog_Known_Issues_Roadmap.md`) is to archive build artifacts per release (e.g., to S3) so a `/var/www/html` rollback can happen without rebuilding.

## 10. Third-Party Setup

- **GitHub.** The stakeholder must have **Owner/Admin** on `Omnilore-DB/Scheduler` and on Actions secrets. Required to manage secrets and to merge to `main`.
- **AWS.** The stakeholder owns the EC2 instance (host: `scheduler.omnilore.org`), the security group `AWS_SG_ID`, and the IAM user/role whose access keys are stored as GitHub secrets. The IAM user needs at minimum:
  - `ec2:AuthorizeSecurityGroupIngress`, `ec2:RevokeSecurityGroupIngress` on `AWS_SG_ID`.
  - SSH connectivity to the instance via `EC2_SSH_KEY` (key-pair on the instance).
  - The instance must run a static web server (today: nginx or Apache) configured to serve `/var/www/html`.
- **DNS.** `scheduler.omnilore.org` is an A record pointing at the EC2 instance's public IP (managed in Omnilore's DNS provider; Route 53 if Omnilore moves DNS to AWS).
- **No third-party SaaS** other than GitHub Actions and AWS is required to build, test, or run the application.

## 11. Switching from `http://` to `https://` (recommended)

Today the site is served over HTTP. Adding TLS does not change the application code; it changes the EC2 web-server config:

1. Issue a Let's Encrypt cert via `certbot --nginx` (or Apache equivalent) for `scheduler.omnilore.org`.
2. Confirm renewal cron is in place.
3. Update DNS only if the host changes; otherwise the cert applies to the existing A record.
4. Update `README_QuickStart.md`, `Operations_Runbook.md`, and the demo video URL to use `https://`.

This is filed as P1 in the backlog.

## 12. Quick reference

```bash
# from a clean checkout
flutter pub get
./scripts/check_platform_gating.sh
flutter analyze
flutter test
flutter run -d chrome              # local dev
flutter build web --release        # what CI deploys

# what CI does
.github/workflows/test.yml         # PR + push to main
.github/workflows/deploy.yml       # push to main → EC2

# the live site
http://scheduler.omnilore.org
```

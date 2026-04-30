# Backlog, Known Issues, and Roadmap

**Status date:** April 29, 2026

This is the prioritized list of remaining work, framed for the next developer or maintenance team. Items are grouped by priority and each has a "Why it matters" and a "Suggested next step" so the work can be picked up without re-deriving context.

## Priority 0 — Handoff blockers (must close before sign-off)

| Item | Status | Owner | Next step |
| --- | --- | --- | --- |
| Stakeholder Owner/Admin on `Omnilore-DB/Scheduler` | Pending | Stakeholder + team | Stakeholder confirms admin in GitHub repo settings; team verifies. |
| Stakeholder ownership of AWS account, EC2 instance, security group, IAM deploy user | Pending | Stakeholder + team | Stakeholder confirms billing + ownership; team rotates and hands over keys per Operations Runbook §6. |
| Final live-URL smoke test by stakeholder | Pending | Stakeholder | Run the manual QA script in Testing_and_QA_Summary.md §5 against http://scheduler.omnilore.org. |
| Demo video recorded and linked | Pending | Team 34 | Record per Demo_Video_Script_and_Checklist.md, save as `Team34_Omnilore_Scheduler_D7_Demo.mp4` in this folder, link from `README_QuickStart.md`. |
| Final release tag `d7-final-handoff` | Pending | Team 34 | Tag after stakeholder approves: `git tag -a d7-final-handoff -m "Deliverable 7 final handoff" && git push origin d7-final-handoff`. |
| Expiration table populated in Operations Runbook §10 | Pending | Stakeholder | Fill in IAM key dates, EC2 SSH key date, domain renewal date, TLS cert renewal (when added). |
| Student credentials revoked | Pending | Stakeholder | Revoke after the stakeholder confirms they can build, deploy, and access independently. |
| Stakeholder sign-off received | Pending | Stakeholder + team | Email cover note + this folder; request approval within 48–72 hours. |

## Priority 1 — Operational hardening (do within 30 days post-handoff)

| Item | Why it matters | Suggested next step |
| --- | --- | --- |
| **TLS / HTTPS** on `scheduler.omnilore.org` | Users upload PII (names, phone numbers); HTTP exposes that traffic to MITM observation. | `certbot --nginx` (or Apache equivalent) with a Let's Encrypt cert; add HSTS; update README + runbook references to `https://`. |
| Document the EC2 web-server config (nginx vs Apache, vhost path, log paths) | The runbook currently lists generic paths; on-call needs the real ones. | SSH in once, capture `/etc/nginx/sites-enabled/*` (or Apache equivalent), commit a redacted copy under `docs/ops/`. |
| Add uptime monitoring on the live URL | The site is unmonitored today; outages will surface only when an admin tries to use it. | UptimeRobot, BetterStack, or AWS Route 53 health check (alert to stakeholder email). |
| Branch protection on `main` | Prevent accidental force-push and unreviewed merges. | GitHub Settings → Branches → Protection rule for `main`: require PR review + required status checks (`test.yml`). |
| Build-artifact archival | Today rollback means rebuild; artifact archive makes rollback a copy. | Add a step to `deploy.yml` that uploads `build/web/` to `s3://omnilore-scheduler-builds/<sha>/`. |
| Dependabot on `pubspec.yaml` and Actions | Surface dependency drift as PRs. | Enable Dependabot in repo settings; set a weekly schedule. |

## Priority 2 — Product enhancements (next quarter or as stakeholder requests)

| Item | Why it matters | Suggested next step |
| --- | --- | --- |
| **Migrate hosting to S3 + CloudFront** | Eliminates EC2 patching, gives free TLS, makes rollback trivial via versioned prefixes. | Replace `deploy.yml` with `aws s3 sync build/web s3://omnilore-scheduler-prod/` + a CloudFront cache invalidation step. Decommission the EC2 instance after a soak. |
| **CSV exports** for roster, mail-merge, unmet-wants | Easier to drop into spreadsheets / Mailchimp. | Wrap the existing `outputXyzToString()` builders with a CSV serializer (header row + RFC-4180 escaping); add a `screen.dart` menu item routing through `exportTextFile()` with `.csv` suggested name. |
| Cross-browser save-dialog matrix | `showSaveFilePicker` support varies; document the user experience for each. | Manual matrix across Chrome, Edge, Safari, Firefox; capture screenshots; document fallback behavior in `Security_Privacy_Accessibility_UX_Notes.md`. |
| **Code-coverage tooling** | No coverage report today. | Add `flutter test --coverage`; convert `coverage/lcov.info` → HTML; publish artifact in `test.yml`. |
| Performance profile with stakeholder-scale data | Canonical fixture is 24/267; production may grow. | Add a `bench/` directory with synthetic 5–10× datasets; capture p50/p95 for load → split → schedule → export; document in this file. |
| Incremental autosave format | Today's autosave bundles the whole file on every change. | Diff-based or keyed-section autosave reduces `localStorage` pressure on very large datasets. |

## Priority 3 — Accessibility, polish, longer-term

| Item | Suggested next step |
| --- | --- |
| Keyboard-only audit | Walk the entire workflow with the mouse unplugged; add focus traps and tab-order fixes where needed. |
| Screen-reader labels | Add `Semantics` widgets to the schedule grid, coordinator chips, and the overview panel. Run with VoiceOver / NVDA. |
| Color contrast pass | Verify WCAG-AA on coordinator highlights, drop/split state, and overview text. |
| Larger / zoomed window QA | 125%, 150% zoom; confirm no overlap and the table is still scannable. |
| Inline file-diff helper for "inconsistent" state | When a people row references an unknown course, surface the exact diff inline rather than only in an exception message. |
| Saved-session manager | Move from "one bundled file at a time" to a per-term archive view (still client-side; uses `localStorage` namespacing). |

## Out of scope (intentionally not delivered)

- **AI-assisted scheduling.** Listed as Optional Requirement #5 in D1; deferred by stakeholder agreement to keep D2–D7 focused on stability, web migration, and ops.
- **Multi-user collaboration / real-time editing.** Would require a backend; not requested.
- **Member-facing self-service portal.** Out of scope; admin-facing tool only.

## Known issues (for transparency, not blockers)

| Issue | Symptom | Workaround | Tracked in |
| --- | --- | --- | --- |
| `showSaveFilePicker` not supported in Firefox | Save dialog never appears; file lands in browser downloads with the suggested name. | Use Chrome/Edge if a save dialog is needed; otherwise accept the download. | Operations Runbook §4 |
| Autosave is browser-profile-local | Switching browsers/profiles loses autosave. | Use Save As → Load. | README, Operations Runbook §5 |
| In-place SCP deploy | A failure mid-SCP can leave `/var/www/html` partially overwritten. | Re-run `deploy.yml` from the same green commit. | Operations Runbook §4, P1 above |
| Site served over plain HTTP | No transport encryption for uploaded PII. | Add TLS (P1 above). | Security_Privacy_Accessibility_UX_Notes.md §1 |
| AI-assisted scheduling absent | D1 listed it as optional; not delivered. | None — out of scope by stakeholder agreement. | This file, "Out of scope". |

## Where to find supporting context

- Pipeline architecture and design choices: `System_Overview_and_Architecture.md`.
- Specific exception types and their messages: `API_and_Data_Reference.md` §9.
- How to run / extend tests: `Testing_and_QA_Summary.md`.
- Per-deliverable history (D1 → D7) and tagging instructions: `ChangeLog_and_Version_History.md`.

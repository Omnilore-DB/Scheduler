# Security, Privacy, Accessibility, and UX Notes

**Status date:** April 29, 2026

The Omnilore Scheduler is a single-user, client-side tool with a thin static-hosting deployment surface. Its threat model is correspondingly narrow. This document records what is in place, what is *not* in place by design, and what the next maintainer should consider tightening.

## 1. Security

### Threat model in one paragraph

The application has no backend, no authentication, no API, and no server-side data store. The only assets worth protecting are (a) the AWS deploy credentials and EC2 SSH key, both stored in GitHub Actions secrets and rotated through the stakeholder, and (b) the EC2 host and its `/var/www/html` content. There is no user account system to attack, no session token to steal, and no PII at rest on the server. The site is currently served over plain HTTP — adding TLS is recommended (see §1.6) but does not change the security posture for application data, which never leaves the user's browser.

### 1.1 Secrets management

- **No real secrets are committed** to the repository. The only `.env`-shaped artifact in the repo is `Project_Docs_D7/.env.example`, which lists *names* of GitHub Actions secrets and is annotated to discourage misuse.
- Secrets are stored exclusively as **GitHub Actions repository secrets**. They are not visible in workflow logs (GitHub redacts them).
- Real values transfer between team and stakeholder through a **stakeholder-approved secure channel** — never email, chat history, or commit messages.
- After handoff, **rotate** AWS access keys and the EC2 SSH key (Operations Runbook §6) — student-era credentials should be treated as exposed-by-default.

### 1.2 Deploy-time access scoping

- The deploy workflow's IAM user needs only:
  - `ec2:AuthorizeSecurityGroupIngress` and `ec2:RevokeSecurityGroupIngress` on `AWS_SG_ID`.
  - SSH connectivity to the EC2 instance via `EC2_SSH_KEY`.
- The workflow opens port 22 to a **single runner IP** (`/32` CIDR) only for the duration of the SCP step. It explicitly revokes the rule with `if: always()` to handle failure paths.
- A future improvement (Backlog P1) is to move from in-place SCP-to-EC2 to publishing artifacts to S3 + CloudFront, eliminating the temporary SSH ingress entirely.

### 1.3 Code supply chain

- All third-party dependencies live in `pubspec.yaml`. The notable ones for security review are `desktop_window`, `rflutter_alert`, `english_words`, `multilevel_drawer`, `flutter_menu`, `file_picker`, `tuple`, and `web` (browser DOM bindings).
- GitHub Actions third-party actions in use: `actions/checkout@v4`, `subosito/flutter-action@v2`, `haythem/public-ip@v1.3`, `aws-actions/configure-aws-credentials@v4`, `appleboy/scp-action@v0.1.7`. These are pinned to major versions in the workflow files.
- Recommended: enable Dependabot on `pubspec.yaml` and on `.github/workflows/*.yml` so dependency drift surfaces as PRs.

### 1.4 Input validation

The two parsers (`lib/store/courses.dart` and `lib/store/people.dart`) reject malformed input fast and **clear in-memory state** on any failure — partial loads cannot leak through. The exception list (`lib/model/exceptions.dart`) covers wrong column counts, duplicate codes, invalid availability values, duplicate selections, references to unknown courses, etc. The parsers do not execute or interpret input strings; they only split on tabs and parse small integers.

### 1.5 Browser security posture

- The page is a single-page Flutter web bundle. There is no inline `<script>` execution beyond Flutter's own runtime.
- No third-party trackers, analytics scripts, or ad networks are loaded.
- No cookies are set; all session state lives in `localStorage` keys explicitly enumerated in `API_and_Data_Reference.md` §8.
- Flutter Web's default service worker is built into the production output. The application does not rely on the service worker for security; it is only used for offline asset caching.

### 1.6 Recommended hardening (filed in backlog)

- **TLS / HTTPS** via Let's Encrypt + certbot on the EC2 web server. The site is currently HTTP; users uploading PII-bearing files (names, phone numbers) deserve at least transport encryption. Setup_and_Deployment_Guide.md §11 has the procedure.
- **Content Security Policy** header on the web server, scoped to `'self'` plus whatever Flutter's runtime needs. Flutter Web is comfortable with a moderately strict CSP.
- **HSTS** once HTTPS is in place.
- **Dependabot or equivalent** on the repo.
- **GitHub branch protection** on `main` (require PR review, required status checks, no force-push) once the stakeholder takes over admin.

## 2. Privacy

### 2.1 What data is processed

The only data the application touches is what the admin uploads from their own machine: a course offerings file and a member preferences file. The people file contains:

- First name, last name (PII)
- Phone number (PII)
- Number of classes wanted (preference)
- Availability across 20 time slots (preference)
- First-choice and backup course codes (preference)
- Submission order (operational)

Course material identifiers (book titles, etc.) are not personal data.

### 2.2 Where the data lives

| Location | What | When it leaves |
| --- | --- | --- |
| User's machine | The original `course.txt` and `people.txt` | Never — the user controls these. |
| Browser tab memory | Parsed `Course` and `Person` objects, scheduling state | Cleared on tab close. |
| Browser `localStorage` | `omnilore_autosave`, `omnilore_hardsave`, the course/people text caches, ISO timestamps | Cleared on tab data clear, browser uninstall, or explicit "clear site data". Never sent to a server. |
| User-saved bundle file | The exact original course/people file contents plus the scheduler state grammar | Wherever the user saves it — the user is in control. |
| Exported rosters / mail-merge / unmet wants | Names + phone numbers + assignments | Wherever the user saves them. |
| EC2 server | **Nothing user-supplied.** Only the static build artifacts. | n/a — no PII reaches the server. |

There is no analytics, no telemetry, no error reporting that uploads PII. The Flutter Web service worker caches static assets; it does not transmit user data.

### 2.3 PII in exports

The four export artifacts may contain names and phone numbers and should be treated as **stakeholder-sensitive**. Operationally:

- Demo videos must use test data (`test/resources/`) or stakeholder-approved sample data only.
- Exports shared in chat or email should go through Omnilore's normal channels for member data, not student channels.
- After handoff, any student-side copies of exported files should be deleted.

### 2.4 Data retention

- The application has no retention policy because it has no backend storage.
- The user's `localStorage` autosave persists until the user clears site data or the browser evicts the entry.
- Bundled save files persist wherever the user puts them.

### 2.5 Compliance posture

- No GDPR / CCPA data controller obligations attach to the *application* (no controller-side storage). They attach to **Omnilore as the organization** that maintains the source files and the resulting rosters. That obligation pre-dates and is unchanged by this project.

## 3. Accessibility

### 3.1 What's in place

- Browser-native file dialogs and downloads (`file_picker`, `showSaveFilePicker`) — these honor the user's system-level accessibility settings.
- Scrollable name-card areas for large rosters (no truncation hiding members).
- `Set C and CC` and `Set CC1 and CC2` modes have a clear visual highlight and a clear-on-reentry semantic, so the keyboard and pointer paths are equivalent in intent.
- Schedule deselection is symmetric: the same gesture (click) selects and deselects.
- The status indicator (`StateOfProcessing`) makes the next required action visible, which serves cognitive load even if it does not yet meet WCAG-AA contrast across all themes.

### 3.2 Recommended next steps (filed P3 in backlog)

- **Keyboard-only audit** through file menu → load → drop/split → schedule → coordinators → exports. Add focus traps where the table currently relies on pointer hover. Document any keyboard shortcuts.
- **Screen-reader labels** on icon-only and color-only controls, especially the schedule grid cells (which today communicate "scheduled" via background color alone).
- **Color contrast pass** (WCAG-AA ratio ≥ 4.5:1 for text) on coordinator highlights, drop/split state, and the overview/stat panel.
- **Manual zoom test** at 125% and 150% — confirm controls don't overlap and the table remains scannable.
- **Reduced-motion** preference handling if any animations are added.

### 3.3 Mobile / small screens

The app is designed for desktop browsers. The UI assumes a wide table layout. A formal mobile responsiveness pass is out of scope of D7 and is **not** filed in the backlog as a priority — Omnilore admins use desktop. Adjust if the stakeholder later requests mobile support.

## 4. UX notes

### What landed in D4–D6 that the stakeholder explicitly asked for

- **Show Splits as preview, not commit.** Admins can move people between preview groups, cancel without consequence, and only commit on **Implement**.
- **Coordinator clearing.** Both `Set C and CC` and `Set CC1 and CC2` clear stale highlights when re-entered. Tapping a highlighted name on an assigned course clears the assignment — a fast undo path.
- **Time-slot deselect.** Click-same-slot-again unschedules.
- **Custom export filenames.** All four exports route through `exportTextFile()` so the browser's save dialog can suggest a timestamped filename (`early_roster_YYYY-MM-DD_HHMM.txt`, `final_roster_YYYY-MM-DD_HHMM.txt`, `mail_merge_YYYY-MM-DD_HHMM.txt`, `unmet_wants_YYYY-MM-DD_HHMM.txt`).
- **Bundled save / load.** One file, three sections; restores the entire session.

### Areas the next dev should watch

- **Browser save-dialog inconsistency.** Firefox does not support `showSaveFilePicker` at the time of writing; the export falls back to a download. Document the expected behavior in any user-facing tooltip if Omnilore standardizes on a non-Chrome browser.
- **Autosave is invisible by default.** Users who never reload won't see the autosave dialog. The README and Operations Runbook stress that **Save As** is the only operational backup.
- **Inconsistent state messages.** When a person references an unknown course, the user sees a "inconsistent" state with the offending code in the exception message. A future improvement is an inline diff between the two files; until then, the runbook section "Common incidents" is the right place to point support tickets.

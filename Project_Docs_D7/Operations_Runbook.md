# Operations Runbook

**Status date:** April 29, 2026
**Live URL:** http://scheduler.omnilore.org
**Owner (post-handoff):** Omnilore stakeholder team

This runbook is what the on-call developer reaches for when something is wrong, when a credential needs to rotate, or when the site is on fire. Every command assumes you have AWS console access and an SSH key authorized for `EC2_USERNAME`@`EC2_HOST`.

## 1. Ownership and Access

| Asset | Where it lives | Who must own it post-handoff |
| --- | --- | --- |
| `Omnilore-DB/Scheduler` GitHub repo | github.com | Stakeholder set as **Owner/Admin** before student access is removed. |
| GitHub Actions secrets | GitHub repo → Settings → Secrets | Set by stakeholder; rotated through stakeholder-controlled AWS account. |
| AWS account / EC2 instance / security group | AWS console | Stakeholder. Student IAM user (if any) revoked after sign-off. |
| EC2 SSH key (`EC2_SSH_KEY`) | Stakeholder password manager | Stakeholder. Public half is in `~/.ssh/authorized_keys` on the EC2 host for `EC2_USERNAME`. |
| DNS for `scheduler.omnilore.org` | Omnilore's DNS provider | Stakeholder. |
| Demo video file | `Project_Docs_D7/Team34_Omnilore_Scheduler_D7_Demo.mp4` (and/or stakeholder-approved link) | Stakeholder. |

After the stakeholder confirms ownership of all of the above, the team's IAM user, GitHub access, and any SSH keys belonging to students should be **revoked, not just downgraded.**

## 2. Normal Operation

The production app is a static Flutter web build served from `/var/www/html` on AWS EC2 (`scheduler.omnilore.org`). Users open the site, upload `course.txt` and `people.txt` from their machine, and run the entire scheduling pipeline in-browser. There is no backend, no database, no auth, and no PII at rest on the server. The site is otherwise idle.

## 3. Monitoring and Logs

| What | Where | Who watches |
| --- | --- | --- |
| GitHub Actions test/deploy runs | github.com → Actions tab | On-call developer; required reading after every push to `main`. |
| EC2 web-server logs | nginx: `/var/log/nginx/access.log`, `/var/log/nginx/error.log` (or Apache equivalents at `/var/log/apache2/`). Confirm with the stakeholder which web server is installed before relying on these paths. | On-call developer when triaging an incident. |
| EC2 instance health | AWS console → EC2 → Instances; `top` / `df -h` on the host | On-call developer when triaging. |
| Browser console | Chrome DevTools → Console | The reporting user, on request. |

**Recommended additions** (none of these are wired today):

- Uptime monitoring on `http://scheduler.omnilore.org` (UptimeRobot, BetterStack, AWS Route 53 health check). Filed as P1 in the backlog.
- CloudWatch alarms on the EC2 instance for CPU/disk/network anomalies.
- Log shipping to a centralized store if Omnilore plans multi-app hosting.

## 4. Common Incidents

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Live URL returns connection refused or times out | EC2 instance is stopped, or web server not running | AWS console → start instance. SSH in: `sudo systemctl status nginx` (or `apache2`); `sudo systemctl start nginx`. |
| Live URL returns 404 / blank `index.html` | `/var/www/html` is empty or partial deploy | Re-run `deploy.yml` from the last green commit, or manually restore from a backup if you have one. |
| Live URL serves an old build | Stale build artifacts; `deploy.yml` did not run on the latest merge | Check Actions tab. If the workflow didn't run, push a no-op commit to `main` to trigger it. |
| `deploy.yml` fails at "Configure AWS Credentials" | Missing/expired `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` | Re-issue keys in IAM, update the GitHub secret, re-run the workflow. |
| `deploy.yml` fails at "Whitelist Runner IP" | IAM user lacks `ec2:AuthorizeSecurityGroupIngress` on `AWS_SG_ID`, or the security group ID changed | Update IAM policy or fix `AWS_SG_ID`. |
| `deploy.yml` fails at SCP step | SSH key/host/user mismatch, or runner IP not whitelisted in time (rare race) | Verify `EC2_HOST`, `EC2_USERNAME`, `EC2_SSH_KEY`. Confirm the public half of `EC2_SSH_KEY` is in `~/.ssh/authorized_keys` on EC2. |
| Whitelist step succeeded but revoke step failed | Transient AWS API hiccup | Manually delete the temporary ingress rule from `AWS_SG_ID` in the AWS console. Filter for `:22` rules with a single-IP CIDR. |
| Browser save dialog never appears on web | Browser does not support `showSaveFilePicker` (e.g., Firefox) | Expected. The export falls back to a regular browser download — the file is in the browser's downloads folder. Document this for the user. |
| Autosave restore prompt never appears | `localStorage` was cleared, the user is on a different browser/profile, or the site was opened in a private window | Tell the user that autosave is browser-local. Recovery path is **Save As** → reload → **Load**. |
| "Inconsistent" error on load | A person references a course code not in `course.txt` | Compare files. The exception message names the offending code/line. |
| Malformed input exception on load | Wrong column count / availability value / number wanted | The exception message identifies the line. Compare to `test/resources/course.txt` and `people.txt` for the canonical format. |
| Coordinator buttons feel "stuck" on a previous selection | Pre-D5 behavior | This was fixed in D5/D6: `Set C and CC` and `Set CC1 and CC2` clear prior selection on re-entry, and tapping a highlighted name on an assigned course clears the assignment. If a regression is reported, re-run the coordinator widget tests. |

## 5. Backup and Restore

The application has no server-side data. Backups protect two things:

1. **The deployed build artifacts on EC2.**
   - Today there is no automated build archive. If `/var/www/html` is corrupted, the recovery path is "redeploy a known-good commit." That re-creates the build from source.
   - **Recommended improvement (P1):** add a step to `deploy.yml` that uploads `build/web/` as a versioned artifact to S3 (`s3://omnilore-scheduler-builds/<sha>/`). A rollback then becomes `aws s3 sync` instead of a rebuild. Filed in the backlog.

2. **User session data.**
   - Users are responsible for keeping copies of their original `course.txt` and `people.txt`.
   - **Save As** produces a single self-contained bundle (`CourseFile:` + `PeopleFile:` + `Setting:`). This is the only operational backup of in-progress work.
   - Browser autosave is browser-profile-local and is convenience-only. Treat it as ephemeral.

### Restore drill (do this once after handoff)

```bash
# On a developer machine, with the live URL up:
# 1. Open http://scheduler.omnilore.org
# 2. Load test/resources/course.txt + people.txt
# 3. Walk to coordinator stage, assign a few coordinators
# 4. Save As → save the bundle to disk
# 5. Refresh the tab; decline the autosave prompt
# 6. Load the saved bundle → confirm the entire state restores
```

If step 6 fails, treat as a P0 incident — bundled-state save/load is the only durable session backup.

## 6. Key Rotation

Rotate quarterly, and immediately on any suspicion of compromise. The seven secrets are documented in `.env.example` and in `Setup_and_Deployment_Guide.md` §6.

### AWS access keys (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)

```bash
# AWS console → IAM → Users → <deploy user> → Security credentials
# 1. Create access key.
# 2. Update GitHub secrets AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY.
# 3. Push a small no-op commit (e.g., bump comment in deploy.yml) → confirm green deploy.
# 4. Disable the previous key (do not delete yet).
# 5. After 24 hours of clean deploys, delete the previous key.
```

### EC2 SSH key (`EC2_SSH_KEY`)

```bash
# Generate a new key locally:
ssh-keygen -t ed25519 -C "omnilore-deploy-$(date +%Y%m)" -f ./omnilore_deploy_new

# On the EC2 host, append the new public key to authorized_keys (do NOT replace the old one yet):
ssh -i <old_key> $EC2_USERNAME@$EC2_HOST 'cat >> ~/.ssh/authorized_keys' < ./omnilore_deploy_new.pub

# Update the GitHub secret EC2_SSH_KEY with the contents of ./omnilore_deploy_new (the PRIVATE key, full PEM).
# Trigger a deploy → confirm green.
# Once green, remove the OLD public key from authorized_keys on EC2 and securely destroy ./omnilore_deploy_new.
```

### Networking secrets (`AWS_REGION`, `AWS_SG_ID`, `EC2_HOST`, `EC2_USERNAME`)

These rarely change. If they do, update GitHub secrets and re-run a deploy from the latest commit. `EC2_HOST` may also require a DNS update.

After every rotation, update the table in §10 below.

## 7. Scaling

The app is static-asset hosting plus client-side computation. There is no server-side load to scale.

If usage grows or Omnilore wants higher availability:

- **Recommended:** migrate `deploy.yml` to publish to S3 + CloudFront. The Flutter web build is well-suited to CDN delivery. This eliminates the EC2 maintenance burden, gives free TLS via ACM, and trivializes rollback (versioned S3 prefixes). Filed as P2 in the backlog.
- If staying on EC2: enable an Elastic IP, configure CloudWatch alarms, and keep a known-good AMI snapshot.
- The compute side does not scale by adding capacity — it scales by improving the algorithm. See `Backlog_Known_Issues_Roadmap.md` for performance notes if data volumes grow.

## 8. Scheduled Tasks

There are no application-level scheduled tasks (no cron, no Lambda, no SQS). The only recurring system events are GitHub Actions runs, which are event-driven (push/PR), not scheduled.

If TLS via Let's Encrypt is added (recommended), `certbot` will install a renewal cron. Document its path here when it lands.

## 9. Recovery Checklist (P0)

When the live site is hard-down:

1. Confirm scope: is this one user (browser issue) or all users (server/build issue)? `curl -I http://scheduler.omnilore.org` from an outside network.
2. Check GitHub Actions for the last `deploy.yml` result.
3. AWS console → EC2 → confirm the instance is running and reachable.
4. SSH to the host: `sudo systemctl status nginx` (or `apache2`); `tail -200 /var/log/nginx/error.log`.
5. `ls -la /var/www/html` — confirm there is an `index.html`. If empty, the last deploy didn't write artifacts.
6. **Recovery action:** push a no-op commit to `main` from a known-good revision, or click "Re-run all jobs" on the last green `deploy.yml` run.
7. After the deploy succeeds, run the deployment smoke test (Setup guide §7).
8. Post-mortem: open a backlog item with root cause, time-to-detect, time-to-recover, and the preventive fix.

## 10. Expiration and Deactivation Dates

Stakeholder must keep this table current. **Empty rows are blocking handoff items.**

| Item | Expires / Renews | Owner | Notes |
| --- | --- | --- | --- |
| AWS account / billing | Stakeholder org plan | Stakeholder | Confirm payment method on file. |
| AWS deploy IAM access keys | Recommend 90-day rotation | Stakeholder | See §6 above. |
| EC2 SSH key (`EC2_SSH_KEY`) | Recommend annual rotation | Stakeholder | See §6 above. |
| EC2 instance (`EC2_HOST`) | n/a — until decommissioned | Stakeholder | If Omnilore reserves capacity, note the term. |
| Domain `omnilore.org` | Per Omnilore registrar | Stakeholder | Renew before expiry to avoid DNS outage. |
| TLS certificate (when added) | 90 days, auto-renew via certbot | Stakeholder | After cert install, document renewal cron path here. |
| Free-tier / student credits used during D1–D7 | All consumed prior to handoff | Team 34 | None of these gated production. |
| Demo video link (if hosted on a third-party service) | Per host | Stakeholder | Move to stakeholder-controlled storage if hosted on a student account. |

## 11. Post-handoff playbook (first 90 days)

| When | Action |
| --- | --- |
| T+0 | Stakeholder confirms Owner/Admin on GitHub repo and AWS. Student access revoked. |
| T+0 | Rotate AWS access keys and `EC2_SSH_KEY` (treat student-era keys as exposed). |
| T+1 week | Add uptime monitoring on `http://scheduler.omnilore.org` (P1). |
| T+1 week | Tag final D7 release: `git tag -a d7-final-handoff -m "..."` ; `git push origin d7-final-handoff`. |
| T+30 days | Add TLS via certbot; switch references to `https://`. |
| T+60 days | Decide whether to migrate hosting to S3 + CloudFront (P2). |
| T+90 days | Quarterly key rotation cycle; first run. |

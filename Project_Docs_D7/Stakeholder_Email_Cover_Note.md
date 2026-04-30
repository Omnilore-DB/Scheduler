# Stakeholder Email Cover Note

> Use this as the cover email when sending the Deliverable 7 package. CC the project mentor and the rest of Team 34. Replace the `<>` placeholders before sending.

---

**Subject:** Omnilore Scheduler — Deliverable 7 (Final Handoff Package)

Hello <stakeholder name>,

Team 34 (CSCI 401) is sending the final handoff package for the Omnilore Scheduler web migration. Everything you need to take ownership and continue maintenance is included or linked below.

**What's attached / linked:**

- **Project_Docs_D7/** — comprehensive handoff documentation (README quick start, architecture, deploy guide, operations runbook, API/data reference, testing summary, security/privacy notes, backlog, changelog, demo video script, handoff checklist, manifest, this cover note, plus PNG/SVG diagrams).
- **Live URL:** http://scheduler.omnilore.org
- **Repository:** https://github.com/Omnilore-DB/Scheduler
- **Demo video:** `Team34_Omnilore_Scheduler_D7_Demo.mp4` (in `Project_Docs_D7/` or at the link below)
- **Deliverable 7 ZIP / link (Brightspace):** <link>

**What we need from you (within 48–72 hours, please):**

1. Confirm you (or the Omnilore admin you designate) have **Owner/Admin** access to:
   - the GitHub repository `Omnilore-DB/Scheduler`,
   - the AWS account that owns the EC2 instance, security group `AWS_SG_ID`, and the IAM deploy user.
2. Acknowledge receipt of the seven GitHub Actions secrets we transferred through `<secure channel name>` on `<date>`. The secret names are listed in `Project_Docs_D7/.env.example`. We have not put real values in the repository.
3. Sign off the **Handoff Checklist** in `Project_Docs_D7/Handoff_Checklist_and_Verification_Log.md`. The "Pending" rows are the ones we still need from you (live-site smoke test, ownership confirmation, sign-off line at the bottom).
4. Tell us if you want any edits before we tag the final release as `d7-final-handoff`.

**What we'll do as soon as you confirm:**

- Tag and push `d7-final-handoff` from `main`.
- Rotate AWS access keys and the EC2 SSH key (per the procedure in `Operations_Runbook.md` §6) and decommission our access.
- Hand off any remaining one-off scripts or notes you ask for.

**A note on what's *not* in the repository.** Real AWS credentials, the EC2 SSH private key, and any production member data have never been committed and are not in the email. Those moved through `<secure channel>` only. We've documented the secure-rotation steps in the runbook so anyone you bring on next can rotate them without us.

A short prioritized to-do list for the next 30–90 days lives at `Project_Docs_D7/Backlog_Known_Issues_Roadmap.md`. The two we'd most recommend you tackle first are (1) adding TLS via Let's Encrypt on the EC2 host and (2) standing up uptime monitoring on the live URL — both small, both meaningful.

Thank you for the term — it was a real pleasure shipping this for Omnilore. We'll watch for your sign-off.

Best,

Xavier Wisniewski (xwisniew@usc.edu)
on behalf of Team 34: Derick Walker, Andrew Chang, Aiden Yan, Alex Wan
CSCI 401, University of Southern California

CC: <mentor name>, <team@usc.edu addresses>

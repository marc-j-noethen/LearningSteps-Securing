# LearningSteps Lockdown — Slide Content for Gamma

Full slide-by-slide content for the 5-day deck, reflecting the current
architecture (NPMplus + CrowdSec, no rate limiting, adapted Sentinel
pipeline). Written to be pasted directly into Gamma to regenerate the deck.
Every day's live demo references the corresponding numbered demo in
`docs/handbook.md` — say "see the handbook" rather than duplicating full
command blocks on slides.

---

# Day 1 — Locking Down Management Access

**Slide 1: Title**
LearningSteps Lockdown — Day 1: Locking Down Management Access

**Slide 2: Where We Are**
LearningSteps is deployed and running — a FastAPI + PostgreSQL app on an
Azure VM. It works, but it's wide open: static SSH keys, no network
restrictions, anonymous API access, a public database, no encryption, no
visibility. Over this week, we close each of these gaps one at a time.

**Slide 3: Today's Problem — Static Keys and Open Ports**
Right now, anyone on the internet can attempt to brute-force SSH on our VM.
Automated scanners (Shodan, Masscan) find new servers with open port 22
within minutes of deployment — no targeting required. Static SSH keys are
also a liability on their own: file-based, easy to leak, hard to rotate, no
audit trail.

**Slide 4: Demo — Shodan**
Live demo: search shodan.io for `port:22` and show how trivially exposed
SSH servers are discovered at internet scale.

**Slide 5: Static Keys vs. Identity**
Static SSH keys: file-based, hard to rotate, no audit trail. Identity-based
access (Entra ID): tied to a real user, enforces MFA, fully auditable —
every login logged with user, timestamp, IP, device.

**Slide 6: Today's Fix**
Two changes: (1) replace static SSH keys with Entra ID identity-based login,
(2) restrict the NSG so port 22 is only reachable from a trusted IP, not the
whole internet.

**Slide 7: Demo — Handbook Day 1, Demo 1: Entra ID SSH Login**
See the handbook for exact commands. Confirm the "Virtual Machine
Administrator Login" role assignment, then log in via `az ssh vm` — no key
file, MFA-backed, fully audited.

**Slide 8: Demo — Handbook Day 1, Demo 2: Restrict SSH to a Trusted IP**
See the handbook. Edit the NSG rule to replace `"*"` with a specific trusted
IP. `terraform apply` takes effect immediately.

**Slide 9: Pop Quiz**
You've configured Entra ID login but still can't connect via `az ssh`. Your
IP is allowed in the NSG. What's missing?
A) A new `.pem` file from the portal
B) The "Virtual Machine Administrator Login" RBAC role
C) A VM restart
D) A Windows machine

**Slide 10: Pop Quiz — Answer**
**B** — the NSG controls network access; RBAC controls OS-level login
authorization. Both are required, and they're independent controls.

**Slide 11: Summary**
- Replaced static SSH keys with Entra ID identity-based login (MFA-backed,
  fully audited).
- Restricted the NSG to eliminate open-to-the-world SSH exposure.
- Learned that network access (NSG) and login authorization (RBAC) are two
  separate controls — both required.

---

# Day 2 — Identity-Based API Access

**Slide 1: Title**
LearningSteps Lockdown — Day 2: Identity-Based API Access

**Slide 2: The Public Utility Problem**
Yesterday we locked the admin entrance (port 22). Today, the application
entrance (port 8000) is still a public utility — anyone on the internet can
create, modify, or delete data with zero accountability. No audit trail, no
attribution, no way to revoke a single bad actor's access.

**Slide 3: API Keys vs. Identity — the Same Lesson as Day 1**
Phase 1 — API Keys: a static "password" for the API. Doesn't expire
automatically, hard to rotate, easy to leak, no per-user attribution.
Phase 2 — Identity (the gold standard): tied to a real account, enforces
MFA, short-lived tokens, precise per-user revocation.

**Slide 4: Refresher — JWT**
A JWT is a signed, self-contained token proving identity. Header (algorithm)
+ Payload (claims: who, roles, expiry) + Signature (tamper-proof, verified
against the issuer's public key). Not encrypted — anyone can read it; the
signature just proves it wasn't altered.

**Slide 5: Today's Approach — Identity at the Edge**
Rather than changing application code, we put an identity gate in front of
FastAPI. All public traffic hits this gate first; FastAPI is never directly
exposed. The gate validates every request's Entra ID token before
forwarding — enforced entirely at the infrastructure layer.

**Slide 6: Demo — Handbook Day 2, Demo 1-2: Admin Panel & Proxy Host**
See the handbook. Access the (internet-facing but not internet-exposed)
admin panel via SSH tunnel — same trusted-access principle as Day 1's SSH
lockdown. Create the app's Proxy Host.

**Slide 7: Demo — Handbook Day 2, Demo 3: Register an Entra ID Application**
See the handbook. Register an app registration for the API, get a client
ID/secret. A worthwhile aside: this needs both an app registration *and* a
Service Principal — the two are not automatically the same thing.

**Slide 8: Demo — Handbook Day 2, Demo 4-5: Wire Up the Identity Gate**
See the handbook. Configure oauth2-proxy with the app's credentials and the
tenant's OIDC issuer URL, then wire it into the identity gate via a single
dropdown/API call — no hand-written proxy configuration. Worth opening the
generated config afterward to see what got built automatically.

**Slide 9: Demo — Handbook Day 2, Demo 6: Test the Identity Gate**
See the handbook. Unauthenticated → rejected. Garbage token → rejected. Real
browser login → succeeds. Real Entra ID token sent directly (no browser) →
succeeds — this is how we'll script/verify the gate going forward.

**Slide 10: Summary**
- Identified the risk of anonymous API access: zero accountability.
- Explained why identity (JWT) beats static API keys: signed, short-lived,
  user-bound, individually revocable.
- Put an identity gate in front of the app with no application code
  changes.
- Verified enforcement three ways: no token, bad token, valid token.

---

# Day 3 — Data Isolation

**Slide 1: Title**
LearningSteps Lockdown — Day 3: Data Isolation

**Slide 2: The Crown Jewels Problem**
We've secured the entrance (Day 1) and the application gate (Day 2). Today:
the database — the single most valuable asset in the system.

**Slide 3: Why This Matters**
A publicly reachable database is a standing target: bots scan the internet
for port 5432 continuously. Traffic on the public internet can also be
intercepted. Once an attacker reaches the database directly, they've
bypassed every control we built on the previous two days.

**Slide 4: The Solution — Private Link**
Deploy the database inside the Azure Virtual Network with a delegated
subnet and a private DNS zone — it never gets a public IP at all. No port to
scan, no endpoint to target. All traffic between the VM and database stays
on Azure's internal backbone.

**Slide 5: This Course's Baseline**
In this environment, the database has been private-by-default from the very
first deploy — there's no earlier "public database" phase to migrate away
from live. Today's exercise is about understanding *why* it's built this
way, and safely practicing a disruptive database operation with a real
backup-first discipline.

**Slide 6: Demo — Handbook Day 3, Demo 1: Back Up the Database**
See the handbook. Since the database has no public IP, the backup runs
*from the VM*, over SSH — never directly from your laptop. Pull the result
down to your own machine before doing anything destructive.

**Slide 7: Demo — Handbook Day 3, Demo 2: Recreate the Database**
See the handbook. Force a real destroy-and-recreate with
`terraform apply -replace`. This is a genuinely disruptive operation — the
app can't reach the database at all while it runs.

**Slide 8: A Hidden Interaction Worth Discussing**
A single Terraform reference (the VM reading the database's live hostname)
used to cause replacing the database to cascade into replacing the *entire
VM* — silently wiping every prior day's configuration. Fixed by using a
static, predictable hostname instead of the live resource value. Good
general lesson: a resource dependency you didn't intend to create can turn
a small operation into a much bigger one.

**Slide 9: Pop Quiz**
You've moved the database to a private subnet. Restoring from your laptop
times out. Why?
A) Password expired
B) Your laptop isn't inside the Azure Virtual Network
C) Restart the proxy
D) Corrupted backup file

**Slide 10: Pop Quiz — Answer**
**B** — private access means only resources inside the VNet can reach the
database. Your laptop is outside it; the VM is inside it.

**Slide 11: Demo — Handbook Day 3, Demo 3-4: Restore and Verify**
See the handbook. Restore from the VM, confirm the laptop still can't
resolve the database hostname at all, and confirm the app is actually
serving real data again (not just that the server exists).

**Slide 12: Summary**
- Identified the risks of a public database: scanning, interception,
  unbounded blast radius.
- Practiced a real backup-first migration discipline.
- Learned that a hidden resource dependency can turn a small, intended
  change into a much larger, unintended one.

---

# Day 4 — Encryption and a Web Application Firewall

**Slide 1: Title**
LearningSteps Lockdown — Day 4: Encryption and a Web Application Firewall

**Slide 2: Two Remaining Gaps**
We've secured who can access the system (Days 1-2) and isolated the data
(Day 3) — but not how traffic travels, or what's actually being sent.
Gap 1: traffic is still plaintext — tokens can be intercepted.
Gap 2: nothing inspects request content — no protection against SQL
injection, XSS, or other attack payloads.

**Slide 3: Refresher — TLS and Certificates**
TLS encrypts traffic in transit. A certificate, signed by a trusted CA
(e.g. Let's Encrypt), proves server identity — browsers trust it
automatically. Without TLS, tokens can be silently intercepted
(adversary-in-the-middle).

**Slide 4: Demo — Handbook Day 4, Demo 1: Port Open ≠ Encrypted**
See the handbook. Request the app over plain HTTP with the port fully open
— note the response is completely readable in transit. An open port is not
the same claim as an encrypted connection.

**Slide 5: Demo — Handbook Day 4, Demo 2: Enable Real TLS**
See the handbook. Request a real Let's Encrypt certificate through the
front door — same domain-verification challenge under the hood, now
automated by the tool rather than hand-typed. Confirm the certificate is
valid and HTTP now redirects to HTTPS.

**Slide 6: Traffic Is Encrypted — But Is the API Protected?**
TLS protects the pipe, not what's inside it. Nothing yet stops SQL
injection, XSS, or a malicious payload from reaching the application
directly.

**Slide 7: Refresher — Web Application Firewall**
Day 2's identity gate asks "who are you?" A WAF asks "what are you
sending?" — inspecting the actual request content for known attack
signatures (SQL injection, XSS, and hundreds of other patterns). An
authenticated user can still be an attacker; a WAF closes that gap.

**Slide 8: Demo — Handbook Day 4, Demo 3: Enable the WAF**
See the handbook. Show the gap first — SQLi and XSS payloads pass straight
through. Enable the WAF (running the real OWASP Core Rule Set). Re-send the
same payloads — both now blocked.

**Slide 9: Layered Defenses Interact**
Once Day 2's identity gate and today's WAF are both active on the same
path, an *unauthenticated* attack payload gets redirected to login before
it ever reaches the WAF — so it won't show a block. To actually see the WAF
work, send the payload with a valid session attached. This demonstrates the
WAF protecting authenticated users too — arguably the more realistic
threat, since anonymous attackers were already stopped by Day 2's gate.

**Slide 10: Read the Fine Print**
Security tools have their own tradeoffs. The WAF engine used here shares
detected attack signals with a community threat-intelligence blocklist by
default. Worth checking what a tool shares before adopting it — this
applies to any security tool, not just this one.

**Slide 11: Summary**
- Demonstrated that an open port is not the same as an encrypted
  connection.
- Enabled real, automatically-renewing TLS.
- Enabled a WAF running genuine industry-standard rules, and watched it
  block real attack payloads.
- Learned that layered defenses can interact in non-obvious ways — test the
  combination, not just each layer alone.

---

# Day 5 — Visibility and Automated Response

**Slide 1: Title**
LearningSteps Lockdown — Day 5: Visibility and Automated Response

**Slide 2: The Visibility Gap**
Every layer built this week is a static defense. If an attacker bypasses
one, or even just probes it — how would we know? The industry-average time
to detect a breach is 200+ days. You cannot defend what you cannot see.

**Slide 3: Quick Quiz**
What is Microsoft Sentinel? A Log Analytics Workspace? The log-shipping
agent on the VM? A Data Collection Rule?

**Slide 4: The Answers**
- **Sentinel**: cloud-native SIEM — detects threats, responds automatically.
- **Log Analytics Workspace**: the database behind Sentinel; every log line
  lands here as a queryable row.
- **Monitoring agent**: installed on the VM, ships logs to the workspace
  over HTTPS — no inbound ports needed.
- **Data Collection Rule**: tells the agent what to collect and where to
  send it.

**Slide 5: The Roadmap**
Phase 1 — Visibility: ship structured logs to the cloud.
Phase 2 — Detection: an analytics rule that watches for an attack pattern.
Phase 3 — Response: an automated playbook that blocks the attacker, no
human required.

**Slide 6: Getting Logs Out of a Container**
Our front door runs inside a container — its logs don't reach the host's
system log automatically. A small forwarder service tails the container's
log file, converts each entry to structured JSON, and forwards it to the
host's logging system. A generally useful pattern for any containerized
service, not specific to this course.

**Slide 7: Demo — Handbook Day 5, Demo 1-2: Confirm Logging and Ingestion**
See the handbook. Confirm the forwarder is running, generate traffic, and
confirm it shows up locally first — the fastest way to debug anything that
doesn't show up later in the cloud. Then confirm it's actually landing in
the Log Analytics Workspace.

**Slide 8: Demo — Handbook Day 5, Demo 3: Run the Attack Simulation**
See the handbook. Fire the same SQL injection payload from Day 4 repeatedly,
authenticated (so it actually reaches the WAF), and confirm all requests are
blocked.

**Slide 9: Demo — Handbook Day 5, Demo 4: Validate the Detection Query**
See the handbook. Run the detection query directly first — a query that
watches for repeated blocks from a single source in a short window. Confirm
it finds the attack before waiting on the scheduled rule.

**Slide 10: Demo — Handbook Day 5, Demo 5-6: Watch the Automated Response**
See the handbook. Wait for the scheduled rule to raise an incident, confirm
the automated playbook fires, and — critically — verify the resulting block
actually cuts off traffic from the attacker, not just that a rule was
created.

**Slide 11: "The Rule Exists" ≠ "The Rule Works"**
A firewall rule can be created successfully and still do nothing, if a
broader, higher-priority rule matches first. Always test the actual
connectivity after a block, not just the rule's existence — a strong,
general lesson about firewall rule ordering that applies well beyond this
course.

**Slide 12: The Full Week — Fortress Review**
Day 1: management access hardened via identity.
Day 2: identity enforced at the application edge.
Day 3: data isolated from the public internet.
Day 4: traffic encrypted, payloads inspected and blocked.
Day 5: full visibility, automatic detection, automatic response.

**Slide 13: Challenges — Open Discussion**
- How do you tune detection thresholds to avoid false positives without
  creating blind spots?
- How do these patterns scale to hundreds or thousands of VMs across
  regions and subscriptions?
- What's next — Zero Trust architecture, threat intelligence feeds, custom
  anomaly detection?

**Slide 14: Summary**
- Solved the visibility gap: logs now flow from the app to a central
  security platform.
- Built a real detection rule and watched it fire on a genuine attack.
- Closed the loop with an automated response — and confirmed the response
  actually works, not just that it exists.

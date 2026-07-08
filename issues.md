# Risk Brainstorm - LearningSteps Lockdown

This document captures the initial group exercise for identifying realistic attack scenarios in the insecure baseline environment.
- **Likelihood** = How likely is it that this will happen?
- **Impact** = How serious would it be?
- **Priority** = How urgently does it need to be fixed?
- **Why** = Why are we assessing it this way?

The environment is deliberately set up to be insecure: a VM with SSH open, a static SSH key, an app without TLS/WAF/authentication, and a publicly accessible database. Therefore, the following scenarios are realistic.

| Scenario | Likelihood | Impact | Priority | Why |
|---|---|---|---|---|
| 1. Public SSH access on port 22 is open to the internet | High | High | Critical | Port 22 is constantly scanned by automated bots. If SSH is reachable from any IP, attackers can repeatedly try access attempts. Even if password login is disabled, the exposed management port increases attack surface. |
| 2. The `.learningsteps_key` private SSH key is leaked or committed to GitHub | Medium | High | High | The baseline uses a static SSH key file. If this key is copied, lost, sent in chat, or accidentally pushed to a repository, anyone with the key can log in to the VM if the network still allows SSH. |
| 3. Application traffic uses HTTP instead of HTTPS | High | Medium | High | Without TLS, traffic is not encrypted. A person on the network path could read or modify requests and responses. This becomes especially dangerous once users, tokens, or sensitive data are involved. |
| 4. The API is reachable without authentication | High | High | Critical | If the API accepts anonymous requests, attackers do not need an account. They can read, create, change, or delete learning entries, and the team cannot reliably prove which real user performed an action. |
| 5. PostgreSQL is publicly reachable from the internet | Medium | Critical | Critical | The database is the most sensitive asset because it stores application data. If it has a public endpoint and permissive firewall rules, attackers can scan it, brute-force credentials, or exploit misconfigurations. A compromise could mean full data loss or data theft. |

**Why these five in particular?**

1. **SSH open** affects the management plane.  
   This is access to the machine itself. Anyone who gains access there can stop services, delete logs, read files or change the configuration.

2. **SSH key leak** affects credentials.  
   A key is like a front-door key. If it is copied, you cannot "get it back". You must block access or rotate the keys.

3. **No HTTPS** affects the transport layer.  
   The app may function correctly, but data travels unprotected across the network. TLS is the layer that protects confidentiality and integrity during transport.

4. **No authentication** affects the application itself.  
   Without a login, there is no identity. Without identity, there is no access control and no meaningful traceability.

5. **Public database** affects the crown jewels.  
   Even if the app and VM are better protected, the database must not be directly accessible from the internet. It belongs on the private network.

A good sentence for the presentation would be:

> Our highest-priority risks are the ones that give direct control over the VM, the API, or the database. Public SSH, anonymous API access, and public database exposure are critical because they can lead to full system compromise or data loss.
# LinkedIn Post Drafts

## Day 0 - Baseline Setup

Today I started the LearningSteps Lockdown project: a practical Azure security hardening challenge.

The goal is to take an intentionally insecure baseline deployment and improve it step by step with evidence-based security controls.

Day 0 focused on:
- deploying the baseline infrastructure with Terraform
- validating the VM, API, PostgreSQL, NPMplus, and CrowdSec setup
- documenting realistic attack scenarios
- setting up a clean GitHub documentation structure
- ensuring secrets, SSH keys, and Terraform state are excluded from Git

Key learning:
A deployment is not complete just because the installer says so. Runtime evidence matters. Verifying the running containers with `docker ps` provided stronger proof than relying only on setup output.
## Final LinkedIn Post - LearningSteps Lockdown Parts 1-5

LearningSteps Lockdown ist fertig.

Aus einem bewusst unsicheren Azure-Baseline-Deployment ist Schritt fuer Schritt eine deutlich besser abgesicherte Umgebung geworden.

Was ich umgesetzt und dokumentiert habe:

- SSH Management Access eingeschraenkt
- Reverse Proxy mit NPMplus und HTTPS/TLS aufgebaut
- Zugriff ueber Microsoft Entra ID und oauth2-proxy abgesichert
- PostgreSQL aus dem oeffentlichen Internet genommen und privat angebunden
- Backup und Restore vor der Datenbank-Migration verifiziert
- nginx Logs ueber Syslog nach Log Analytics gebracht
- CrowdSec AppSec/WAF aktiviert und echte 403 Blocks erzeugt
- Microsoft Sentinel Incident aus WAF-Events erstellt
- automatische NSG-Blockregel per Playbook nachgewiesen

Der wichtigste Lerneffekt fuer mich war: Security ist nicht nur eine Einstellung in Azure.

Man muss beweisen, dass jede Schicht wirklich funktioniert:

- Ist der Dienst erreichbar?
- Ist er nur dort erreichbar, wo er erreichbar sein soll?
- Wird ein Angriff geblockt?
- Wird der Block geloggt?
- Kommt das Log in Azure an?
- Erkennt Sentinel daraus einen Incident?
- Reagiert die Automation wirklich?

Genau das habe ich in diesem Projekt mit Screenshots und Commands dokumentiert.

Nicht perfekt aus dem ersten Versuch, aber genau dadurch habe ich viel mehr gelernt: Fehlersuche, Logs lesen, Befehle sauber herleiten, Secrets schuetzen und Ergebnisse beweisen.

Repo:
https://github.com/marc-j-noethen/LearningSteps-Securing

#CyberSecurity #Azure #MicrosoftSentinel #DevSecOps #CloudSecurity #Terraform #LearningInPublic

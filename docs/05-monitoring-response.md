# Part 5 - Monitoring, Detection, and Automated Response

## Goal

The goal of this part was to prove that the LearningSteps environment can detect and respond to suspicious web activity.

Before this part, the application was already protected by TLS, NPMplus, Microsoft Entra ID authentication, and private PostgreSQL access. Part 5 focused on the monitoring and response path:

```text
Browser / attacker
-> NPMplus
-> CrowdSec AppSec / WAF
-> nginx JSON access log
-> local syslog
-> Azure Monitor Agent
-> Log Analytics
-> Microsoft Sentinel
-> Analytics rule
-> Incident
-> Automation playbook
-> NSG deny rule
```

In simple terms: a malicious-looking request should be blocked, logged, detected by Sentinel, and then used to create an automatic network block rule.

## Why This Matters

Security is not finished when an application is deployed. A secure environment needs visibility and response.

The important questions in this part were:

- Can I see real web traffic in logs?
- Are the logs forwarded from the VM to Azure?
- Can Log Analytics parse the nginx JSON logs?
- Does the Sentinel rule match real WAF block events?
- Does the automation create a network block rule?
- Can I safely remove the test block afterward?

This matters because attackers do not usually announce themselves. Monitoring is the layer that turns activity into evidence.

## VM and Access Baseline

Before testing the monitoring flow, I confirmed that the VM was running and that SSH access was still restricted to my current public IP address.

Evidence:

![VM running before monitoring](../images/05-monitoring/01-vm-running-before-monitoring.png)

![SSH NSG updated current IP](../images/05-monitoring/02-ssh-nsg-updated-current-ip.png)

The NPMplus and CrowdSec containers were running:

```bash
sudo docker ps
```

Evidence:

![Docker containers running](../images/05-monitoring/03-docker-containers-running.png)

## Local Log Forwarding

The environment uses a systemd service called `npmplus-log-forwarder`. Its job is to read the NPMplus nginx access log and forward it into Linux syslog with the process name `nginx`.

Command:

```bash
systemctl status npmplus-log-forwarder --no-pager
```

Evidence:

![Log forwarder active](../images/05-monitoring/04-log-forwarder-active.png)

Then I checked the local syslog stream directly:

```bash
sudo journalctl -t nginx --since '5 min ago' --no-pager
```

This showed nginx JSON events from NPMplus.

Evidence:

![Local nginx syslog events](../images/05-monitoring/05-local-nginx-syslog-events.png)

After opening the app in the browser, the real browser request became visible locally:

Evidence:

![Browser request visible in local syslog](../images/05-monitoring/06-browser-request-visible-in-local-syslog.png)

## Log Analytics Ingestion

Next, I verified that the same nginx syslog events were arriving in Azure Log Analytics.

First, I retrieved and stored the Log Analytics workspace ID:

```powershell
$WORKSPACE_ID = "6dc3eb6d-2ead-4b93-8783-336779e176e8"
```

Then I queried recent nginx events:

```powershell
$query = "Syslog | where TimeGenerated > ago(30m) | where ProcessName == 'nginx' | project TimeGenerated, Computer, ProcessName, SyslogMessage | sort by TimeGenerated desc | take 5"
az monitor log-analytics query -w $WORKSPACE_ID --analytics-query $query -o table
```

Evidence:

![Log Analytics nginx syslog ingestion](../images/05-monitoring/07-log-analytics-nginx-syslog-ingestion.png)

Then I parsed the JSON inside `SyslogMessage`:

```powershell
$query = "Syslog | where TimeGenerated > ago(30m) | where ProcessName == 'nginx' | extend log=parse_json(SyslogMessage) | project Row=strcat(format_datetime(TimeGenerated, 'HH:mm:ss'), ' | ', tostring(log.remote_addr), ' | ', tostring(log.domain), ' | ', tostring(log.uri), ' | ', tostring(log.status)) | sort by Row desc | take 10"
az monitor log-analytics query -w $WORKSPACE_ID --analytics-query $query -o tsv
```

Evidence:

![Log Analytics parsed nginx events](../images/05-monitoring/08-log-analytics-parsed-nginx-events.png)

The real browser request to `/docs` was also visible in Log Analytics:

Evidence:

![Browser request visible in Log Analytics](../images/05-monitoring/09-browser-request-visible-in-log-analytics.png)

## CrowdSec AppSec State

CrowdSec AppSec configurations and rules were present.

Evidence:

![CrowdSec AppSec rules configured](../images/05-monitoring/10-crowdsec-appsec-rules-configured.png)

Initial unauthenticated tests against suspicious paths produced `302` redirects because oauth2-proxy was in front of the application. This is expected:

```text
anonymous request -> oauth2-proxy auth redirect -> 302
```

Evidence:

![Unauthenticated env request redirected](../images/05-monitoring/11-unauthenticated-env-request-redirected.png)

Authenticated `.env` requests reached the backend and returned `404`, which showed that the request was passing through to FastAPI but was not yet blocked by AppSec.

Evidence:

![Authenticated env request reaches backend 404](../images/05-monitoring/12-authenticated-env-request-reaches-backend-404.png)

To avoid guessing, I inspected the active CrowdSec generic test rule. It defines an exact trigger path:

```text
/crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl
```

Evidence:

![CrowdSec generic test rule trigger path](../images/05-monitoring/13-crowdsec-generic-test-rule-trigger-path.png)

Before the NPMplus bouncer was enabled, the test path still reached the backend and returned `404`.

Evidence:

![CrowdSec test path reaches backend 404](../images/05-monitoring/14-crowdsec-test-path-reaches-backend-404.png)

I then confirmed that NPMplus did not yet have visible AppSec wiring in the generated nginx proxy host configuration and did not expose CrowdSec-related environment variables.

Evidence:

![NPMplus proxy host no AppSec config found](../images/05-monitoring/15-npmplus-proxy-host-no-appsec-config-found.png)

![NPMplus no CrowdSec env vars](../images/05-monitoring/16-npmplus-no-crowdsec-env-vars.png)

## Enabling the NPMplus CrowdSec Bouncer

The project handbook and setup script showed that CrowdSec was installed but the NPMplus bouncer was intentionally disabled at baseline.

The bouncer configuration was enabled in:

```text
/opt/npmplus/crowdsec/crowdsec.conf
```

The API key was treated as a secret and redacted in verification output.

Evidence:

![NPMplus CrowdSec bouncer enabled config redacted](../images/05-monitoring/17-npmplus-crowdsec-bouncer-enabled-config-redacted.png)

After enabling the bouncer, I restarted NPMplus:

```bash
cd /opt/npmplus
sudo docker compose restart npmplus
sudo docker ps
```

Evidence:

![NPMplus restarted after bouncer enable](../images/05-monitoring/18-npmplus-restarted-after-bouncer-enable.png)

Unauthenticated requests still returned `302`, which is correct because authentication happens first for anonymous requests.

Evidence:

![Anonymous WAF test redirected by auth](../images/05-monitoring/19-anonymous-waf-test-redirected-by-auth.png)

In an authenticated browser session, the CrowdSec test path was blocked with `403 Forbidden`.

Evidence:

![Authenticated WAF test blocked 403](../images/05-monitoring/20-authenticated-waf-test-blocked-403.png)

## WAF Blocks in Log Analytics

After waiting for ingestion, the `403` WAF blocks were visible in Log Analytics:

```text
77.64.146.237 | /crowdsec-test-NtktlJHV4TfBSK3wvlhiOBnl | 403
```

Evidence:

![WAF 403 events visible in Log Analytics](../images/05-monitoring/21-waf-403-events-visible-in-log-analytics.png)

Then I tested the Sentinel rule logic directly with a KQL query equivalent to the Terraform analytics rule:

```powershell
$query = "Syslog | where TimeGenerated > ago(30m) | where ProcessName == 'nginx' | extend log=parse_json(SyslogMessage) | extend StatusCode=toint(log.status), ClientIP=tostring(log.remote_addr), Uri=tostring(log.uri) | where StatusCode == 403 | where ClientIP != '127.0.0.1' | summarize WafBlocks=count(), Uris=make_set(Uri, 10), FirstSeen=min(TimeGenerated), LastSeen=max(TimeGenerated) by ClientIP | where WafBlocks >= 5"
az monitor log-analytics query -w $WORKSPACE_ID --analytics-query $query -o table
```

Evidence:

![Sentinel rule query condition matched](../images/05-monitoring/22-sentinel-rule-query-condition-matched.png)

This proved that the Log Analytics data matched the Sentinel analytics rule condition:

```text
StatusCode == 403
ClientIP != 127.0.0.1
WafBlocks >= 5
```

## Sentinel Incident and Automated NSG Response

Microsoft Sentinel created incidents with the title:

```text
WAF Attack - High Volume 403s from Single IP
```

Evidence:

![Sentinel incident created](../images/05-monitoring/23-sentinel-incident-created.png)

The automation playbook created an NSG deny rule:

```text
sentinel-block-77-64-146-237
Priority: 100
Source: 77.64.146.237
Access: Deny
Port: *
```

Evidence:

![NSG auto block rule created](../images/05-monitoring/24-nsg-auto-block-rule-created.png)

Because this was a controlled test from my own public IP, I removed the generated deny rule afterward:

```powershell
az network nsg rule delete --resource-group rg-lslukas --nsg-name nsg-app --name sentinel-block-77-64-146-237
```

The follow-up check returned no remaining `sentinel-block` rules.

Evidence:

![NSG auto block rule removed after test](../images/05-monitoring/25-nsg-auto-block-rule-removed-after-test.png)

## Result

Part 5 is complete.

The final monitoring and response chain is proven:

- NPMplus and CrowdSec were running.
- NPMplus access logs were forwarded to local syslog.
- Azure Monitor Agent sent syslog events to Log Analytics.
- Log Analytics parsed nginx JSON logs.
- CrowdSec AppSec blocked the authenticated test request with `403`.
- Sentinel matched the `5+` WAF block rule.
- Sentinel created high severity incidents.
- The automation playbook created an NSG deny rule.
- The test deny rule was removed afterward to restore normal access.

This completes the LearningSteps lockdown project from deployment to prevention, identity, data isolation, monitoring, detection, and automated response.

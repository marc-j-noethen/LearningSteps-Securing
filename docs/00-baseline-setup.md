# 00 - Baseline Setup

## Goal

Deploy the intentionally insecure LearningSteps baseline environment and verify that the core services are running before starting the daily security hardening tasks.

## Deployment Summary

- Resource group: `rg-lslukas`
- VM: `vm-lslukas`
- Domain: `lslukas.westeurope.cloudapp.azure.com`
- PostgreSQL server: `psql-lslukas.postgres.database.azure.com`
- NPMplus and CrowdSec installed on the VM
- oauth2-proxy installed but not started yet

## Evidence

| Evidence | What it proves |
|---|---|
| `images/00-baseline/Apply-Complete.png` | Terraform created the baseline Azure infrastructure successfully. |
| `images/00-baseline/npmplus-crowdsec-baseline-running.png` | NPMplus and CrowdSec baseline setup completed. |
| `images/00-baseline/docker-containers-npmplus-crowdsec-running.png` | Runtime verification that the containers are actually running. |

## Issue Encountered

During the first deployment run, the NPMplus/CrowdSec setup failed because Ubuntu's package manager lock was still held by another process.

Resolution:
- Waited for package manager activity to finish.
- Copied `setup-npmplus.sh` to the VM.
- Converted Windows line endings to Linux-compatible format.
- Re-ran the setup script successfully.

## Security Notes

The baseline is intentionally insecure and will be hardened over the next parts. Sensitive local deployment files are excluded from Git.
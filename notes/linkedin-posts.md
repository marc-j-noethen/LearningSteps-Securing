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
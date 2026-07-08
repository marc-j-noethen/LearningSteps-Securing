# Error Ledger

## 2026-07-06 - NPMplus/CrowdSec setup failed during baseline deployment

Observation:
The baseline deployment completed, but the NPMplus/CrowdSec setup failed with a package manager lock error.

Error:
`Could not get lock /var/lib/dpkg/lock-frontend`

Cause:
The Ubuntu VM was still running package manager activity shortly after provisioning.

Resolution:
Waited for the package manager process to finish, copied the setup script to the VM, fixed Windows line endings, and re-ran the setup successfully.

Prevention:
Expect package manager locks shortly after VM creation and validate post-install services with runtime checks such as `docker ps`.
# Security policy

## Reporting a vulnerability

Do not open a public issue. Use the repository host's private security advisory feature and provide affected paths, impact, reproduction steps, and suggested mitigation. Maintainers should acknowledge within three business days and coordinate disclosure after a fix.

## Supported versions

This proof of concept supports only the current default branch. Never place credentials, access tokens, production identifiers, customer data, Terraform state, or generated deployment logs containing sensitive values in commits or issues.

## Deployment warning

Review `deploy.sql` and `deploy-report.xml` before approving production. Replace all placeholders and enforce the controls described in `docs/security.md`.

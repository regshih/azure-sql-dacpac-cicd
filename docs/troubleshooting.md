# Troubleshooting

| Symptom | Checks |
|---|---|
| OIDC login fails | Confirm Environment name, exact federated subject, audience, client/tenant/subscription variables, and that the job has `id-token: write`. |
| SQL token login fails | Confirm the workflow principal is the configured Entra admin or a contained user; request a token for `https://database.windows.net/`; check tenant alignment. |
| Workflow remains queued | Confirm the repository runner is online and has the `azure-sql-private` label. Check its systemd service and outbound HTTPS access to GitHub. |
| SqlPackage timeout | From the runner, ensure `*.database.windows.net` resolves to the expected private IP and TCP 1433 is reachable. Confirm the private endpoint connection is approved. |
| Possible data loss blocked | Download `deploy.sql` and `deploy-report.xml`; review and approve an explicit migration rather than disabling protection blindly. |
| Build cannot resolve SDK | Confirm .NET 8 and NuGet connectivity; run `dotnet restore database/SqlDemo.sqlproj`. |
| Terraform auth prompt | Validation needs no Azure credentials after provider installation. Plans/applies use OIDC or Azure CLI context, never tfvars credentials. |
| Bicep parameter rejected | Replace all-zero GUIDs and ensure `uniqueSuffix` is 4–12 lowercase alphanumeric characters and names are globally unique. |

Deployment evidence uploads with `if: always()`. If report generation fails before files exist, the upload step warns rather than masking the primary error.

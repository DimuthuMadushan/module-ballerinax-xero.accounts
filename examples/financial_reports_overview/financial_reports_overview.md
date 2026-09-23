# Financial reports overview

This example prints an organisation's month-end position. It identifies the organisation, then prints the summary rows of the profit and loss report for the month and of the balance sheet and trial balance at month end.

## Prerequisites

- Ballerina Swan Lake 2201.13.4 or later
- A Xero app, refresh token and tenant ID, as described in the [setup guide](../../ballerina/README.md#setup-guide)
- Push the connector to the local repository:
  ```bash
  cd ../../ballerina
  bal pack && bal push --repository=local
  ```
- Create a `Config.toml` in this directory:
  ```toml
  clientId = "<CLIENT_ID>"
  clientSecret = "<CLIENT_SECRET>"
  refreshToken = "<REFRESH_TOKEN>"
  refreshUrl = "https://identity.xero.com/connect/token"
  tenantId = "<TENANT_ID>"
  periodStart = "2026-08-01"
  periodEnd = "2026-08-31"
  ```

## Run the example

```bash
bal run
```

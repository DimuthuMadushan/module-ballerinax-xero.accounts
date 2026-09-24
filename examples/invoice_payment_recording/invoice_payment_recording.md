# Invoice payment recording

This example records a customer payment against an existing sales invoice. It pays the invoice into one of the organisation's bank accounts, attaches a remittance note to the payment's history and prints the stored payment with its audit trail.

## Prerequisites

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
  invoiceId = "<INVOICE_ID>"
  bankAccountCode = "<BANK_ACCOUNT_CODE>"
  paymentAmount = 100.00
  paymentDate = "<YYYY-MM-DD>"
  ```

## Run the example

```bash
bal run
```

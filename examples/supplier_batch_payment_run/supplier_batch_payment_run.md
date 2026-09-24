# Supplier batch payment run

This example pays all of a supplier's outstanding bills in a single bank transaction. It finds the supplier's authorised bills that still have an amount due, settles them with one batch payment from a bank account, adds a note to the batch's history and reads the batch back.

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
  supplierContactId = "<SUPPLIER_CONTACT_ID>"
  bankAccountId = "<BANK_ACCOUNT_ID>"
  paymentDate = "<YYYY-MM-DD>"
  ```

## Run the example

```bash
bal run
```

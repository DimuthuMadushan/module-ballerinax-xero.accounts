# Customer invoice billing

This example onboards a new customer and bills them. It creates the customer contact, raises an approved sales invoice against it, optionally emails the invoice to the customer through Xero, and reads it back to confirm the total and the amount due.

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
  salesAccountCode = "200"
  # Replace with the customer's real billing address before enabling sendEmail.
  customerEmail = "<CUSTOMER_EMAIL>"
  invoiceDate = "<YYYY-MM-DD>"
  dueDate = "<YYYY-MM-DD>"
  # Sends a real email; needs an organisation that Xero permits to send email.
  sendEmail = false
  ```

## Run the example

```bash
bal run
```

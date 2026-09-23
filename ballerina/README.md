## Overview

[Xero](https://www.xero.com/) is a cloud-based accounting platform for small and medium-sized businesses, covering invoicing, bills, bank reconciliation, payments, payroll and financial reporting.

The Ballerina Xero Accounts connector lets you work with the [Xero Accounting API](https://developer.xero.com/documentation/api/accounting/overview) from Ballerina: manage contacts, invoices, credit notes, quotes, purchase orders, bank transactions and transfers, payments and batch payments, manual journals, items, tax rates and tracking categories, and read organisation settings and financial reports.

### Key features

- Create, update and track sales invoices, purchase bills, credit notes, quotes and purchase orders
- Manage contacts, contact groups, items and the chart of accounts
- Record payments, batch payments, overpayments, prepayments and allocations
- Work with bank transactions and bank transfers, including attachments and history notes
- Read organisation settings, tax rates, tracking categories and financial reports such as the balance sheet and profit and loss

## Setup guide

To use the connector you need a Xero account, an app registered in the Xero developer portal, an OAuth 2.0 refresh token and the ID of the organisation (tenant) to work with.

1. Sign up for a [Xero account](https://www.xero.com/signup/) if you do not already have one. A free [demo company](https://central.xero.com/s/article/Use-the-demo-company) is enough for development.

2. Sign in to the [Xero developer portal](https://developer.xero.com/app/manage) and select **New app**. Choose the **Web app** integration type, enter an app name, a company or application URL, and a redirect URI such as `http://localhost:8080/callback`, then create the app.

3. On the app's **Configuration** page, copy the **Client id** and generate a **Client secret**. Keep the secret safe; it is shown only once.

4. Obtain a refresh token with the [OAuth 2.0 authorization code flow](https://developer.xero.com/documentation/guides/oauth2/auth-flow). Open the authorization URL below in a browser, replacing the client ID and redirect URI with your own and requesting only the scopes your integration needs. `offline_access` is required to receive a refresh token.

   ```
   https://login.xero.com/identity/connect/authorize?response_type=code&client_id=<CLIENT_ID>&redirect_uri=<REDIRECT_URI>&scope=openid profile email offline_access accounting.transactions accounting.contacts accounting.settings accounting.reports.read&state=123
   ```

   After you approve access, Xero redirects to your redirect URI with a `code` query parameter. Exchange it for tokens:

   ```bash
   curl -X POST https://identity.xero.com/connect/token \
     -u "<CLIENT_ID>:<CLIENT_SECRET>" \
     -d grant_type=authorization_code \
     -d code=<CODE> \
     -d redirect_uri=<REDIRECT_URI>
   ```

   The response contains an `access_token` and a `refresh_token`.

5. Every Accounting API call is scoped to an organisation through the `xero-tenant-id` header. List the organisations the token can access and note the `tenantId` of the one you want:

   ```bash
   curl https://api.xero.com/connections -H "Authorization: Bearer <ACCESS_TOKEN>"
   ```

## Quickstart

To use the Xero Accounts connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `xero.accounts` module.

```ballerina
import ballerinax/xero.accounts;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file with the credentials from the setup guide:

    ```toml
    clientId = "<CLIENT_ID>"
    clientSecret = "<CLIENT_SECRET>"
    refreshToken = "<REFRESH_TOKEN>"
    refreshUrl = "https://identity.xero.com/connect/token"
    tenantId = "<TENANT_ID>"
    ```

2. Create an `accounts:Client` that refreshes its access token with those credentials:

    ```ballerina
    configurable string clientId = ?;
    configurable string clientSecret = ?;
    configurable string refreshToken = ?;
    configurable string refreshUrl = ?;
    configurable string tenantId = ?;

    final accounts:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });
    ```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations. Every operation takes the tenant ID in its headers record.

#### List the organisation's authorised sales invoices

```ballerina
public function main() returns error? {
    accounts:Invoices _ = check xero->getInvoices({xeroTenantId: tenantId}, statuses = ["AUTHORISED"]);
}
```

### Step 4: Run the Ballerina application

```bash
bal run
```

## Examples

The Xero Accounts connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-xero.accounts/tree/main/examples/), covering the following use cases:

1. [Customer invoice billing](../examples/customer_invoice_billing/customer_invoice_billing.md) - Creates a customer contact, raises an approved sales invoice, emails it and checks the amount due.
2. [Invoice payment recording](../examples/invoice_payment_recording/invoice_payment_recording.md) - Records a payment against a sales invoice, attaches a remittance note and prints the payment's audit history.
3. [Supplier batch payment run](../examples/supplier_batch_payment_run/supplier_batch_payment_run.md) - Pays all of a supplier's outstanding bills in one bank transaction with a batch payment.
4. [Financial reports overview](../examples/financial_reports_overview/financial_reports_overview.md) - Prints the month's profit and loss, the balance sheet and the trial balance for an organisation.

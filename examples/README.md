# Examples

The `ballerinax/xero.accounts` connector provides practical examples illustrating usage in various scenarios.

| Example | Description |
|---------|-------------|
| [`customer_invoice_billing`](./customer_invoice_billing/customer_invoice_billing.md) | Onboards a new customer and bills them. |
| [`invoice_payment_recording`](./invoice_payment_recording/invoice_payment_recording.md) | Records a customer payment against an existing sales invoice. |
| [`supplier_batch_payment_run`](./supplier_batch_payment_run/supplier_batch_payment_run.md) | Pays all of a supplier's outstanding bills in a single bank transaction. |
| [`financial_reports_overview`](./financial_reports_overview/financial_reports_overview.md) | Prints an organisation's month-end position. |

## Prerequisites

1. Complete the [setup guide](../ballerina/README.md#setup-guide) to obtain a client ID, client secret, refresh token and tenant ID.

2. For each example, create a `Config.toml` in the example directory with the required credentials and the example-specific values listed in its document:
   ```toml
   clientId = "<CLIENT_ID>"
   clientSecret = "<CLIENT_SECRET>"
   refreshToken = "<REFRESH_TOKEN>"
   refreshUrl = "https://identity.xero.com/connect/token"
   tenantId = "<TENANT_ID>"
   ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```

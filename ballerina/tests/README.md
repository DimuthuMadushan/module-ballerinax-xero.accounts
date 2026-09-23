# Tests

The test suite exercises 30 of the connector's 235 operations against a mock Xero Accounting API, covering the chart of accounts (`getAccounts`, `getAccount`, `createAccount`, `updateAccount`, `deleteAccount`), contacts (`getContacts`, `getContact`, `getContactByContactNumber`, `createContacts`, `updateContact`), invoices (`getInvoices`, `getInvoice`, `createInvoices`, `updateInvoice`, `emailInvoice`), items (`getItems`, `createItems`, `deleteItem`), payments and bank transactions (`getPayments`, `createPayment`, `getBankTransactions`, `createBankTransactions`, `getBatchPayment`), tracking categories (`getTrackingCategories`, `createTrackingCategory`, `deleteTrackingCategory`), and organisation, tax and report reads (`getOrganisations`, `getTaxRates`, `getTaxRateByTaxType`, `getReportBalanceSheet`). Every delete and update test creates the record it changes, so tests do not depend on execution order or shared fixtures.

## Running Tests

```bash
bal test
```

The test suite uses a mock server (`tests/mock_service.bal`) that intercepts HTTP calls so no real credentials are required.

### Running against Xero

Tests in the `live_tests` group can run against a real Xero organisation. Use a demo company: the tests create accounts, contacts, invoices, items and tracking categories. `testEmailInvoice`, `testCreatePayment`, `testCreateBankTransactions` and `testGetBatchPayment` run against the mock only, because they send email or need organisation-specific records.

```bash
export IS_LIVE_SERVER=true
export XERO_ACCESS_TOKEN=<access token>
export XERO_TENANT_ID=<tenant id>
bal test --groups live_tests
```

# Changelog

All notable changes to this project are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Remote methods for operations 1.5.2 did not cover:
  - Batch payments: `getBatchPayment`, `deleteBatchPayment` and `deleteBatchPaymentByUrlParam`.
  - Bank transfers: `deleteBankTransfers` and `deleteBankTransfer`.
  - Allocations: `deleteCreditNoteAllocations`, `deleteOverpaymentAllocations` and `deletePrepaymentAllocations`.
  - Repeating invoices: `createRepeatingInvoices`, `updateOrCreateRepeatingInvoices` and `updateRepeatingInvoice`.
  - `getJournalByNumber` and `getTaxRateByTaxType`.
- The records these methods use, and others the API now returns: `BatchPaymentDelete`, `BatchPaymentDeleteByUrlParam`, `BankTransferDelete`, `BankTransfersDelete`, `BankTransferDeleteByUrlParam`, `Pagination`, `TrackingReference`, `InvoiceAddress`, `TaxBreakdownComponent` and `LineItemItem`.
- A `*Headers` record for each operation, such as `GetAccountsHeaders` and `CreateInvoicesHeaders`, which carries its request headers, and a `*Queries` record, such as `GetInvoicesQueries`, which carries its query parameters.
- An optional `idempotencyKey` header on the methods that create, update or delete data.
- New query parameters: `pageSize` on the list methods that page (`getBankTransactions`, `getContacts`, `getCreditNotes`, `getInvoices`, `getManualJournals`, `getOverpayments`, `getPayments`, `getPrepayments` and `getPurchaseOrders`), `searchTerm` on `getContacts` and `getInvoices`, `references` on `getBankTransactions`, `getOverpayments` and `getPrepayments`, `invoiceNumbers` on `getPrepayments`, `includeDeleted` on `getBankTransfers`, `dateFrom` and `dateTo` on `getBudget`, and `allowBackorders` on `createInvoices`, `updateOrCreateInvoices` and `updateInvoice`.
- New record fields, among them `pagination` and `warnings` on the list results (such as `Invoices` and `Contacts`), `Allocation.allocationID` and `isDeleted`, `BankTransfer.reference`, `status`, `fromTracking` and `toTracking`, `Contact.companyNumber`, `taxNumberType` and `mergedToContactID`, `Invoice.invoiceAddresses`, `LineItem.taxBreakdown` and `item`, and `Item.quantityAvailable`.
- New `ConnectionConfig` fields, taken from `http:ClientConfiguration`: `followRedirects`, `cookieConfig`, `socketConfig` and `laxDataBinding`.

### Changed

- **Breaking:** the Xero tenant ID and the other request headers are no longer positional parameters. `xeroTenantId`, `ifModifiedSince` and `contentType` are passed in the operation's `*Headers` record, which follows the path parameters. Query parameters such as `where`, `order`, `page` and `unitdp` are passed as named arguments, or as the operation's `*Queries` record:

    ```ballerina
    // 1.5.2
    xero:Accounts accounts = check xero->getAccounts(tenantId, 'where = "Status==\"ACTIVE\"");
    xero:Invoices invoice = check xero->getInvoice(tenantId, invoiceId, 2);
    ```

    ```ballerina
    // 2.0.0
    xero:Accounts accounts = check xero->getAccounts({xeroTenantId: tenantId}, 'where = "Status==\"ACTIVE\"");
    xero:Invoices invoice = check xero->getInvoice(invoiceId, {xeroTenantId: tenantId}, unitdp = 2);
    ```

- **Breaking:** the methods that download an attachment, such as `getInvoiceAttachmentById` and `getContactAttachmentByFileName`, return `byte[]` (was `string`).
- **Breaking:** `getCreditNoteAsPdf`, `getInvoiceAsPdf`, `getPurchaseOrderAsPdf` and `getQuoteAsPdf` return `http:Response` (was `string`).
- **Breaking:** `deleteContactGroupContacts`, `deleteContactGroupContact`, `emailInvoice`, `deleteItem` and `deleteLinkedTransaction` return `error?` (was `http:Response|error`).
- **Breaking:** `createBrandingThemePaymentServices` takes a `PaymentServices` payload (was `PaymentService`).
- **Breaking:** most record fields use camel case, mapped to the API's Pascal-case JSON names with `@jsondata:Name`. For example, `Account.AccountID` is now `accountID`, `Invoice.LineItems` is now `lineItems`, and `Accounts.Accounts` is now `accounts`.
- **Breaking:** fields and aliases that take a fixed set of values are string-literal unions (were `string`). For example, `Account.status` is `"ACTIVE"|"ARCHIVED"|"DELETED"`, and `AccountType`, `CurrencyCode`, `CountryCode`, `LineAmountTypes` and `TimeZone` are unions of their values. The `status` query parameter of `getPurchaseOrders` and the `timeframe` query parameter of `getReportBalanceSheet` and `getReportProfitAndLoss` are unions too.
- **Breaking:** some field types are corrected: `BatchPayment.totalAmount` is `decimal` (was `string`), `BatchPayment.isReconciled` is `boolean` (was `string`), `BudgetBalance.amount` and `unitAmount` are `decimal` (were `int`), and the `ImportSummaryAccounts` counts are `int:Signed32` (were `int`).
- **Breaking:** `ConnectionConfig.http1Settings` is now `http:ClientHttp1Settings` (was the connector's own `ClientHttp1Settings`).
- Boolean flags such as `hasAttachments`, `hasErrors` and `hasValidationErrors` default to `false` (were optional).
- `ConnectionConfig.timeout` defaults to 30 seconds (was 60).

### Removed

- **Breaking:** the employee methods `getEmployees`, `createEmployees`, `updateOrCreateEmployees` and `getEmployee`, with the `Employee` and `Employees` records.
- **Breaking:** the `taxType` query parameter of `getTaxRates`. Use `getTaxRateByTaxType` to fetch a tax rate by its tax type.
- **Breaking:** `Contact.SkypeUserName`.
- **Breaking:** the `TaxType`, `Element` and `Error` types. No method took or returned them, directly or through another record.
- **Breaking:** the connector's own `ClientHttp1Settings` and `ProxyConfig` records. Use `http:ClientHttp1Settings` and `http:ProxyConfig` instead.

_Author_: @DimuthuMadushan \
_Created_: 2026/09/23 \
_Updated_: 2026/09/23 \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Xero Accounts. 
The OpenAPI specification is obtained from the [Xero Accounting API 19.0.0 specification](https://github.com/wso2/api-specs/blob/main/openapi/xero/accounts/19.0.0/openapi.yaml) (`openapi/xero/accounts/19.0.0/openapi.yaml` in `api-specs`), which is Xero's own `xero_accounting.yaml` from [XeroAPI/Xero-OpenAPI](https://github.com/XeroAPI/Xero-OpenAPI).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

`docs/spec/openapi.yaml` is the upstream file, unmodified. Every change below is applied to `docs/spec/aligned_ballerina_openapi.json`, after `bal openapi flatten` and `bal openapi align`. `flatten` and `align` themselves made no structural changes to this specification: no server URL, path prefix, format, nullability or type changes.

1. **Converted the aligned YAML to JSON without timestamp coercion**
   **Original**: The response examples contain unquoted date-times (for example `UpdatedDateUTC: 2019-02-25T16:12:31`).
   **Updated**: 169 example values are kept as the strings written in the specification.
   **Reason**: PyYAML resolves unquoted date-times to `datetime` objects, which the JSON encoder rejects, so the plugin's YAML-to-JSON conversion fails. Loading without the timestamp resolver keeps the values unchanged.

2. **Removed the unreferenced `Employee` schema**
   **Original**: `components.schemas.Employee` is defined, but no operation or schema references it.
   **Updated**: Deleted.
   **Reason**: The Employees operations are no longer part of the Xero Accounting API specification, so the schema is a dangling type. Removing it keeps the connector's public types in line with its operations.

3. **Added descriptions to 163 undocumented schema properties**
   **Original**: 163 properties had no description (for example `Invoice.Contact`, `Pagination.page`, the list fields such as `Invoices.Invoices`, and `pagination` on every paged response).
   **Updated**: Each property has a description derived from its schema and purpose (for example "Contact associated with the invoice", "List of invoices", "Pagination details of the returned page of results").
   **Reason**: Undocumented properties produce undocumented record fields in the generated `types.bal`.

4. **Wrapped 11 bare `$ref` properties in `allOf`**
   **Original**: The `pagination` properties (and `Setup.ConversionDate`, `ImportSummaryObject.ImportSummary`) were a bare `$ref`.
   **Updated**: `allOf: [{$ref: ...}]` with a sibling `description`.
   **Reason**: OpenAPI 3.0 ignores keys beside a bare `$ref`, so the description added in item 3 would otherwise be dropped from the generated field.

5. **Filled four empty operation summaries**
   **Original**: `PUT` and `POST` `/BankTransfers/{bankTransferID}/Attachments/{fileName}` and `/Contacts/{contactID}/Attachments/{fileName}` had an empty summary.
   **Updated**: For example, "Uploads an attachment to a specific bank transfer by file name" and "Updates an attachment on a specific contact by file name".
   **Reason**: The summary becomes the remote method's doc comment.

6. **Corrected summaries that contradict their operation**
   **Original**: `deleteBatchPayment` and `deleteBatchPaymentByUrlParam` read "Updates a specific batch payment for invoices and credit notes", `deletePayment` read "Updates a specific payment for invoices and credit notes", `updateRepeatingInvoice` read "Deletes a specific repeating invoice template", and `createCreditNoteHistory` repeated `getCreditNoteHistory`'s "Retrieves history records of a specific credit note".
   **Updated**: "Deletes one or more batch payments by setting their status to DELETED", "Deletes a specific batch payment by setting its status to DELETED", "Deletes a specific payment by setting its status to DELETED", "Updates or deletes a specific repeating invoice template" and "Creates a history record for a specific credit note".
   **Reason**: Xero deletes these records with a `POST` that sets `Status` to `DELETED`, so the operationIds are right and the summaries were wrong, or were copied from a sibling operation.

7. **Added descriptions to 24 inline request bodies**
   **Original**: 24 request bodies (for example `POST /Invoices`, `POST /BatchPayments`) had no description.
   **Updated**: A one-line description of each payload, for example "Sales invoices or purchase bills to create or update".
   **Reason**: The request body description becomes the `payload` parameter's doc comment.

8. **Kept Xero's operationIds and schema names unchanged**
   **Original**: 235 operationIds and 137 schema names.
   **Updated**: No change. The decisions are recorded as identity mappings in `ai-mappings.json`.
   **Reason**: The operationIds are the remote method names that `ballerinax/xero.accounts` 1.x published. Keeping them keeps every surviving 1.x method name. Twelve of them exceed the plugin's 37-character guideline (for example `createRepeatingInvoiceAttachmentByFileName`), but renaming them would break existing callers.

The connector uses remote methods (`--client-methods remote`), as 1.x did. The specification has 14 pairs of `GET` operations whose paths differ only in the parameter name, for example `/Contacts/{ContactID}` and `/Contacts/{ContactNumber}`, and `/Invoices/{InvoiceID}/Attachments/{AttachmentID}` and `/Invoices/{InvoiceID}/Attachments/{FileName}`. These cannot coexist as resource methods, and `/Reports/{ReportID}` sits beside nine literal `/Reports/<name>` paths.

## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
bal openapi -i docs/spec/aligned_ballerina_openapi.json --mode client --client-methods remote --license docs/license.txt -o ballerina
```
Note: The license year is 2026, as set in `docs/license.txt`.

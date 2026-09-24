// Copyright (c) 2026, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/data.jsondata;
import ballerina/http;
import ballerina/uuid;

listener http:Listener ep0 = new (9090);

// Contacts the mock knows about, keyed by both ContactID and ContactNumber so that
// `GET /Contacts/{identifier}` serves getContact and getContactByContactNumber alike.
// Seeded with the contacts `GET /Contacts` lists; `PUT /Contacts` adds to it.
isolated map<Contact> contactStore = seedContacts();

isolated function seedContacts() returns map<Contact> {
    Contact[] seed = [
        {
            contactID: "bd2270c3-8706-4c11-9cfb-000b551c3f51",
            contactNumber: "SB2",
            name: "ABC Limited",
            emailAddress: "a.dutchess@abclimited.com",
            contactStatus: "ACTIVE",
            addresses: [{addressType: "STREET", addressLine1: "18 Main Street", city: "Wellington", postalCode: "6011", country: "New Zealand"}],
            phones: [{phoneType: "DEFAULT", phoneNumber: "4912345", phoneAreaCode: "04", phoneCountryCode: "64"}],
            isCustomer: true,
            isSupplier: false
        },
        {contactID: "8138a266-fb42-49b2-a104-014b7045753d", contactNumber: "SB3", name: "Boom FM", emailAddress: "accounts@boomfm.com", contactStatus: "ACTIVE", isCustomer: true, isSupplier: true}
    ];
    map<Contact> store = {};
    foreach Contact contact in seed {
        store[contact.contactID ?: ""] = contact;
        store[contact.contactNumber ?: ""] = contact;
    }
    return store;
}

isolated function storeContact(Contact contact) {
    lock {
        foreach string? key in [contact.contactID, contact.contactNumber] {
            if key is string {
                contactStore[key] = contact.clone();
            }
        }
    }
}

service / on ep0 {
    # Deletes a chart of accounts
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + accountID - Unique identifier for Account object
    # + return - returns can be any of following types 
    # http:Ok (Success - delete existing Account and return response of type Accounts array with deleted Account)
    # http:BadRequest (Validation Error - some data was incorrect returns response of type Error)
    resource function delete Accounts/[string accountID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns Accounts|ErrorBadRequest {
        return {accounts: [{accountID, code: "091", name: "Business Savings Account", status: "DELETED", 'type: "BANK", currencyCode: "NZD"}]};
    }

    # Deletes a specific item
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + itemID - Unique identifier for an Item
    # + return - returns can be any of following types 
    # http:NoContent (Success - return response 204 no content)
    # http:BadRequest (A failed request due to validation error)
    resource function delete Items/[string itemID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns http:NoContent|ErrorBadRequest {
        return http:NO_CONTENT;
    }

    # Deletes a specific tracking category
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + trackingCategoryID - Unique identifier for a TrackingCategory
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type TrackingCategories array of deleted TrackingCategory)
    # http:BadRequest (A failed request due to validation error)
    resource function delete TrackingCategories/[string trackingCategoryID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns TrackingCategories|ErrorBadRequest {
        return {trackingCategories: [{trackingCategoryID, name: "Region", status: "DELETED"}]};
    }

    # Retrieves the full chart of accounts
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + return - Success - return response of type Accounts array with 0 to n Account 
    resource function get Accounts(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order) returns Accounts {
        return {
            accounts: [
                {accountID: "ebd06280-af70-4bed-97c6-7451a454ad85", code: "091", name: "Business Savings Account", 'type: "BANK", taxType: "NONE", status: "ACTIVE", bankAccountNumber: "0209087654321050", bankAccountType: "BANK", currencyCode: "NZD", enablePaymentsToAccount: false},
                {accountID: "7d05a53d-613d-4eb2-a2fc-dcb6adb80b80", code: "200", name: "Sales", 'type: "REVENUE", taxType: "OUTPUT2", status: "ACTIVE", description: "Income from any normal business activity", enablePaymentsToAccount: false}
            ]
        };
    }

    # Retrieves a single chart of accounts by using a unique account Id
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + accountID - Unique identifier for Account object
    # + return - Success - return response of type Accounts array with one Account 
    resource function get Accounts/[string accountID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns Accounts {
        return {accounts: [{accountID, code: "200", name: "Sales", 'type: "REVENUE", taxType: "OUTPUT2", status: "ACTIVE", 'class: "REVENUE", description: "Income from any normal business activity"}]};
    }

    # Retrieves any spent or received money transactions
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + page - Up to 100 bank transactions will be returned in a single API call with line items details
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + pageSize - Number of records to retrieve per page
    # + references - Filter by a comma-separated list of References
    # + return - Success - return response of type BankTransactions array with 0 to n BankTransaction 
    resource function get BankTransactions(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order, int? page, int? unitdp, int? pageSize, @http:Query {name: "References"} string[]? references) returns BankTransactions {
        return {
            bankTransactions: [
                {
                    bankTransactionID: "db54aab0-ad40-4ced-bcff-0940ba20db2c",
                    'type: "SPEND",
                    status: "AUTHORISED",
                    date: "2019-02-25",
                    reference: "Office supplies",
                    bankAccount: {accountID: "6f7594f2-f059-4d56-9e67-47ac9733bfe9", code: "088", name: "Business Wells Fargo"},
                    contact: {contactID: "3ec601ad-eea0-4c51-9b0a-5a0e5e3f6d6f", name: "Staples"},
                    lineItems: [{description: "Printer paper", quantity: 2, unitAmount: 20.00, accountCode: "429", lineAmount: 40.00}],
                    lineAmountTypes: "Exclusive",
                    subTotal: 40.00,
                    totalTax: 0.00,
                    total: 40.00,
                    currencyCode: "USD",
                    isReconciled: false
                }
            ],
            pagination: {page: 1, pageSize: 100, pageCount: 1, itemCount: 1}
        };
    }

    # Retrieves a specific batch payment using a unique batch payment Id
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + batchPaymentID - Unique identifier for BatchPayment
    # + return - Success - return response of type BatchPayments array with matching batch payment Id 
    resource function get BatchPayments/[string batchPaymentID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns BatchPayments {
        return {
            batchPayments: [
                {
                    batchPaymentID,
                    'type: "PAYBATCH",
                    status: "AUTHORISED",
                    date: "2024-03-15",
                    reference: "March supplier run",
                    account: {accountID: "56e8a1f2-3b4c-4d5e-8f90-1a2b3c4d5e6f", code: "090", name: "Business Bank Account"},
                    totalAmount: 1250.00,
                    isReconciled: false,
                    payments: [{paymentID: "7b1c3d2e-4f5a-4b6c-8d7e-9f0a1b2c3d4e", amount: 1250.00, invoiceNumber: "INV-0042"}]
                }
            ]
        };
    }

    # Retrieves all contacts in a Xero organisation
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + iDs - Filter by a comma separated list of ContactIDs. Allows you to retrieve a specific set of contacts in a single call
    # + page - e.g. page=1 - Up to 100 contacts will be returned in a single API call
    # + includeArchived - e.g. includeArchived=true - Contacts with a status of ARCHIVED will be included in the response
    # + summaryOnly - Use summaryOnly=true in GET Contacts and Invoices endpoint to retrieve a smaller version of the response object. This returns only lightweight fields, excluding computation-heavy fields from the response, making the API calls quick and efficient
    # + searchTerm - Search parameter that performs a case-insensitive text search across the Name, FirstName, LastName, ContactNumber and EmailAddress fields
    # + pageSize - Number of records to retrieve per page
    # + return - Success - return response of type Contacts array with 0 to N Contact 
    resource function get Contacts(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order, @http:Query {name: "IDs"} string[]? iDs, int? page, boolean? includeArchived, string? searchTerm, int? pageSize, boolean summaryOnly = false) returns Contacts {
        return {
            contacts: [
                {contactID: "bd2270c3-8706-4c11-9cfb-000b551c3f51", contactNumber: "SB2", name: "ABC Limited", firstName: "Andrea", lastName: "Dutchess", emailAddress: "a.dutchess@abclimited.com", contactStatus: "ACTIVE", isCustomer: true, isSupplier: false, defaultCurrency: "NZD"},
                {contactID: "8138a266-fb42-49b2-a104-014b7045753d", contactNumber: "SB3", name: "Boom FM", emailAddress: "accounts@boomfm.com", contactStatus: "ACTIVE", isCustomer: true, isSupplier: true, defaultCurrency: "NZD"}
            ],
            pagination: {page: page ?: 1, pageSize: pageSize ?: 100, pageCount: 1, itemCount: 2}
        };
    }

    # Retrieves a specific contacts in a Xero organisation using a unique contact Id
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + contactID - Unique identifier for a Contact
    # + return - Success - return response of type Contacts array with a unique Contact 
    resource function get Contacts/[string contactID](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns Contacts {
        lock {
            Contact? contact = contactStore[contactID];
            if contact is () {
                return {contacts: []};
            }
            return {contacts: [contact.clone()]};
        }
    }

    # Retrieves sales invoices or purchase bills
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + iDs - Filter by a comma-separated list of InvoicesIDs
    # + invoiceNumbers - Filter by a comma-separated list of InvoiceNumbers
    # + contactIDs - Filter by a comma-separated list of ContactIDs
    # + statuses - Filter by a comma-separated list Statuses. For faster response times we recommend using these explicit parameters instead of passing OR conditions into the Where filter
    # + page - e.g. page=1 – Up to 100 invoices will be returned in a single API call with line items shown for each invoice
    # + includeArchived - e.g. includeArchived=true - Invoices with a status of ARCHIVED will be included in the response
    # + createdByMyApp - When set to true you'll only retrieve Invoices created by your app
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + summaryOnly - Use summaryOnly=true in GET Contacts and Invoices endpoint to retrieve a smaller version of the response object. This returns only lightweight fields, excluding computation-heavy fields from the response, making the API calls quick and efficient
    # + pageSize - Number of records to retrieve per page
    # + searchTerm - Search parameter that performs a case-insensitive text search across the fields e.g. InvoiceNumber, Reference
    # + return - Success - return response of type Invoices array with all Invoices 
    resource function get Invoices(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order, @http:Query {name: "IDs"} string[]? iDs, @http:Query {name: "InvoiceNumbers"} string[]? invoiceNumbers, @http:Query {name: "ContactIDs"} string[]? contactIDs, @http:Query {name: "Statuses"} string[]? statuses, int? page, boolean? includeArchived, boolean? createdByMyApp, int? unitdp, int? pageSize, string? searchTerm, boolean summaryOnly = false) returns Invoices {
        return {
            invoices: [
                {
                    invoiceID: "d4956132-ed94-4dd7-9eaa-aa22dfdf06f2",
                    invoiceNumber: "INV-0001",
                    'type: "ACCREC",
                    status: "AUTHORISED",
                    contact: {contactID: "bd2270c3-8706-4c11-9cfb-000b551c3f51", name: "ABC Limited"},
                    date: "2024-03-01",
                    dueDate: "2024-03-31",
                    lineAmountTypes: "Exclusive",
                    subTotal: 500.00,
                    totalTax: 75.00,
                    total: 575.00,
                    amountDue: 575.00,
                    amountPaid: 0.00,
                    currencyCode: "NZD"
                }
            ],
            pagination: {page: page ?: 1, pageSize: pageSize ?: 100, pageCount: 1, itemCount: 1}
        };
    }

    # Retrieves a specific sales invoice or purchase bill using a unique invoice Id
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + invoiceID - Unique identifier for an Invoice
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + return - Success - return response of type Invoices array with specified Invoices 
    resource function get Invoices/[string invoiceID](@http:Header {name: "xero-tenant-id"} string xeroTenantId, int? unitdp) returns Invoices {
        return {
            invoices: [
                {
                    invoiceID,
                    invoiceNumber: "INV-0001",
                    'type: "ACCREC",
                    status: "AUTHORISED",
                    contact: {contactID: "bd2270c3-8706-4c11-9cfb-000b551c3f51", name: "ABC Limited"},
                    date: "2024-03-01",
                    dueDate: "2024-03-31",
                    lineItems: [{description: "Consulting services", quantity: 10, unitAmount: 50.00, accountCode: "200", taxType: "OUTPUT2", lineAmount: 500.00}],
                    lineAmountTypes: "Exclusive",
                    subTotal: 500.00,
                    totalTax: 75.00,
                    total: 575.00,
                    amountDue: 575.00,
                    currencyCode: "NZD"
                }
            ]
        };
    }

    # Retrieves items
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + return - Success - return response of type Items array with all Item 
    resource function get Items(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order, int? unitdp) returns Items {
        return {
            items: [
                {itemID: "c8c54d65-f3f2-452a-8433-2b6a8ec2d32e", code: "BOOK", name: "Fiction Books", description: "Paperback fiction titles", isSold: true, isPurchased: true, salesDetails: {unitPrice: 19.95, accountCode: "200", taxType: "OUTPUT2"}, purchaseDetails: {unitPrice: 12.50, accountCode: "300", taxType: "INPUT2"}},
                {itemID: "9a59ea90-942e-484d-9b71-d00ab607e03b", code: "MUG", name: "Coffee Mug", isSold: true, isPurchased: false, salesDetails: {unitPrice: 9.00, accountCode: "200"}}
            ]
        };
    }

    # Retrieves Xero organisation details
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + return - Success - return response of type Organisation array with all Organisation 
    resource function get Organisation(@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns Organisations {
        return {
            organisations: [
                {
                    organisationID: "b2c885a9-4bb9-4a00-9b6e-6c2bf60b1a2b",
                    name: "Demo Company (NZ)",
                    legalName: "Demo Company (NZ)",
                    shortCode: "!c0s5T",
                    version: "NZ",
                    organisationType: "COMPANY",
                    baseCurrency: "NZD",
                    countryCode: "NZ",
                    isDemoCompany: true,
                    organisationStatus: "ACTIVE",
                    financialYearEndDay: 31,
                    financialYearEndMonth: 3,
                    timezone: "NEWZEALANDSTANDARDTIME"
                }
            ]
        };
    }

    # Retrieves payments for invoices and credit notes
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + ifModifiedSince - Only records created or modified since this timestamp will be returned
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + page - Up to 100 payments will be returned in a single API call
    # + pageSize - Number of records to retrieve per page
    # + return - Success - return response of type Payments array for all Payments 
    resource function get Payments(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "If-Modified-Since"} string? ifModifiedSince, string? 'where, string? 'order, int? page, int? pageSize) returns Payments {
        return {
            payments: [
                {
                    paymentID: "99ea7f6b-c7cd-4b6c-a2e3-d2b1e0b7d5c0",
                    date: "2024-03-10",
                    amount: 575.00,
                    reference: "INV-0001 payment",
                    status: "AUTHORISED",
                    paymentType: "ACCRECPAYMENT",
                    invoice: {invoiceID: "d4956132-ed94-4dd7-9eaa-aa22dfdf06f2", invoiceNumber: "INV-0001"},
                    account: {accountID: "ebd06280-af70-4bed-97c6-7451a454ad85", code: "090"},
                    isReconciled: true
                }
            ],
            pagination: {page: page ?: 1, pageSize: pageSize ?: 100, pageCount: 1, itemCount: 1}
        };
    }

    # Retrieves report for balancesheet
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + date - The date of the Balance Sheet report
    # + periods - The number of periods for the Balance Sheet report
    # + timeframe - The period size to compare to (MONTH, QUARTER, YEAR)
    # + trackingOptionID1 - The tracking option 1 for the Balance Sheet report
    # + trackingOptionID2 - The tracking option 2 for the Balance Sheet report
    # + standardLayout - The standard layout boolean for the Balance Sheet report
    # + paymentsOnly - return a cash basis for the Balance Sheet report
    # + return - Success - return response of type ReportWithRows 
    resource function get Reports/BalanceSheet(@http:Header {name: "xero-tenant-id"} string xeroTenantId, string? date, int? periods, "MONTH"|"QUARTER"|"YEAR"? timeframe, string? trackingOptionID1, string? trackingOptionID2, boolean? standardLayout, boolean? paymentsOnly) returns ReportWithRows {
        return {
            reports: [
                {
                    ReportID: "BalanceSheet",
                    ReportName: "Balance Sheet",
                    ReportType: "BalanceSheet",
                    ReportTitles: ["Balance Sheet", "Demo Company (NZ)", "As at 31 March 2024"],
                    ReportDate: date ?: "31 March 2024",
                    Rows: [
                        {rowType: "Header", cells: [{value: ""}, {value: "31 Mar 2024"}]},
                        {rowType: "Section", title: "Bank", rows: [{rowType: "Row", cells: [{value: "Business Bank Account"}, {value: "12500.00"}]}]}
                    ]
                }
            ]
        };
    }

    # Retrieves tax rates
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + return - Success - return response of type TaxRates array with TaxRates 
    resource function get TaxRates(@http:Header {name: "xero-tenant-id"} string xeroTenantId, string? 'where, string? 'order) returns TaxRates {
        return {
            taxRates: [
                {name: "15% GST on Income", taxType: "OUTPUT2", status: "ACTIVE", displayTaxRate: 15.0, effectiveRate: 15.0, canApplyToRevenue: true, taxComponents: [{name: "GST", rate: 15.0, isCompound: false, isNonRecoverable: false}]},
                {name: "No GST", taxType: "NONE", status: "ACTIVE", displayTaxRate: 0.0, effectiveRate: 0.0, canApplyToExpenses: true, canApplyToRevenue: true}
            ]
        };
    }

    # Retrieves a specific tax rate according to given TaxType code
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + taxType - A valid TaxType code
    # + return - Success - return response of type TaxRates array with one TaxRate 
    resource function get TaxRates/[string taxType](@http:Header {name: "xero-tenant-id"} string xeroTenantId) returns TaxRates {
        return {taxRates: [{name: "15% GST on Income", taxType, status: "ACTIVE", displayTaxRate: 15.0, effectiveRate: 15.0, taxComponents: [{name: "GST", rate: 15.0, isCompound: false, isNonRecoverable: false}]}]};
    }

    # Retrieves tracking categories and options
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + 'where - Filter by an any element
    # + 'order - Order by an any element
    # + includeArchived - e.g. includeArchived=true - Categories and options with a status of ARCHIVED will be included in the response
    # + return - Success - return response of type TrackingCategories array of TrackingCategory 
    resource function get TrackingCategories(@http:Header {name: "xero-tenant-id"} string xeroTenantId, string? 'where, string? 'order, boolean? includeArchived) returns TrackingCategories {
        return {
            trackingCategories: [
                {
                    trackingCategoryID: "351953c4-8127-4009-88c3-f9cd8c9cbe9f",
                    name: "Region",
                    status: "ACTIVE",
                    options: [
                        {trackingOptionID: "ce205173-7387-4651-9726-2cf4c5405ba2", name: "North", status: "ACTIVE"},
                        {trackingOptionID: "4c8b4a6c-8d3c-4f0e-8b5e-2d6a1f0c9e7b", name: "South", status: "ACTIVE"}
                    ]
                }
            ]
        };
    }

    # Updates a chart of accounts
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + accountID - Unique identifier for Account object
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Request of type Accounts array with one Account 
    # + return - returns can be any of following types 
    # http:Ok (Success - update existing Account and return response of type Accounts array with updated Account)
    # http:BadRequest (Validation Error - some data was incorrect returns response of type Error)
    resource function post Accounts/[string accountID](@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Accounts payload) returns AccountsOk|ErrorBadRequest {
        Account[] updated = [];
        foreach Account a in payload.accounts ?: [] {
            Account account = a.clone();
            account.accountID = accountID;
            updated.push(account);
        }
        return <AccountsOk>{body: {accounts: updated}};
    }

    # Updates a specific contact in a Xero organisation
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + contactID - Unique identifier for a Contact
    # + payload - an array of Contacts containing single Contact object with properties to update 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Contacts array with an updated Contact)
    # http:BadRequest (A failed request due to validation error)
    resource function post Contacts/[string contactID](@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Contacts payload) returns ContactsOk|ErrorBadRequest {
        Contact[] updated = [];
        foreach Contact c in payload.contacts ?: [] {
            Contact contact = c.clone();
            contact.contactID = contactID;
            contact.contactStatus = "ACTIVE";
            updated.push(contact);
        }
        return <ContactsOk>{body: {contacts: updated}};
    }

    # Updates a specific sales invoices or purchase bills
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + invoiceID - Unique identifier for an Invoice
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + allowBackorders - Allows an invoice to be created even when one or more line items contain tracked inventory where the invoice quantity would cause the available quantity to go negative
    # + payload - Invoice with the fields to update 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Invoices array with updated Invoice)
    # http:BadRequest (A failed request due to validation error)
    resource function post Invoices/[string invoiceID](@http:Header {name: "xero-tenant-id"} string xeroTenantId, int? unitdp, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, boolean? allowBackorders, @http:Payload Invoices payload) returns InvoicesOk|ErrorBadRequest {
        Invoice[] updated = [];
        foreach Invoice inv in payload.invoices ?: [] {
            Invoice invoice = inv.clone();
            invoice.invoiceID = invoiceID;
            invoice.status = inv.status ?: "DRAFT";
            updated.push(invoice);
        }
        return <InvoicesOk>{body: {invoices: updated}};
    }

    # Sends a copy of a specific invoice to related contact via email
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + invoiceID - Unique identifier for an Invoice
    # + payload - Empty request body that triggers the invoice email 
    # + return - returns can be any of following types 
    # http:NoContent (Success - return response 204 no content)
    # http:BadRequest (A failed request due to validation error)
    resource function post Invoices/[string invoiceID]/Email(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload RequestEmpty payload) returns http:NoContent|ErrorBadRequest {
        return http:NO_CONTENT;
    }

    # Creates a single payment for invoice or credit notes
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Request body with a single Payment object 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Payments array for newly created Payment)
    # http:BadRequest (A failed request due to validation error)
    resource function post Payments(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Payment payload) returns PaymentsOk|ErrorBadRequest {
        Payment payment = payload.clone();
        payment.paymentID = "0d666415-cf77-43fa-80c7-56775591d426";
        payment.status = "AUTHORISED";
        payment.paymentType = "ACCRECPAYMENT";
        return <PaymentsOk>{body: {payments: [payment]}};
    }

    # Creates a new chart of accounts
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Account object in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - created new Account and return response of type Accounts array with new Account)
    # http:BadRequest (Validation Error - some data was incorrect returns response of type Error)
    resource function put Accounts(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Account payload) returns Accounts|ErrorBadRequest {
        Account account = payload.clone();
        account.accountID = "66b262ff-4e5c-4b53-8b68-4b2e2b6f1b3c";
        account.status = "ACTIVE";
        return {accounts: [account]};
    }

    # Creates one or more spent or received money transaction
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + summarizeErrors - If false return 200 OK and mix of successfully created objects and any with validation errors
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - BankTransactions with an array of BankTransaction objects in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type BankTransactions array with new BankTransaction)
    # http:BadRequest (A failed request due to validation error)
    resource function put BankTransactions(@http:Header {name: "xero-tenant-id"} string xeroTenantId, int? unitdp, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload BankTransactions payload, boolean summarizeErrors = false) returns BankTransactions|ErrorBadRequest {
        BankTransaction[] created = [];
        foreach BankTransaction t in payload.bankTransactions ?: [] {
            BankTransaction txn = t.clone();
            txn.bankTransactionID = "f0d12f1a-0b9f-4a8f-9f7e-3c2d1b0a9e8d";
            txn.status = "AUTHORISED";
            created.push(txn);
        }
        return {bankTransactions: created};
    }

    # Creates multiple contacts (bulk) in a Xero organisation
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + summarizeErrors - If false return 200 OK and mix of successfully created objects and any with validation errors
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Contacts with an array of Contact objects to create in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Contacts array with newly created Contact)
    # http:BadRequest (Validation Error - some data was incorrect returns response of type Error)
    resource function put Contacts(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Contacts payload, boolean summarizeErrors = false) returns Contacts|ErrorBadRequest {
        Contact[] created = [];
        foreach Contact c in payload.contacts ?: [] {
            Contact contact = c.clone();
            contact.contactID = uuid:createType4AsString();
            contact.contactStatus = "ACTIVE";
            storeContact(contact);
            created.push(contact);
        }
        return {contacts: created};
    }

    # Creates one or more sales invoices or purchase bills
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + summarizeErrors - If false return 200 OK and mix of successfully created objects and any with validation errors
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + allowBackorders - Allows an invoice to be created even when one or more line items contain tracked inventory where the invoice quantity would cause the available quantity to go negative
    # + payload - Invoices with an array of invoice objects in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Invoices array with newly created Invoice)
    # http:BadRequest (A failed request due to validation error)
    resource function put Invoices(@http:Header {name: "xero-tenant-id"} string xeroTenantId, int? unitdp, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, boolean? allowBackorders, @http:Payload Invoices payload, boolean summarizeErrors = false) returns Invoices|ErrorBadRequest {
        Invoice[] created = [];
        foreach Invoice inv in payload.invoices ?: [] {
            Invoice invoice = inv.clone();
            invoice.invoiceID = "8f0c3e1a-5b2d-4c6e-9a7f-1d2e3f4a5b6c";
            invoice.invoiceNumber = "INV-0042";
            invoice.status = inv.status ?: "DRAFT";
            created.push(invoice);
        }
        return {invoices: created};
    }

    # Creates one or more items
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + summarizeErrors - If false return 200 OK and mix of successfully created objects and any with validation errors
    # + unitdp - e.g. unitdp=4 – (Unit Decimal Places) You can opt in to use four decimal places for unit amounts
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - Items with an array of Item objects in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type Items array with newly created Item)
    # http:BadRequest (A failed request due to validation error)
    resource function put Items(@http:Header {name: "xero-tenant-id"} string xeroTenantId, int? unitdp, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload Items payload, boolean summarizeErrors = false) returns Items|ErrorBadRequest {
        Item[] created = [];
        foreach Item i in payload.items ?: [] {
            Item item = i.clone();
            item.itemID = "a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d";
            created.push(item);
        }
        return {items: created};
    }

    # Create tracking categories
    #
    # + xeroTenantId - Xero identifier for Tenant
    # + idempotencyKey - This allows you to safely retry requests without the risk of duplicate processing. 128 character max
    # + payload - TrackingCategory object in body of request 
    # + return - returns can be any of following types 
    # http:Ok (Success - return response of type TrackingCategories array of newly created TrackingCategory)
    # http:BadRequest (A failed request due to validation error)
    resource function put TrackingCategories(@http:Header {name: "xero-tenant-id"} string xeroTenantId, @http:Header {name: "Idempotency-Key"} string? idempotencyKey, @http:Payload TrackingCategory payload) returns TrackingCategories|ErrorBadRequest {
        TrackingCategory category = payload.clone();
        category.trackingCategoryID = "b1df776b-b093-4730-b6ea-590cca40e723";
        category.status = "ACTIVE";
        return {trackingCategories: [category]};
    }
}

// Service-mode response types. `bal openapi --mode client` collapses 4XX/5XX
// to `error` and never emits these, so they are defined here for the mock only.
public type AccountsOk record {|
    *http:Ok;
    Accounts body;
|};

public type ContactsOk record {|
    *http:Ok;
    Contacts body;
|};

public type ErrorBadRequest record {|
    *http:BadRequest;
    Error body;
|};

public type InvoicesOk record {|
    *http:Ok;
    Invoices body;
|};

public type PaymentsOk record {|
    *http:Ok;
    Payments body;
|};

public type Error record {
    # Exception type
    @jsondata:Name {value: "Type"}
    string 'type?;
    # Exception message
    @jsondata:Name {value: "Message"}
    string message?;
    # Exception number
    @jsondata:Name {value: "ErrorNumber"}
    int errorNumber?;
    # Array of Elements of validation Errors
    @jsondata:Name {value: "Elements"}
    Element[] elements?;
};

public type Element record {
    # Identifier of the credit note the error relates to
    @jsondata:Name {value: "CreditNoteID"}
    string creditNoteID?;
    # Unique ID for batch payment object with validation error
    @jsondata:Name {value: "BatchPaymentID"}
    string batchPaymentID?;
    # Array of Validation Error message
    @jsondata:Name {value: "ValidationErrors"}
    ValidationError[] validationErrors?;
    # Identifier of the purchase order the error relates to
    @jsondata:Name {value: "PurchaseOrderID"}
    string purchaseOrderID?;
    # Identifier of the contact the error relates to
    @jsondata:Name {value: "ContactID"}
    string contactID?;
    # Identifier of the invoice the error relates to
    @jsondata:Name {value: "InvoiceID"}
    string invoiceID?;
    # Identifier of the item the error relates to
    @jsondata:Name {value: "ItemID"}
    string itemID?;
    # Identifier of the bank transaction the error relates to
    @jsondata:Name {value: "BankTransactionID"}
    string bankTransactionID?;
};

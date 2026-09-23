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

import ballerina/os;
import ballerina/test;
import ballerina/uuid;

final boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";
final string serviceUrl = isLiveServer ? "https://api.xero.com/api.xro/2.0" : "http://localhost:9090";
final string token = isLiveServer ? os:getEnv("XERO_ACCESS_TOKEN") : "test_token";
final string tenantId = isLiveServer ? os:getEnv("XERO_TENANT_ID") : "test_tenant";

final Client xero = check new ({auth: {token}}, serviceUrl);

// Every test builds a unique code so repeated live runs do not collide on Xero's
// uniqueness rules (account codes, item codes, tracking category names).
isolated function uniqueCode(string prefix) returns string =>
    prefix + uuid:createType4AsString().substring(0, 6).toUpperAscii();

isolated function firstContactId() returns string|error {
    Contacts contacts = check xero->getContacts({xeroTenantId: tenantId});
    Contact[] list = contacts.contacts ?: [];
    if list.length() == 0 {
        return error("the organisation has no contacts to test against");
    }
    return list[0].contactID ?: error("contact without a ContactID");
}

isolated function firstInvoiceId() returns string|error {
    Invoices invoices = check xero->getInvoices({xeroTenantId: tenantId});
    Invoice[] list = invoices.invoices ?: [];
    if list.length() == 0 {
        return error("the organisation has no invoices to test against");
    }
    return list[0].invoiceID ?: error("invoice without an InvoiceID");
}

// ---- Accounts --------------------------------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetAccounts() returns error? {
    Accounts response = check xero->getAccounts({xeroTenantId: tenantId}, 'order = "Name ASC");
    test:assertTrue((response.accounts ?: []).length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetAccount() returns error? {
    Accounts all = check xero->getAccounts({xeroTenantId: tenantId});
    string accountId = check ((all.accounts ?: [])[0].accountID).ensureType();
    Accounts response = check xero->getAccount(accountId, {xeroTenantId: tenantId});
    Account[] accounts = response.accounts ?: [];
    test:assertEquals(accounts.length(), 1);
    test:assertEquals(accounts[0].accountID, accountId);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateAccount() returns error? {
    string code = uniqueCode("T");
    Accounts response = check xero->createAccount({xeroTenantId: tenantId},
        {code, name: "Connector test " + code, 'type: "EXPENSE"});
    Account[] accounts = response.accounts ?: [];
    test:assertEquals(accounts.length(), 1);
    test:assertTrue(accounts[0].accountID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdateAccount() returns error? {
    string code = uniqueCode("U");
    Accounts created = check xero->createAccount({xeroTenantId: tenantId},
        {code, name: "Connector test " + code, 'type: "EXPENSE"});
    string accountId = check ((created.accounts ?: [])[0].accountID).ensureType();
    Accounts response = check xero->updateAccount(accountId, {xeroTenantId: tenantId},
        {accounts: [{description: "Updated by the connector test suite"}]});
    Account[] accounts = response.accounts ?: [];
    test:assertEquals(accounts.length(), 1);
    test:assertEquals(accounts[0].accountID, accountId);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteAccount() returns error? {
    string code = uniqueCode("D");
    Accounts created = check xero->createAccount({xeroTenantId: tenantId},
        {code, name: "Connector test " + code, 'type: "EXPENSE"});
    string accountId = check ((created.accounts ?: [])[0].accountID).ensureType();
    Accounts response = check xero->deleteAccount(accountId, {xeroTenantId: tenantId});
    Account[] accounts = response.accounts ?: [];
    test:assertEquals(accounts.length(), 1);
    test:assertEquals(accounts[0].status, "DELETED");
}

// ---- Contacts --------------------------------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetContacts() returns error? {
    Contacts response = check xero->getContacts({xeroTenantId: tenantId}, page = 1, pageSize = 10);
    test:assertTrue((response.contacts ?: []).length() > 0);
    test:assertTrue(response.pagination is Pagination);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetContact() returns error? {
    string contactId = check firstContactId();
    Contacts response = check xero->getContact(contactId, {xeroTenantId: tenantId});
    test:assertEquals((response.contacts ?: []).length(), 1);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetContactByContactNumber() returns error? {
    Contacts created = check xero->createContacts({xeroTenantId: tenantId},
        {contacts: [{name: "Connector test " + uniqueCode("C"), contactNumber: uniqueCode("N")}]});
    string contactNumber = check ((created.contacts ?: [])[0].contactNumber).ensureType();
    Contacts response = check xero->getContactByContactNumber(contactNumber, {xeroTenantId: tenantId});
    Contact[] contacts = response.contacts ?: [];
    test:assertEquals(contacts.length(), 1);
    test:assertTrue(contacts[0].contactID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateContacts() returns error? {
    string name = "Connector test " + uniqueCode("C");
    Contacts response = check xero->createContacts({xeroTenantId: tenantId},
        {contacts: [{name, emailAddress: "connector.test@example.com"}]});
    Contact[] contacts = response.contacts ?: [];
    test:assertEquals(contacts.length(), 1);
    test:assertEquals(contacts[0].name, name);
    test:assertTrue(contacts[0].contactID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdateContact() returns error? {
    Contacts created = check xero->createContacts({xeroTenantId: tenantId},
        {contacts: [{name: "Connector test " + uniqueCode("C")}]});
    string contactId = check ((created.contacts ?: [])[0].contactID).ensureType();
    Contacts response = check xero->updateContact(contactId, {xeroTenantId: tenantId},
        {contacts: [{emailAddress: "updated.contact@example.com"}]});
    Contact[] contacts = response.contacts ?: [];
    test:assertEquals(contacts.length(), 1);
    test:assertEquals(contacts[0].contactID, contactId);
}

// ---- Invoices --------------------------------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetInvoices() returns error? {
    Invoices response = check xero->getInvoices({xeroTenantId: tenantId}, statuses = ["AUTHORISED", "DRAFT"]);
    test:assertTrue((response.invoices ?: []).length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetInvoice() returns error? {
    string invoiceId = check firstInvoiceId();
    Invoices response = check xero->getInvoice(invoiceId, {xeroTenantId: tenantId}, unitdp = 4);
    Invoice[] invoices = response.invoices ?: [];
    test:assertEquals(invoices.length(), 1);
    test:assertEquals(invoices[0].invoiceID, invoiceId);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateInvoices() returns error? {
    string contactId = check firstContactId();
    Invoices response = check xero->createInvoices({xeroTenantId: tenantId}, {
        invoices: [
            {
                'type: "ACCREC",
                contact: {contactID: contactId},
                date: "2024-03-01",
                dueDate: "2024-03-31",
                lineAmountTypes: "Exclusive",
                lineItems: [{description: "Consulting services", quantity: 1, unitAmount: 100, accountCode: "200"}]
            }
        ]
    });
    Invoice[] invoices = response.invoices ?: [];
    test:assertEquals(invoices.length(), 1);
    test:assertTrue(invoices[0].invoiceID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testUpdateInvoice() returns error? {
    string contactId = check firstContactId();
    Invoices created = check xero->createInvoices({xeroTenantId: tenantId}, {
        invoices: [
            {
                'type: "ACCREC",
                contact: {contactID: contactId},
                lineItems: [{description: "Consulting services", quantity: 1, unitAmount: 100, accountCode: "200"}]
            }
        ]
    });
    string invoiceId = check ((created.invoices ?: [])[0].invoiceID).ensureType();
    Invoices response = check xero->updateInvoice(invoiceId, {xeroTenantId: tenantId},
        {invoices: [{reference: "Updated by the connector test suite"}]});
    Invoice[] invoices = response.invoices ?: [];
    test:assertEquals(invoices.length(), 1);
    test:assertEquals(invoices[0].invoiceID, invoiceId);
}

@test:Config {groups: ["mock_tests"]}
isolated function testEmailInvoice() returns error? {
    // Mock only: a live run would send a real email to the contact.
    string invoiceId = check firstInvoiceId();
    error? response = xero->emailInvoice(invoiceId, {xeroTenantId: tenantId}, {});
    test:assertTrue(response is ());
}

// ---- Items -----------------------------------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetItems() returns error? {
    Items response = check xero->getItems({xeroTenantId: tenantId});
    test:assertTrue((response.items ?: []).length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateItems() returns error? {
    string code = uniqueCode("ITEM");
    Items response = check xero->createItems({xeroTenantId: tenantId},
        {items: [{code, name: "Connector test item", salesDetails: {unitPrice: 25.00, accountCode: "200"}}]});
    Item[] items = response.items ?: [];
    test:assertEquals(items.length(), 1);
    test:assertEquals(items[0].code, code);
    test:assertTrue(items[0].itemID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteItem() returns error? {
    Items created = check xero->createItems({xeroTenantId: tenantId},
        {items: [{code: uniqueCode("DEL"), name: "Connector test item to delete"}]});
    string itemId = check ((created.items ?: [])[0].itemID).ensureType();
    error? response = xero->deleteItem(itemId, {xeroTenantId: tenantId});
    test:assertTrue(response is ());
}

// ---- Payments and bank transactions ----------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetPayments() returns error? {
    Payments response = check xero->getPayments({xeroTenantId: tenantId}, page = 1);
    test:assertTrue((response.payments ?: []).length() > 0);
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreatePayment() returns error? {
    // Mock only: a live payment needs an AUTHORISED invoice with an amount due.
    Payments response = check xero->createPayment({xeroTenantId: tenantId}, {
        invoice: {invoiceID: "d4956132-ed94-4dd7-9eaa-aa22dfdf06f2"},
        account: {code: "090"},
        date: "2024-03-10",
        amount: 575.00
    });
    Payment[] payments = response.payments ?: [];
    test:assertEquals(payments.length(), 1);
    test:assertTrue(payments[0].paymentID is string);
    test:assertEquals(payments[0].amount, 575.00d);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetBankTransactions() returns error? {
    BankTransactions response = check xero->getBankTransactions({xeroTenantId: tenantId}, page = 1);
    BankTransaction[] transactions = response.bankTransactions ?: [];
    test:assertTrue(transactions.length() > 0);
    test:assertTrue(transactions[0].lineItems.length() > 0);
}

@test:Config {groups: ["mock_tests"]}
isolated function testCreateBankTransactions() returns error? {
    // Mock only: a live run needs the organisation's own bank account code.
    BankTransactions response = check xero->createBankTransactions({xeroTenantId: tenantId}, {
        bankTransactions: [
            {
                'type: "SPEND",
                bankAccount: {code: "088"},
                contact: {contactID: "3ec601ad-eea0-4c51-9b0a-5a0e5e3f6d6f"},
                lineItems: [{description: "Printer paper", quantity: 2, unitAmount: 20.00, accountCode: "429"}]
            }
        ]
    });
    BankTransaction[] transactions = response.bankTransactions ?: [];
    test:assertEquals(transactions.length(), 1);
    test:assertTrue(transactions[0].bankTransactionID is string);
}

@test:Config {groups: ["mock_tests"]}
isolated function testGetBatchPayment() returns error? {
    // Mock only: needs the ID of an existing batch payment.
    string batchPaymentId = "b54aa50c-794c-461b-89d1-846e1b84d9c0";
    BatchPayments response = check xero->getBatchPayment(batchPaymentId, {xeroTenantId: tenantId});
    BatchPayment[] batches = response.batchPayments ?: [];
    test:assertEquals(batches.length(), 1);
    test:assertEquals(batches[0].batchPaymentID, batchPaymentId);
}

// ---- Tracking categories ---------------------------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetTrackingCategories() returns error? {
    TrackingCategories response = check xero->getTrackingCategories({xeroTenantId: tenantId}, includeArchived = false);
    test:assertTrue(response.trackingCategories is TrackingCategory[]);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testCreateTrackingCategory() returns error? {
    string name = uniqueCode("Region ");
    TrackingCategories response = check xero->createTrackingCategory({xeroTenantId: tenantId}, {name});
    TrackingCategory[] categories = response.trackingCategories ?: [];
    test:assertEquals(categories.length(), 1);
    test:assertEquals(categories[0].name, name);
    test:assertTrue(categories[0].trackingCategoryID is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testDeleteTrackingCategory() returns error? {
    TrackingCategories created = check xero->createTrackingCategory({xeroTenantId: tenantId},
        {name: uniqueCode("Delete ")});
    string categoryId = check ((created.trackingCategories ?: [])[0].trackingCategoryID).ensureType();
    TrackingCategories response = check xero->deleteTrackingCategory(categoryId, {xeroTenantId: tenantId});
    TrackingCategory[] categories = response.trackingCategories ?: [];
    test:assertEquals(categories.length(), 1);
    test:assertEquals(categories[0].status, "DELETED");
}

// ---- Organisation, tax rates and reports -----------------------------------

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetOrganisations() returns error? {
    Organisations response = check xero->getOrganisations({xeroTenantId: tenantId});
    Organisation[] organisations = response.organisations ?: [];
    test:assertEquals(organisations.length(), 1);
    test:assertTrue(organisations[0].name is string);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetTaxRates() returns error? {
    TaxRates response = check xero->getTaxRates({xeroTenantId: tenantId});
    test:assertTrue((response.taxRates ?: []).length() > 0);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetTaxRateByTaxType() returns error? {
    TaxRates all = check xero->getTaxRates({xeroTenantId: tenantId});
    string taxType = check ((all.taxRates ?: [])[0].taxType).ensureType();
    TaxRates response = check xero->getTaxRateByTaxType(taxType, {xeroTenantId: tenantId});
    TaxRate[] rates = response.taxRates ?: [];
    test:assertEquals(rates.length(), 1);
    test:assertEquals(rates[0].taxType, taxType);
}

@test:Config {groups: ["live_tests", "mock_tests"]}
isolated function testGetReportBalanceSheet() returns error? {
    ReportWithRows response = check xero->getReportBalanceSheet({xeroTenantId: tenantId}, date = "2024-03-31");
    ReportWithRow[] reports = response.reports ?: [];
    test:assertEquals(reports.length(), 1);
    test:assertTrue((reports[0].Rows ?: []).length() > 0);
}

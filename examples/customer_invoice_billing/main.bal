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

// Onboards a new customer, raises an approved sales invoice for them, emails it and
// reads it back to confirm the amount due.

import ballerina/io;
import ballerinax/xero.accounts;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
configurable string salesAccountCode = "200";

public function main() returns error? {
    accounts:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });

    // Step 1: create the customer contact.
    accounts:Contacts contacts = check xero->createContacts({xeroTenantId: tenantId}, {
        contacts: [
            {
                name: "Ridgeway University",
                firstName: "Jordan",
                lastName: "Reyes",
                emailAddress: "accounts@ridgeway.example.com",
                isCustomer: true
            }
        ]
    });
    accounts:Contact[] createdContacts = contacts.contacts ?: [];
    if createdContacts.length() == 0 {
        return error("Xero returned no contact for the create request");
    }
    string contactId = check createdContacts[0].contactID.ensureType();
    io:println("Created contact ", contactId);

    // Step 2: raise an AUTHORISED sales invoice against that contact.
    accounts:Invoices invoices = check xero->createInvoices({xeroTenantId: tenantId}, {
        invoices: [
            {
                'type: "ACCREC",
                contact: {contactID: contactId},
                date: "2026-09-01",
                dueDate: "2026-09-30",
                reference: "Semester workshop",
                status: "AUTHORISED",
                lineAmountTypes: "Exclusive",
                lineItems: [
                    {description: "Two-day data workshop", quantity: 2, unitAmount: 1200, accountCode: salesAccountCode}
                ]
            }
        ]
    });
    accounts:Invoice[] createdInvoices = invoices.invoices ?: [];
    if createdInvoices.length() == 0 {
        return error("Xero returned no invoice for the create request");
    }
    string invoiceId = check createdInvoices[0].invoiceID.ensureType();
    io:println("Raised invoice ", createdInvoices[0].invoiceNumber, " (", invoiceId, ")");

    // Step 3: email the invoice to the contact.
    check xero->emailInvoice(invoiceId, {xeroTenantId: tenantId}, {});
    io:println("Emailed the invoice to the customer");

    // Step 4: read the invoice back to confirm what is owed.
    accounts:Invoices fetched = check xero->getInvoice(invoiceId, {xeroTenantId: tenantId});
    accounts:Invoice[] fetchedInvoices = fetched.invoices ?: [];
    if fetchedInvoices.length() == 0 {
        return error(string `invoice ${invoiceId} was not found`);
    }
    accounts:Invoice invoice = fetchedInvoices[0];
    io:println("Status: ", invoice.status, ", total: ", invoice.total, ", amount due: ", invoice.amountDue);
}

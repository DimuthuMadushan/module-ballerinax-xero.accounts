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

// Pays every outstanding bill from one supplier in a single bank transaction with a batch
// payment, records the approval on the batch, and prints the stored batch.

import ballerina/io;
import ballerinax/xero.accounts;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
configurable string supplierContactId = ?;
configurable string bankAccountId = ?;

public function main() returns error? {
    accounts:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });

    // Step 1: find the supplier's AUTHORISED bills that still have an amount due.
    accounts:Invoices bills = check xero->getInvoices({xeroTenantId: tenantId},
        contactIDs = [supplierContactId], statuses = ["AUTHORISED"], 'where = "Type==\"ACCPAY\"");
    accounts:Payment[] lines = from accounts:Invoice bill in bills.invoices ?: []
        let decimal due = bill.amountDue ?: 0d
        where due > 0d
        select {invoice: {invoiceID: bill.invoiceID}, amount: due};
    if lines.length() == 0 {
        io:println("The supplier has no outstanding bills");
        return;
    }
    io:println("Paying ", lines.length(), " bills in one batch");

    // Step 2: settle them all with one batch payment from the bank account.
    accounts:BatchPayments created = check xero->createBatchPayment({xeroTenantId: tenantId}, {
        batchPayments: [
            {
                account: {accountID: bankAccountId},
                date: "2026-09-23",
                reference: "September supplier run",
                payments: lines
            }
        ]
    });
    accounts:BatchPayment[] batches = created.batchPayments ?: [];
    if batches.length() == 0 {
        return error("Xero returned no batch payment for the create request");
    }
    string batchPaymentId = check batches[0].batchPaymentID.ensureType();
    io:println("Created batch payment ", batchPaymentId);

    // Step 3: record who approved the run on the batch's history.
    _ = check xero->createBatchPaymentHistoryRecord(batchPaymentId, {xeroTenantId: tenantId}, {
        historyRecords: [{details: "Approved by the finance manager"}]
    });

    // Step 4: read the batch back.
    accounts:BatchPayments fetched = check xero->getBatchPayment(batchPaymentId, {xeroTenantId: tenantId});
    accounts:BatchPayment[] stored = fetched.batchPayments ?: [];
    if stored.length() == 0 {
        return error(string `batch payment ${batchPaymentId} was not found`);
    }
    io:println("Batch total: ", stored[0].totalAmount, " across ", (stored[0].payments ?: []).length(), " bills");
}

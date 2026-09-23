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

// Records a customer payment against a sales invoice, attaches a remittance note to the
// payment, and prints the stored payment together with its audit history.

import ballerina/io;
import ballerinax/xero.accounts;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
configurable string invoiceId = ?;
configurable string bankAccountCode = ?;
configurable decimal paymentAmount = ?;

public function main() returns error? {
    accounts:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });

    // Step 1: record the payment against the invoice, into the given bank account.
    accounts:Payments created = check xero->createPayment({xeroTenantId: tenantId}, {
        invoice: {invoiceID: invoiceId},
        account: {code: bankAccountCode},
        date: "2026-09-23",
        amount: paymentAmount,
        reference: "Customer remittance"
    });
    accounts:Payment[] payments = created.payments ?: [];
    if payments.length() == 0 {
        return error("Xero returned no payment for the create request");
    }
    string paymentId = check payments[0].paymentID.ensureType();
    io:println("Recorded payment ", paymentId);

    // Step 2: attach the remittance note to the payment's history.
    _ = check xero->createPaymentHistory(paymentId, {xeroTenantId: tenantId}, {
        historyRecords: [{details: "Remittance advice received by email"}]
    });

    // Step 3: fetch the stored payment.
    accounts:Payments fetched = check xero->getPayment(paymentId, {xeroTenantId: tenantId});
    accounts:Payment[] stored = fetched.payments ?: [];
    if stored.length() == 0 {
        return error(string `payment ${paymentId} was not found`);
    }
    io:println("Payment of ", stored[0].amount, " on invoice ", stored[0].invoice?.invoiceNumber, " is ", stored[0].status);

    // Step 4: print the payment's audit trail, including the note just added.
    accounts:HistoryRecords history = check xero->getPaymentHistory(paymentId, {xeroTenantId: tenantId});
    foreach accounts:HistoryRecord entry in history.historyRecords ?: [] {
        io:println(entry.dateUTC, "  ", entry.changes, "  ", entry.details);
    }
}

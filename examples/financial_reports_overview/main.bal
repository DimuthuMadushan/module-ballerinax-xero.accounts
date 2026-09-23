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

// Prints an organisation's month-end position: profit and loss for the month, the balance
// sheet and the trial balance at month end.

import ballerina/io;
import ballerinax/xero.accounts;

configurable string clientId = ?;
configurable string clientSecret = ?;
configurable string refreshToken = ?;
configurable string refreshUrl = ?;
configurable string tenantId = ?;
configurable string periodStart = "2026-08-01";
configurable string periodEnd = "2026-08-31";

public function main() returns error? {
    accounts:Client xero = check new ({
        auth: {clientId, clientSecret, refreshToken, refreshUrl}
    });

    // Step 1: identify the organisation the reports belong to.
    accounts:Organisations orgs = check xero->getOrganisations({xeroTenantId: tenantId});
    accounts:Organisation[] organisations = orgs.organisations ?: [];
    if organisations.length() == 0 {
        return error("the tenant returned no organisation");
    }
    io:println("Organisation: ", organisations[0].name, " (", organisations[0].baseCurrency, ")");

    // Step 2: profit and loss for the period.
    accounts:ReportWithRows profitAndLoss = check xero->getReportProfitAndLoss({xeroTenantId: tenantId},
        fromDate = periodStart, toDate = periodEnd);
    printReport(profitAndLoss);

    // Step 3: balance sheet at the end of the period.
    accounts:ReportWithRows balanceSheet = check xero->getReportBalanceSheet({xeroTenantId: tenantId},
        date = periodEnd);
    printReport(balanceSheet);

    // Step 4: trial balance at the end of the period.
    accounts:ReportWithRows trialBalance = check xero->getReportTrialBalance({xeroTenantId: tenantId},
        date = periodEnd);
    printReport(trialBalance);
}

// Prints each report's title and the label and first value of its summary rows.
function printReport(accounts:ReportWithRows response) {
    foreach accounts:ReportWithRow report in response.reports ?: [] {
        io:println("\n== ", report.ReportName, " ", report.ReportDate, " ==");
        foreach accounts:ReportRows section in report.Rows ?: [] {
            foreach accounts:ReportRow row in section.rows ?: [] {
                accounts:ReportCell[] cells = row.cells ?: [];
                if row.rowType == "SummaryRow" && cells.length() > 1 {
                    io:println(cells[0].value, ": ", cells[1].value);
                }
            }
        }
    }
}

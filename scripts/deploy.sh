#!/usr/bin/env bash
set -e

ORG_ALIAS=${1:-Agentforce_Org}

echo "1. Deploying Schema (Objects, Fields, Record Types, Validation Rules, Roles)..."
sf project deploy start --source-dir force-app/main/default/objects --source-dir force-app/main/default/roles --target-org "$ORG_ALIAS"

echo "2. Deploying Full Project Metadata & Running Local Apex Tests..."
sf project deploy start --source-dir force-app --test-level RunLocalTests --target-org "$ORG_ALIAS"

echo "3. Assigning Permission Set..."
sf org assign permset --name AutoProtect_Full_Access --target-org "$ORG_ALIAS"

echo "4. Importing 200+ Sample Records per Object..."
sf data import bulk --sobject Agent__c --file sample-data/csv/01_Agents.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Account --file sample-data/csv/02_Accounts.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Lead --file sample-data/csv/03_Leads.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Contact --file sample-data/csv/04_Contacts.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Policy__c --file sample-data/csv/05_Policies.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Claim__c --file sample-data/csv/06_Claims.csv --wait 10 --target-org "$ORG_ALIAS"
sf data import bulk --sobject Service_Request__c --file sample-data/csv/07_Service_Requests.csv --wait 10 --target-org "$ORG_ALIAS"

echo "5. Activating Daily Renewal Scheduler..."
sf apex run --file scripts/post-deploy.apex --target-org "$ORG_ALIAS"

echo "Deployment Complete!"

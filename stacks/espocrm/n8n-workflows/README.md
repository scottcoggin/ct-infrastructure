# n8n Workflow Templates for EspoCRM

This directory contains n8n workflow templates for automating EspoCRM tasks.

## Available Workflows

### linkedin-contacts-import.json

Imports LinkedIn contacts from CSV export into EspoCRM.

**Prerequisites:**
1. EspoCRM node installed in n8n: `@traien/n8n-nodes-espocrm`
2. EspoCRM API credentials configured in n8n
3. LinkedIn contacts exported as CSV

**How to Use:**

1. **Export LinkedIn Contacts:**
   - LinkedIn → Me → Settings & Privacy
   - Data Privacy → Get a copy of your data
   - Select "Connections" → Request Archive
   - Download CSV when ready

2. **Import Workflow into n8n:**
   ```bash
   # Option A: Via n8n UI
   - n8n → Workflows → Import from File
   - Select linkedin-contacts-import.json

   # Option B: Via CLI
   docker cp stacks/espocrm/n8n-workflows/linkedin-contacts-import.json n8n:/tmp/
   docker exec -it n8n sh -c "n8n import:workflow --input=/tmp/linkedin-contacts-import.json"
   ```

3. **Configure Workflow:**
   - Open imported workflow in n8n editor
   - Update "Read CSV File" node with your CSV file path
   - Configure EspoCRM credentials in final node
   - Optionally modify field mappings in "Map Fields" code node

4. **Run Workflow:**
   - Click "Execute Workflow" button
   - Monitor progress in execution log
   - Check EspoCRM for imported contacts

**Field Mappings:**

LinkedIn CSV → EspoCRM Contact:
- `First Name` → `firstName`
- `Last Name` → `lastName`
- `Email Address` → `emailAddress`
- `Position` → `title`
- `Company` → `accountName`
- `URL` → `linkedInUrl` (custom field)

**Deduplication:**

The workflow deduplicates contacts by email address before import. If a contact with the same email already exists in EspoCRM, it will be updated instead of creating a duplicate.

**Customization:**

Edit the "Map Fields" code node to:
- Add custom field mappings
- Apply data transformations
- Add conditional logic
- Enrich contact data from other sources

## Creating Additional Workflows

### Facebook Contacts Import

Similar workflow structure:
1. Export Facebook friends data
2. Parse JSON/CSV format
3. Map fields to EspoCRM schema
4. Deduplicate and import

### Email Follow-up Automation

Workflow to send automated follow-ups:
1. Schedule trigger (daily/weekly)
2. Query EspoCRM for contacts without recent activity
3. Generate personalized email via OpenWebUI/LiteLLM
4. Send email through EspoCRM

### CRM to DataLab Sync

Export CRM analytics to DataMart:
1. Schedule trigger (nightly)
2. Query EspoCRM contacts, deals, activities
3. Transform data for medallion architecture
4. Insert into DataMart bronze layer

## Troubleshooting

**Workflow fails to import:**
- Ensure n8n version is compatible (v1.0+)
- Check JSON syntax is valid
- Verify EspoCRM node is installed

**CSV parsing errors:**
- Verify CSV format matches LinkedIn export structure
- Check for special characters in field names
- Ensure UTF-8 encoding

**API connection errors:**
- Test EspoCRM credentials in n8n
- Verify EspoCRM API is enabled
- Check Docker network connectivity: `docker exec n8n ping espocrm`

**Duplicates still created:**
- Verify email addresses are present in CSV
- Check email field name matches in "Map Fields" code
- Ensure EspoCRM upsert operation is configured correctly

## Resources

- n8n Documentation: https://docs.n8n.io/
- EspoCRM API Docs: https://docs.espocrm.com/development/api/
- EspoCRM n8n Node: https://www.npmjs.com/package/@traien/n8n-nodes-espocrm

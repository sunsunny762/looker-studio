import fetch from 'node-fetch';
import qs from 'qs';
import * as fs from 'fs';

const tenantId = 'YOUR_TENANT_ID';
const clientId = 'YOUR_CLIENT_ID';
const username = 'YOUR_USERNAME';
const password = 'YOUR_PASSWORD';
const resource = 'https://analysis.windows.net/powerbi/api';

const reportId = 'YOUR_REPORT_ID';
const groupId = 'YOUR_GROUP_ID'; // Workspace ID

// Define TypeScript interfaces for the response objects
interface AuthResponse {
  access_token: string;
}

async function authenticate(): Promise<string> {
  const tokenUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/token`;

  const data = {
    grant_type: 'password',
    resource: resource,
    client_id: clientId,
    username: username,
    password: password,
    scope: 'openid',
  };

  try {
    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: qs.stringify(data),
    });

    if (!response.ok) {
      throw new Error(`Authentication failed: ${response.statusText}`);
    }

    const authResponse: AuthResponse = await response.json();
    return authResponse.access_token;
  } catch (error) {
    console.error('Error authenticating:', error);
    throw new Error('Authentication failed');
  }
}

async function exportReportToPDF(token: string): Promise<Buffer> {
  const exportUrl = `https://api.powerbi.com/v1.0/myorg/groups/${groupId}/reports/${reportId}/ExportTo`;

  const headers = {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${token}`,
  };

  const body = {
    format: 'PDF',
    reportLevelFilters: [
      {
        filter: {
          table: 'TableName',
          column: 'ColumnName',
          operator: 'In',
          values: ['FilterValue1', 'FilterValue2'], // Adjust values as needed
        },
      },
    ],
  };

  try {
    const response = await fetch(exportUrl, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new Error(`Export failed: ${response.statusText}`);
    }

    return Buffer.from(await response.arrayBuffer());
  } catch (error) {
    console.error('Error exporting report:', error);
    throw new Error('Export failed');
  }
}

async function savePDF(data: Buffer): Promise<void> {
  fs.writeFileSync('report.pdf', data);
  console.log('PDF saved as report.pdf');
}

(async () => {
  try {
    const token = await authenticate();
    const pdfData = await exportReportToPDF(token);
    await savePDF(pdfData);
  } catch (error) {
    console.error(error.message);
  }
})();

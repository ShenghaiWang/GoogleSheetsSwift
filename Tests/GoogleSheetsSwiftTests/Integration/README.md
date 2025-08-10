# Integration Tests

This directory contains integration tests that run against the real Google Sheets API. These tests are designed to verify that the SDK works correctly with the actual Google Sheets service.

## Setup

### Prerequisites

1. A Google Cloud Project with the Google Sheets API enabled
2. Either:
   - An API key for read-only operations, OR
   - OAuth2 credentials for full read/write operations

### Getting Credentials

#### Option 1: API Key (Read-only operations)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Enable the Google Sheets API
4. Go to "Credentials" and create an API key
5. Restrict the API key to the Google Sheets API for security

#### Option 2: OAuth2 Credentials (Full access)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project or create a new one
3. Enable the Google Sheets API
4. Go to "Credentials" and create OAuth2 credentials (Desktop application type)
5. Download the credentials JSON file
6. Use a tool like the [Google OAuth2 Playground](https://developers.google.com/oauthplayground/) to get a refresh token:
   - Set the scope to `https://www.googleapis.com/auth/spreadsheets`
   - Exchange the authorization code for tokens
   - Save the refresh token

### Environment Variables

Set the following environment variables to configure the integration tests:

#### For API Key (Read-only)
```bash
export GOOGLE_SHEETS_API_KEY="your_api_key_here"
export GOOGLE_SHEETS_TEST_SPREADSHEET_ID="your_test_spreadsheet_id"
```

#### For OAuth2 (Full access)
```bash
export GOOGLE_SHEETS_CLIENT_ID="your_client_id"
export GOOGLE_SHEETS_CLIENT_SECRET="your_client_secret"
export GOOGLE_SHEETS_REFRESH_TOKEN="your_refresh_token"
export GOOGLE_SHEETS_TEST_SPREADSHEET_ID="your_test_spreadsheet_id" # Optional
```

#### Optional Configuration
```bash
export GOOGLE_SHEETS_BASE_URL="https://sheets.googleapis.com/v4"  # Default
export GOOGLE_SHEETS_TEST_TIMEOUT="30"  # Timeout in seconds, default is 30
export RUN_INTEGRATION_TESTS="true"  # Force enable integration tests
```

### Test Spreadsheet

You can either:

1. **Use an existing spreadsheet**: Set `GOOGLE_SHEETS_TEST_SPREADSHEET_ID` to an existing spreadsheet ID
2. **Let tests create a spreadsheet**: If you have OAuth2 credentials, tests can create their own spreadsheet (requires manual cleanup)

To create a test spreadsheet manually:
1. Go to [Google Sheets](https://sheets.google.com/)
2. Create a new spreadsheet
3. Copy the spreadsheet ID from the URL (the long string between `/d/` and `/edit`)
4. Set the `GOOGLE_SHEETS_TEST_SPREADSHEET_ID` environment variable

## Running Tests

### Run All Integration Tests
```bash
swift test --filter IntegrationTests
```

### Run Specific Integration Test Classes
```bash
# Spreadsheet operations only
swift test --filter SpreadsheetsIntegrationTests

# Values operations only  
swift test --filter ValuesIntegrationTests
```

### Run with Environment Variables
```bash
GOOGLE_SHEETS_API_KEY="your_key" \
GOOGLE_SHEETS_TEST_SPREADSHEET_ID="your_spreadsheet_id" \
swift test --filter IntegrationTests
```

## Test Structure

### IntegrationTestBase
Base class that provides:
- Automatic configuration from environment variables
- Client setup (API key or OAuth2)
- Test spreadsheet management
- Helper methods for async operations
- Timeout handling

### SpreadsheetsIntegrationTests
Tests for spreadsheet-level operations:
- Creating spreadsheets (OAuth2 only)
- Retrieving spreadsheet metadata
- Error handling for invalid spreadsheet IDs
- Performance testing

### ValuesIntegrationTests  
Tests for cell value operations:
- Reading values from ranges
- Writing values to ranges (OAuth2 only)
- Batch operations
- Clearing values
- Different value types and formats
- Error handling for invalid ranges

## Test Categories

### Read-Only Tests (API Key or OAuth2)
- Get spreadsheet metadata
- Read cell values
- Batch read operations
- Error handling for invalid inputs

### Write Tests (OAuth2 only)
- Update cell values
- Append values
- Clear values
- Batch update operations
- Create spreadsheets

### Performance Tests
- Large data operations
- Concurrent requests
- Response time measurements

## Troubleshooting

### Tests are Skipped
If you see "Integration tests are disabled", check that:
1. Environment variables are set correctly
2. Credentials are valid
3. The Google Sheets API is enabled in your project

### Authentication Errors
- Verify your API key or OAuth2 credentials
- Check that the Google Sheets API is enabled
- Ensure OAuth2 refresh token hasn't expired

### Permission Errors
- API keys only allow read operations
- OAuth2 credentials need the `https://www.googleapis.com/auth/spreadsheets` scope
- Check that the test spreadsheet is accessible with your credentials

### Rate Limiting
- Google Sheets API has rate limits
- Tests include retry logic for rate limit errors
- Consider reducing concurrent operations if you hit limits frequently

### Cleanup
- Tests that create spreadsheets will print the spreadsheet ID for manual cleanup
- Google Sheets API doesn't provide a delete endpoint
- Use the Google Drive API or manually delete test spreadsheets

## Best Practices

1. **Use a dedicated test project** to avoid affecting production data
2. **Set up separate credentials** for testing
3. **Use a dedicated test spreadsheet** that can be safely modified
4. **Run integration tests in CI** with proper credential management
5. **Monitor API usage** to stay within quotas
6. **Clean up test data** regularly

## Security Notes

- Never commit credentials to version control
- Use environment variables or secure credential storage
- Restrict API keys to only necessary APIs
- Regularly rotate credentials
- Use least-privilege OAuth2 scopes
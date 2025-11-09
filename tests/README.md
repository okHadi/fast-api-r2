# API Tests

Comprehensive bash script to test the thumbnail upload API with curl.

## Prerequisites

1. Make sure the FastAPI server is running:

   ```bash
   fastapi dev src/main.py
   ```

2. Test images (`h.png` and `h2.png`) should be present in the tests directory

## Running Tests

From the `tests` directory, run:

```bash
./test_api.sh
```

## Tests Covered

### Authentication & Security Tests

1. **Missing API Key** - Verifies requests without API key are rejected (401)
2. **Invalid API Key** - Verifies requests with wrong API key are rejected (401)
3. **Valid API Key** - Verifies authenticated requests succeed

### File Upload Tests

4. **Single File Upload** - Tests uploading one PNG file
5. **Multiple Files Upload** - Tests uploading multiple files simultaneously (async)
6. **Invalid File Type** - Tests that non-image files (e.g., .txt) are rejected
7. **File Size Validation** - Tests that files > 2MB are rejected
8. **No Files Provided** - Tests error handling when no files are sent

### Database UPSERT Tests

9. **Re-upload Same File** - Tests that re-uploading updates `updated_at` timestamp
   - First upload creates record with `created_at` and `updated_at`
   - Second upload only updates `updated_at` (UPSERT behavior)

### Async R2 Upload Tests

10. **Concurrent Uploads** - Tests async behavior by sending 3 requests in parallel
    - Verifies all requests complete successfully
    - Confirms async uploads to R2 bucket work correctly

### Data Retrieval Tests

11. **Get Thumbnails** - Tests retrieving uploaded thumbnails with pagination
12. **Get Without Auth** - Verifies GET requests require authentication

### System Tests

13. **Health Check** - Tests the `/health` endpoint

## Test Output

The script provides color-coded output:

- 🟢 **Green**: Passed tests
- 🔴 **Red**: Failed tests
- 🔵 **Blue**: Test headers
- 🟡 **Yellow**: Informational messages

## Example Output

```
===================================================
TEST 1: Upload without API key (should fail)
===================================================
✓ PASSED: Request rejected without API key

===================================================
TEST SUMMARY
===================================================
Total Tests Run: 12
Tests Passed: 12
Tests Failed: 0
===================================================

🎉 All tests passed!
```

## What's Being Tested

### Async Operations

- **R2 Uploads**: All uploads use `aioboto3` async client
- **Database Operations**: PostgreSQL queries use async connection pool
- **Concurrent Requests**: Tests verify multiple uploads can happen simultaneously

### Security

- API key validation on all endpoints
- Proper 401 responses for unauthorized requests

### Data Integrity

- File type validation (only image/jpeg, image/png, image/jpg, image/webp)
- File size validation (max 2MB)
- UPSERT behavior (ON CONFLICT updates `updated_at` only)
- Transaction rollback on errors

### R2 Integration

- Async upload to Cloudflare R2 bucket
- Proper content-type headers
- File key storage in database with URLs

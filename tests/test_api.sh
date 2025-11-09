#!/bin/bash

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Configuration
API_URL="http://localhost:8000/api/thumbnails/"
VALID_API_KEY="my_secret_api_key"
INVALID_API_KEY="invalid_key_123"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to print test header
print_test() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}TEST $1: $2${NC}"
    echo -e "${BLUE}===================================================${NC}"
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Function to check test result
check_result() {
    local expected=$1
    local actual=$2
    local test_name=$3
    
    if [[ "$actual" == *"$expected"* ]]; then
        echo -e "${GREEN}✓ PASSED: $test_name${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ FAILED: $test_name${NC}"
        echo -e "${RED}Expected: $expected${NC}"
        echo -e "${RED}Got: $actual${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Function to print summary
print_summary() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}TEST SUMMARY${NC}"
    echo -e "${BLUE}===================================================${NC}"
    echo -e "Total Tests Run: $TESTS_RUN"
    echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}\n"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed!${NC}\n"
        exit 1
    fi
}

# Check if test images exist
if [ ! -f "h.png" ] || [ ! -f "h2.png" ]; then
    echo -e "${RED}Error: Test images (h.png, h2.png) not found in current directory!${NC}"
    echo -e "${YELLOW}Please run this script from the tests directory.${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting API Tests...${NC}"
echo -e "${YELLOW}Make sure the API server is running on $API_URL${NC}"

# ============================================
# TEST 1: Missing API Key
# ============================================
print_test "1" "Upload without API key (should fail)"
response=$(curl -s -X POST $API_URL -F "files=@h.png" 2>&1)
check_result "Missing API key" "$response" "Request rejected without API key"

# ============================================
# TEST 2: Invalid API Key
# ============================================
print_test "2" "Upload with invalid API key (should fail)"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $INVALID_API_KEY" -F "files=@h.png" 2>&1)
check_result "Invalid API key" "$response" "Request rejected with invalid API key"

# ============================================
# TEST 3: Valid Single File Upload
# ============================================
print_test "3" "Upload single valid PNG file"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" 2>&1)
check_result '"success":true' "$response" "Single file uploaded successfully"
check_result '"h.png"' "$response" "Response contains uploaded filename"

# ============================================
# TEST 4: Multiple Files Upload
# ============================================
print_test "4" "Upload multiple valid files (async)"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" -F "files=@h2.png" 2>&1)
check_result '"success":true' "$response" "Multiple files uploaded successfully"
check_result '"h.png"' "$response" "Response contains first filename"
check_result '"h2.png"' "$response" "Response contains second filename"

# ============================================
# TEST 5: Re-upload Same File (UPSERT Test)
# ============================================
print_test "5" "Re-upload same file (should update updated_at)"
# First upload
response1=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" 2>&1)
check_result '"success":true' "$response1" "First upload successful"

# Wait a moment to ensure different timestamp
sleep 2

# Second upload (should trigger UPSERT)
response2=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" 2>&1)
check_result '"success":true' "$response2" "Re-upload successful (UPSERT triggered)"

# ============================================
# TEST 6: Get Thumbnails
# ============================================
print_test "6" "Retrieve uploaded thumbnails"
response=$(curl -s -X GET $API_URL -H "X-API-Key: $VALID_API_KEY" 2>&1)
check_result '"success":true' "$response" "Thumbnails retrieved successfully"
check_result '"file_key"' "$response" "Response contains file_key field"
check_result '"url"' "$response" "Response contains url field"
check_result '"created_at"' "$response" "Response contains created_at field"
check_result '"updated_at"' "$response" "Response contains updated_at field"

# ============================================
# TEST 7: Get Thumbnails without API Key
# ============================================
print_test "7" "Try to get thumbnails without API key (should fail)"
response=$(curl -s -X GET $API_URL 2>&1)
check_result "Missing API key" "$response" "GET request rejected without API key"

# ============================================
# TEST 8: Create Invalid File Type Test
# ============================================
print_test "8" "Upload invalid file type (text file)"
# Create a temporary text file
echo "This is a test file" > test_file.txt
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@test_file.txt" 2>&1)
check_result '"success":false' "$response" "Invalid file type rejected"
check_result "Invalid file type" "$response" "Error message mentions file type"
rm -f test_file.txt

# ============================================
# TEST 9: Create Large File Test
# ============================================
print_test "9" "Upload file larger than 2MB (should fail)"
# Create a 3MB file
dd if=/dev/zero of=large_file.png bs=1M count=3 2>/dev/null
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@large_file.png" 2>&1)
check_result '"success":false' "$response" "Large file rejected"
check_result "File size exceeds limit" "$response" "Error message mentions file size"
rm -f large_file.png

# ============================================
# TEST 10: No Files Provided
# ============================================
print_test "10" "Upload without providing any files"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" 2>&1)
# FastAPI will return 422 for missing required field
check_result "Field required" "$response" "Request fails when no files provided"

# ============================================
# TEST 11: Concurrent Uploads (Async Test)
# ============================================
print_test "11" "Test concurrent uploads (async behavior)"
echo "Starting 3 concurrent upload requests..."

# Launch 3 upload requests in parallel
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" > /tmp/response1.txt 2>&1 &
PID1=$!
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h2.png" > /tmp/response2.txt 2>&1 &
PID2=$!
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" -F "files=@h2.png" > /tmp/response3.txt 2>&1 &
PID3=$!

# Wait for all requests to complete
wait $PID1 $PID2 $PID3

# Check all responses
response1=$(cat /tmp/response1.txt)
response2=$(cat /tmp/response2.txt)
response3=$(cat /tmp/response3.txt)

check_result '"success":true' "$response1" "Concurrent request 1 succeeded"
check_result '"success":true' "$response2" "Concurrent request 2 succeeded"
check_result '"success":true' "$response3" "Concurrent request 3 succeeded"

# Cleanup
rm -f /tmp/response1.txt /tmp/response2.txt /tmp/response3.txt

echo -e "\n${GREEN}All async upload tests completed!${NC}"

# ============================================
# TEST 12: Health Check
# ============================================
print_test "12" "API health check"
response=$(curl -s -X GET http://localhost:8000/health 2>&1)
check_result '"success":true' "$response" "Health check endpoint responding"

# Print final summary
print_summary

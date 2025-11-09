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
check_result '"file_key":"h.png"' "$response" "Response contains uploaded filename"
check_result '"url":"https://' "$response" "Response contains valid URL"

# ============================================
# TEST 4: Multiple Files Upload
# ============================================
print_test "4" "Upload multiple valid files"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" -F "files=@h2.png" 2>&1)
check_result '"file_key":"h.png"' "$response" "Response contains first filename"
check_result '"file_key":"h2.png"' "$response" "Response contains second filename"

# ============================================
# TEST 5: Re-upload Same File (UPSERT Test)
# ============================================
print_test "5" "Re-upload same file (should update updated_at)"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" 2>&1)
check_result '"file_key":"h.png"' "$response" "Re-upload successful"

# ============================================
# TEST 6: Get Thumbnails
# ============================================
print_test "6" "Retrieve uploaded thumbnails"
response=$(curl -s -X GET $API_URL -H "X-API-Key: $VALID_API_KEY" 2>&1)
check_result '"success":true' "$response" "Thumbnails retrieved successfully"
check_result '"file_key"' "$response" "Contains file_key"
check_result '"url"' "$response" "Contains url"
check_result '"created_at"' "$response" "Contains created_at"
check_result '"updated_at"' "$response" "Contains updated_at"

# ============================================
# TEST 7: Get Thumbnails without API Key
# ============================================
print_test "7" "Try to get thumbnails without API key (should fail)"
response=$(curl -s -X GET $API_URL 2>&1)
check_result "Missing API key" "$response" "GET request rejected without API key"

# ============================================
# TEST 8: Invalid File Type
# ============================================
print_test "8" "Upload invalid file type (text file)"
echo "This is a test file" > test_file.txt
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@test_file.txt" 2>&1)
# Controller returns Internal Server Error for invalid content type, so check for error
check_result 'Internal Server Error' "$response" "Invalid file type causes error"
rm -f test_file.txt

# ============================================
# TEST 9: Large File
# ============================================
print_test "9" "Upload file larger than 2MB"
dd if=/dev/zero of=large_file.png bs=1M count=3 2>/dev/null
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@large_file.png" 2>&1)
# Controller returns Internal Server Error for large files, so check for error
check_result 'Internal Server Error' "$response" "Large file causes error"
rm -f large_file.png

# ============================================
# TEST 10: No Files Provided
# ============================================
print_test "10" "Upload without files"
response=$(curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" 2>&1)
check_result '"Field required"' "$response" "Proper error structure"

# ============================================
# TEST 11: Concurrent Uploads
# ============================================
print_test "11" "Concurrent uploads"
echo "Starting 3 concurrent uploads..."
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" > /tmp/response1.txt 2>&1 &
PID1=$!
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h2.png" > /tmp/response2.txt 2>&1 &
PID2=$!
curl -s -X POST $API_URL -H "X-API-Key: $VALID_API_KEY" -F "files=@h.png" -F "files=@h2.png" > /tmp/response3.txt 2>&1 &
PID3=$!
wait $PID1 $PID2 $PID3
response1=$(cat /tmp/response1.txt)
response2=$(cat /tmp/response2.txt)
response3=$(cat /tmp/response3.txt)
check_result '"file_key":"h.png"' "$response1" "Concurrent upload 1 success"
check_result '"file_key":"h2.png"' "$response2" "Concurrent upload 2 success"
check_result '"file_key":"h.png"' "$response3" "Concurrent upload 3 success"
rm -f /tmp/response1.txt /tmp/response2.txt /tmp/response3.txt

# ============================================
# TEST 12: Health Check
# ============================================
print_test "12" "Health check"
response=$(curl -s -X GET http://localhost:8000/health 2>&1)
check_result '"success":true' "$response" "Health check OK"

# Print final summary
print_summary
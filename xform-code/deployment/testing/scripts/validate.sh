#!/bin/bash

# =============================================
# Bob's Used Bookstore - Validation Script
# Testing Environment Validation
# =============================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"

echo "================================================"
echo "Bob's Used Bookstore - Deployment Validation"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Load environment variables if .env exists
if [ -f "$DEPLOYMENT_DIR/config/.env" ]; then
    export $(grep -v '^#' "$DEPLOYMENT_DIR/config/.env" | xargs)
fi

APP_URL=${APP_URL:-http://localhost:8080}
CONTAINER_NAME="bookstore-web-testing"

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to run a test
run_test() {
    local test_name=$1
    local test_command=$2
    
    print_test "Testing: $test_name"
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓ PASSED${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC}"
        ((FAILED++))
        return 1
    fi
}

# Test 1: Container Status
echo "================================================"
echo "1. Container Health Checks"
echo "================================================"

if docker ps --filter "name=$CONTAINER_NAME" --filter "status=running" | grep -q "$CONTAINER_NAME"; then
    print_info "Container is running"
    ((PASSED++))
else
    print_error "Container is not running!"
    ((FAILED++))
    
    if docker ps -a --filter "name=$CONTAINER_NAME" | grep -q "$CONTAINER_NAME"; then
        print_error "Container exists but is not running. Last logs:"
        docker logs --tail 50 "$CONTAINER_NAME"
    else
        print_error "Container does not exist!"
    fi
fi

# Test 2: Application Endpoint Tests
echo ""
echo "================================================"
echo "2. Application Endpoint Tests"
echo "================================================"

sleep 5  # Give app time to fully start

# Test homepage
print_test "Testing: Homepage (GET /)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (HTTP $HTTP_CODE)"
    ((PASSED++))
else
    echo -e "  ${RED}✗ FAILED${NC} (HTTP $HTTP_CODE)"
    ((FAILED++))
fi

# Test search endpoint
print_test "Testing: Search endpoint (GET /Search)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/Search" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (HTTP $HTTP_CODE)"
    ((PASSED++))
else
    echo -e "  ${RED}✗ FAILED${NC} (HTTP $HTTP_CODE)"
    ((FAILED++))
fi

# Test authentication endpoint
print_test "Testing: Authentication endpoint (GET /Authentication/Login)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/Authentication/Login" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (HTTP $HTTP_CODE)"
    ((PASSED++))
else
    echo -e "  ${YELLOW}⚠ WARNING${NC} (HTTP $HTTP_CODE)"
    ((WARNINGS++))
fi

# Test static files
print_test "Testing: Static files (CSS)"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$APP_URL/css/site.css" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  ${GREEN}✓ PASSED${NC} (HTTP $HTTP_CODE)"
    ((PASSED++))
else
    echo -e "  ${RED}✗ FAILED${NC} (HTTP $HTTP_CODE)"
    ((FAILED++))
fi

# Test 3: Database Connectivity
echo ""
echo "================================================"
echo "3. Database Connectivity"
echo "================================================"

if [ -n "$DB_HOST" ] && [ -n "$DB_USER" ] && [ -n "$DB_PASSWORD" ]; then
    print_test "Testing: Database connection"
    
    if command -v psql &> /dev/null; then
        export PGPASSWORD="$DB_PASSWORD"
        DB_PORT=${DB_PORT:-5432}
        DB_NAME=${DB_NAME:-bookstore}
        
        if psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
            echo -e "  ${GREEN}✓ PASSED${NC}"
            ((PASSED++))
            
            # Check for tables
            print_test "Testing: Database tables exist"
            TABLE_COUNT=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null | xargs)
            if [ "$TABLE_COUNT" -gt 0 ]; then
                echo -e "  ${GREEN}✓ PASSED${NC} ($TABLE_COUNT tables found)"
                ((PASSED++))
            else
                echo -e "  ${RED}✗ FAILED${NC} (No tables found)"
                ((FAILED++))
            fi
        else
            echo -e "  ${RED}✗ FAILED${NC}"
            ((FAILED++))
        fi
    else
        echo -e "  ${YELLOW}⚠ SKIPPED${NC} (psql not available)"
        ((WARNINGS++))
    fi
else
    echo -e "  ${YELLOW}⚠ SKIPPED${NC} (Database credentials not configured)"
    ((WARNINGS++))
fi

# Test 4: Service Configuration
echo ""
echo "================================================"
echo "4. Service Configuration"
echo "================================================"

print_info "Checking environment variables in container..."
docker exec "$CONTAINER_NAME" printenv | grep "Services__" || true

print_test "Verifying: Service configurations"
EXPECTED_SERVICES=(
    "Services__Authentication=local"
    "Services__Database=aws"
    "Services__FileService=aws"
    "Services__ImageValidationService=local"
    "Services__LoggingService=aws"
)

for service_config in "${EXPECTED_SERVICES[@]}"; do
    if docker exec "$CONTAINER_NAME" printenv | grep -q "$service_config"; then
        echo -e "  ${GREEN}✓${NC} $service_config"
        ((PASSED++))
    else
        echo -e "  ${RED}✗${NC} $service_config"
        ((FAILED++))
    fi
done

# Test 5: AWS Services (if configured)
echo ""
echo "================================================"
echo "5. AWS Services Configuration"
echo "================================================"

if [ -n "$AWS_ACCESS_KEY_ID" ] && [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    print_info "AWS credentials are configured"
    ((PASSED++))
    
    if [ -n "$Files__BucketName" ]; then
        print_info "S3 bucket configured: $Files__BucketName"
        ((PASSED++))
    else
        print_warn "S3 bucket name not configured"
        ((WARNINGS++))
    fi
else
    print_warn "AWS credentials not configured (required for aws services)"
    ((WARNINGS++))
fi

# Test 6: Container Logs Check
echo ""
echo "================================================"
echo "6. Container Logs Analysis"
echo "================================================"

print_info "Checking for errors in container logs..."
ERROR_COUNT=$(docker logs "$CONTAINER_NAME" 2>&1 | grep -i "error\|exception\|failed" | grep -v "No error" | wc -l || echo "0")

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo -e "  ${GREEN}✓ No errors found in logs${NC}"
    ((PASSED++))
else
    echo -e "  ${YELLOW}⚠ Found $ERROR_COUNT potential errors in logs${NC}"
    print_warn "Recent errors:"
    docker logs "$CONTAINER_NAME" 2>&1 | grep -i "error\|exception\|failed" | grep -v "No error" | tail -10
    ((WARNINGS++))
fi

# Test 7: Memory and Resource Usage
echo ""
echo "================================================"
echo "7. Resource Usage"
echo "================================================"

print_info "Container resource usage:"
docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

# Summary
echo ""
echo "================================================"
echo "Validation Summary"
echo "================================================"
echo -e "${GREEN}Passed:${NC}   $PASSED"
echo -e "${RED}Failed:${NC}   $FAILED"
echo -e "${YELLOW}Warnings:${NC} $WARNINGS"
echo "================================================"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo ""
    echo "Application is ready for testing!"
    echo "URL: $APP_URL"
    exit 0
else
    echo -e "${RED}✗ Some tests failed!${NC}"
    echo ""
    echo "Please review the failures above and check:"
    echo "  - Container logs: docker logs $CONTAINER_NAME"
    echo "  - Container status: docker ps -a"
    echo "  - Configuration: $DEPLOYMENT_DIR/config/.env"
    exit 1
fi

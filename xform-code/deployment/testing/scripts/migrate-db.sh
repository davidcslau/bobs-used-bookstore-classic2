#!/bin/bash

# =============================================
# Bob's Used Bookstore - Database Migration Script
# PostgreSQL Schema Migration for AWS RDS
# =============================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"
MIGRATIONS_DIR="$DEPLOYMENT_DIR/migrations"

echo "================================================"
echo "Database Migration Script"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Load environment variables if .env exists
if [ -f "$DEPLOYMENT_DIR/config/.env" ]; then
    print_info "Loading environment variables..."
    export $(grep -v '^#' "$DEPLOYMENT_DIR/config/.env" | xargs)
fi

# Check for required variables
if [ -z "$DB_HOST" ] || [ -z "$DB_NAME" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ]; then
    print_error "Database configuration missing!"
    echo "Please set the following environment variables:"
    echo "  - DB_HOST"
    echo "  - DB_NAME"
    echo "  - DB_USER"
    echo "  - DB_PASSWORD"
    exit 1
fi

# Set default port if not specified
DB_PORT=${DB_PORT:-5432}

# Check if psql is available
if ! command -v psql &> /dev/null; then
    print_warn "psql is not installed locally."
    print_info "Attempting to use Docker PostgreSQL client..."
    
    # Use Docker to run psql
    PSQL_CMD="docker run --rm -i -e PGPASSWORD=$DB_PASSWORD postgres:16 psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
else
    # Use local psql
    export PGPASSWORD="$DB_PASSWORD"
    PSQL_CMD="psql -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME"
fi

# Test database connection
print_info "Testing database connection..."
if echo "SELECT version();" | $PSQL_CMD > /dev/null 2>&1; then
    print_info "Database connection successful!"
else
    print_error "Cannot connect to database!"
    print_error "Please check your database configuration and network connectivity."
    exit 1
fi

# Function to run migration file
run_migration() {
    local migration_file=$1
    local migration_name=$(basename "$migration_file")
    
    print_info "Running migration: $migration_name"
    
    if cat "$migration_file" | $PSQL_CMD; then
        print_info "✓ Migration completed: $migration_name"
        return 0
    else
        print_error "✗ Migration failed: $migration_name"
        return 1
    fi
}

# Run migrations in order
print_info "Starting database migrations..."
echo ""

MIGRATION_FILES=(
    "$MIGRATIONS_DIR/001_initial_schema.sql"
    "$MIGRATIONS_DIR/002_seed_reference_data.sql"
)

FAILED_MIGRATIONS=()

for migration_file in "${MIGRATION_FILES[@]}"; do
    if [ -f "$migration_file" ]; then
        if ! run_migration "$migration_file"; then
            FAILED_MIGRATIONS+=("$(basename "$migration_file")")
        fi
    else
        print_warn "Migration file not found: $(basename "$migration_file")"
    fi
    echo ""
done

# Summary
echo "================================================"
if [ ${#FAILED_MIGRATIONS[@]} -eq 0 ]; then
    echo -e "${GREEN}All migrations completed successfully!${NC}"
else
    echo -e "${RED}Some migrations failed:${NC}"
    for failed in "${FAILED_MIGRATIONS[@]}"; do
        echo "  - $failed"
    done
    exit 1
fi
echo "================================================"
echo ""

# Verify tables were created
print_info "Verifying database schema..."
TABLE_COUNT=$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | $PSQL_CMD -t | xargs)

if [ "$TABLE_COUNT" -gt 0 ]; then
    print_info "Found $TABLE_COUNT tables in the database"
    
    # List tables
    print_info "Database tables:"
    echo "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;" | $PSQL_CMD
else
    print_error "No tables found! Migrations may have failed."
    exit 1
fi

echo ""
print_info "Database migration completed successfully!"

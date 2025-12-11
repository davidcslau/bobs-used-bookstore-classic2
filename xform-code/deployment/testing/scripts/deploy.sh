#!/bin/bash

# =============================================
# Bob's Used Bookstore - Deployment Script
# Testing Environment Deployment
# =============================================

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$(dirname "$DEPLOYMENT_DIR")")"

echo "================================================"
echo "Bob's Used Bookstore - Testing Deployment"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if .env file exists
if [ ! -f "$DEPLOYMENT_DIR/config/.env" ]; then
    print_error ".env file not found!"
    print_info "Please copy .env.template to .env and configure it:"
    print_info "  cp $DEPLOYMENT_DIR/config/.env.template $DEPLOYMENT_DIR/config/.env"
    exit 1
fi

# Load environment variables
print_info "Loading environment variables..."
export $(grep -v '^#' "$DEPLOYMENT_DIR/config/.env" | xargs)

# Validate required environment variables
print_info "Validating environment configuration..."
REQUIRED_VARS=(
    "DB_HOST"
    "DB_NAME"
    "DB_USER"
    "DB_PASSWORD"
    "AWS_REGION"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "Files__BucketName"
)

MISSING_VARS=()
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    print_error "Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "  - $var"
    done
    exit 1
fi

print_info "Environment validation passed!"

# Check Docker and Docker Compose
print_info "Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running. Please start Docker."
    exit 1
fi

print_info "Docker is ready!"

# Build Docker image
print_info "Building Docker image..."
cd "$PROJECT_ROOT"
docker build -t bookstore-web:testing -f Dockerfile .

if [ $? -eq 0 ]; then
    print_info "Docker image built successfully!"
else
    print_error "Docker build failed!"
    exit 1
fi

# Run database migrations
print_info "Preparing database migrations..."
print_warn "Make sure your AWS RDS PostgreSQL instance is accessible!"
read -p "Do you want to run database migrations? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    bash "$SCRIPT_DIR/migrate-db.sh"
fi

# Deploy with Docker Compose
print_info "Starting application with Docker Compose..."
cd "$DEPLOYMENT_DIR"
docker-compose -f docker-compose.testing.yml --env-file config/.env up -d

if [ $? -eq 0 ]; then
    print_info "Application deployed successfully!"
else
    print_error "Deployment failed!"
    exit 1
fi

# Wait for application to be ready
print_info "Waiting for application to start..."
sleep 10

# Check container status
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' bookstore-web-testing 2>/dev/null || echo "not found")

if [ "$CONTAINER_STATUS" == "running" ]; then
    print_info "Container is running!"
    
    # Display container logs
    print_info "Recent container logs:"
    docker logs --tail 20 bookstore-web-testing
    
    echo ""
    echo "================================================"
    echo -e "${GREEN}Deployment Complete!${NC}"
    echo "================================================"
    echo ""
    echo "Application URL: http://localhost:8080"
    echo ""
    echo "Useful commands:"
    echo "  - View logs:        docker logs -f bookstore-web-testing"
    echo "  - Stop application: docker-compose -f $DEPLOYMENT_DIR/docker-compose.testing.yml down"
    echo "  - Restart:          docker-compose -f $DEPLOYMENT_DIR/docker-compose.testing.yml restart"
    echo ""
else
    print_error "Container failed to start! Status: $CONTAINER_STATUS"
    print_error "Container logs:"
    docker logs bookstore-web-testing
    exit 1
fi

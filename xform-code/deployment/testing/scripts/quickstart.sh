#!/bin/bash

# =============================================
# Bob's Used Bookstore - Quick Start
# Interactive setup for testing environment
# =============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOYMENT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

clear
cat << "EOF"
╔════════════════════════════════════════════════════════╗
║                                                        ║
║       Bob's Used Bookstore - Testing Setup            ║
║       .NET 8.0 on Linux with AWS Services             ║
║                                                        ║
╚════════════════════════════════════════════════════════╝
EOF

echo ""
echo "This script will guide you through setting up the testing environment."
echo ""

# Function to print steps
print_step() {
    echo -e "${BLUE}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check prerequisites
echo "================================================"
echo "Checking Prerequisites..."
echo "================================================"
echo ""

PREREQ_FAILED=0

# Check Docker
print_step "Checking Docker..."
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        print_success "Docker is installed and running"
    else
        print_error "Docker is installed but not running"
        ((PREREQ_FAILED++))
    fi
else
    print_error "Docker is not installed"
    ((PREREQ_FAILED++))
fi

# Check Docker Compose
print_step "Checking Docker Compose..."
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    print_success "Docker Compose is available"
else
    print_error "Docker Compose is not installed"
    ((PREREQ_FAILED++))
fi

# Check AWS CLI
print_step "Checking AWS CLI..."
if command -v aws &> /dev/null; then
    print_success "AWS CLI is installed"
else
    print_warn "AWS CLI is not installed (optional, but recommended)"
fi

# Check psql
print_step "Checking PostgreSQL client..."
if command -v psql &> /dev/null; then
    print_success "PostgreSQL client is installed"
else
    print_warn "PostgreSQL client is not installed (optional)"
fi

echo ""

if [ $PREREQ_FAILED -gt 0 ]; then
    print_error "Some prerequisites are missing. Please install them first."
    echo ""
    echo "Installation links:"
    echo "  Docker: https://docs.docker.com/get-docker/"
    echo "  Docker Compose: https://docs.docker.com/compose/install/"
    echo "  AWS CLI: https://aws.amazon.com/cli/"
    exit 1
fi

# Setup steps
echo "================================================"
echo "Setup Steps"
echo "================================================"
echo ""
echo "The setup process consists of:"
echo "  1. Configure environment variables"
echo "  2. Set up AWS resources (optional)"
echo "  3. Run database migrations"
echo "  4. Build and deploy application"
echo "  5. Validate deployment"
echo ""
read -p "Continue with setup? (y/n) [y]: " CONTINUE
CONTINUE=${CONTINUE:-y}

if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Step 1: Environment Configuration
echo ""
echo "================================================"
echo "Step 1: Environment Configuration"
echo "================================================"
echo ""

if [ -f "$DEPLOYMENT_DIR/config/.env" ]; then
    print_warn ".env file already exists"
    read -p "Do you want to reconfigure? (y/n) [n]: " RECONFIG
    RECONFIG=${RECONFIG:-n}
    
    if [[ ! $RECONFIG =~ ^[Yy]$ ]]; then
        print_success "Using existing .env file"
    else
        cp "$DEPLOYMENT_DIR/config/.env.template" "$DEPLOYMENT_DIR/config/.env"
        print_success "Reset .env from template"
        echo ""
        print_warn "Please edit $DEPLOYMENT_DIR/config/.env with your settings"
        echo ""
        read -p "Press Enter after you've configured the .env file..."
    fi
else
    print_step "Creating .env file from template..."
    cp "$DEPLOYMENT_DIR/config/.env.template" "$DEPLOYMENT_DIR/config/.env"
    print_success ".env file created"
    echo ""
    print_warn "Please edit $DEPLOYMENT_DIR/config/.env with your settings"
    echo ""
    echo "Required configuration:"
    echo "  - DB_HOST: Your RDS PostgreSQL endpoint"
    echo "  - DB_PASSWORD: Database password"
    echo "  - AWS_ACCESS_KEY_ID: Your AWS access key"
    echo "  - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
    echo "  - Files__BucketName: Your S3 bucket name"
    echo ""
    read -p "Press Enter after you've configured the .env file..."
fi

# Step 2: AWS Resources (optional)
echo ""
echo "================================================"
echo "Step 2: AWS Resources Setup (Optional)"
echo "================================================"
echo ""
echo "Do you need help setting up AWS resources?"
echo "  - S3 bucket for file storage"
echo "  - CloudWatch log group"
echo "  - IAM user and permissions"
echo ""
read -p "Run AWS setup helper? (y/n) [n]: " SETUP_AWS
SETUP_AWS=${SETUP_AWS:-n}

if [[ $SETUP_AWS =~ ^[Yy]$ ]]; then
    if [ -x "$SCRIPT_DIR/setup-aws-resources.sh" ]; then
        bash "$SCRIPT_DIR/setup-aws-resources.sh"
    else
        print_error "AWS setup script not found or not executable"
    fi
    echo ""
    read -p "Press Enter to continue..."
fi

# Step 3: Database Migrations
echo ""
echo "================================================"
echo "Step 3: Database Migrations"
echo "================================================"
echo ""
print_warn "Ensure your RDS PostgreSQL instance is accessible before continuing"
echo ""
read -p "Run database migrations? (y/n) [y]: " RUN_MIGRATIONS
RUN_MIGRATIONS=${RUN_MIGRATIONS:-y}

if [[ $RUN_MIGRATIONS =~ ^[Yy]$ ]]; then
    print_step "Running database migrations..."
    if bash "$SCRIPT_DIR/migrate-db.sh"; then
        print_success "Database migrations completed"
    else
        print_error "Database migrations failed"
        echo ""
        read -p "Continue anyway? (y/n) [n]: " CONTINUE_ANYWAY
        if [[ ! $CONTINUE_ANYWAY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
fi

# Step 4: Build and Deploy
echo ""
echo "================================================"
echo "Step 4: Build and Deploy Application"
echo "================================================"
echo ""
read -p "Build and deploy the application? (y/n) [y]: " DEPLOY_APP
DEPLOY_APP=${DEPLOY_APP:-y}

if [[ $DEPLOY_APP =~ ^[Yy]$ ]]; then
    print_step "Running deployment..."
    if bash "$SCRIPT_DIR/deploy.sh"; then
        print_success "Deployment completed"
    else
        print_error "Deployment failed"
        exit 1
    fi
fi

# Step 5: Validation
echo ""
echo "================================================"
echo "Step 5: Deployment Validation"
echo "================================================"
echo ""
read -p "Run deployment validation? (y/n) [y]: " RUN_VALIDATION
RUN_VALIDATION=${RUN_VALIDATION:-y}

if [[ $RUN_VALIDATION =~ ^[Yy]$ ]]; then
    print_step "Running validation tests..."
    bash "$SCRIPT_DIR/validate.sh"
fi

# Summary
echo ""
echo "================================================"
echo "Setup Complete!"
echo "================================================"
echo ""
print_success "Bob's Used Bookstore is now running in testing mode"
echo ""
echo "Access the application:"
echo "  URL: http://localhost:8080"
echo "  Admin: http://localhost:8080/Admin"
echo ""
echo "Useful commands:"
echo "  View logs:     docker logs -f bookstore-web-testing"
echo "  Stop app:      cd $DEPLOYMENT_DIR && docker-compose -f docker-compose.testing.yml down"
echo "  Restart app:   cd $DEPLOYMENT_DIR && docker-compose -f docker-compose.testing.yml restart"
echo "  Validate:      $SCRIPT_DIR/validate.sh"
echo ""
echo "Documentation:"
echo "  Deployment:    $DEPLOYMENT_DIR/docs/DEPLOYMENT_GUIDE.md"
echo "  Configuration: $DEPLOYMENT_DIR/docs/CONFIGURATION_GUIDE.md"
echo "  Troubleshooting: $DEPLOYMENT_DIR/docs/TROUBLESHOOTING_GUIDE.md"
echo "  Testing:       $DEPLOYMENT_DIR/docs/TESTING_CHECKLIST.md"
echo ""
print_success "Happy testing!"
echo ""

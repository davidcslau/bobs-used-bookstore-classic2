#!/bin/bash

# =============================================
# Bob's Used Bookstore - AWS Resources Setup
# Helper script to create required AWS resources
# =============================================

set -e

echo "================================================"
echo "AWS Resources Setup for Bob's Used Bookstore"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first:"
    echo "  https://aws.amazon.com/cli/"
    exit 1
fi

# Check AWS credentials
print_info "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured. Please run 'aws configure'"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_info "AWS Account ID: $ACCOUNT_ID"

# Get region
DEFAULT_REGION="us-east-1"
read -p "Enter AWS region [$DEFAULT_REGION]: " AWS_REGION
AWS_REGION=${AWS_REGION:-$DEFAULT_REGION}
print_info "Using region: $AWS_REGION"

echo ""
echo "================================================"
echo "1. S3 Bucket Setup"
echo "================================================"

DEFAULT_BUCKET="bookstore-files-bucket-$ACCOUNT_ID"
read -p "Enter S3 bucket name [$DEFAULT_BUCKET]: " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-$DEFAULT_BUCKET}

if aws s3 ls "s3://$BUCKET_NAME" 2>/dev/null; then
    print_warn "Bucket $BUCKET_NAME already exists"
else
    print_step "Creating S3 bucket: $BUCKET_NAME"
    
    if [ "$AWS_REGION" == "us-east-1" ]; then
        aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION
    else
        aws s3 mb "s3://$BUCKET_NAME" --region $AWS_REGION --create-bucket-configuration LocationConstraint=$AWS_REGION
    fi
    
    print_info "✓ Bucket created successfully"
fi

# Enable versioning
print_step "Enabling bucket versioning..."
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled \
    --region $AWS_REGION

print_info "✓ Versioning enabled"

# Enable encryption
print_step "Enabling bucket encryption..."
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --region $AWS_REGION

print_info "✓ Encryption enabled"

# Block public access
print_step "Blocking public access..."
aws s3api put-public-access-block \
    --bucket $BUCKET_NAME \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region $AWS_REGION

print_info "✓ Public access blocked"

echo ""
echo "================================================"
echo "2. CloudWatch Log Group Setup"
echo "================================================"

LOG_GROUP="/aws/bookstore/testing"
read -p "Enter CloudWatch log group name [$LOG_GROUP]: " LOG_GROUP_INPUT
LOG_GROUP=${LOG_GROUP_INPUT:-$LOG_GROUP}

if aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP" --region $AWS_REGION 2>/dev/null | grep -q "$LOG_GROUP"; then
    print_warn "Log group $LOG_GROUP already exists"
else
    print_step "Creating CloudWatch log group: $LOG_GROUP"
    aws logs create-log-group \
        --log-group-name "$LOG_GROUP" \
        --region $AWS_REGION
    
    print_info "✓ Log group created"
fi

# Set retention policy
print_step "Setting log retention to 30 days..."
aws logs put-retention-policy \
    --log-group-name "$LOG_GROUP" \
    --retention-in-days 30 \
    --region $AWS_REGION

print_info "✓ Retention policy set"

echo ""
echo "================================================"
echo "3. IAM User Setup"
echo "================================================"

DEFAULT_IAM_USER="bookstore-app-user"
read -p "Create IAM user for application? (y/n) [y]: " CREATE_USER
CREATE_USER=${CREATE_USER:-y}

if [[ $CREATE_USER =~ ^[Yy]$ ]]; then
    read -p "Enter IAM user name [$DEFAULT_IAM_USER]: " IAM_USER
    IAM_USER=${IAM_USER:-$DEFAULT_IAM_USER}
    
    if aws iam get-user --user-name $IAM_USER 2>/dev/null; then
        print_warn "IAM user $IAM_USER already exists"
    else
        print_step "Creating IAM user: $IAM_USER"
        aws iam create-user --user-name $IAM_USER
        print_info "✓ IAM user created"
    fi
    
    # Create policy
    POLICY_NAME="BookstoreAppPolicy"
    print_step "Creating IAM policy: $POLICY_NAME"
    
    POLICY_DOCUMENT=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::$BUCKET_NAME",
                "arn:aws:s3:::$BUCKET_NAME/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:$LOG_GROUP:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rekognition:DetectModerationLabels"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)
    
    POLICY_ARN=$(aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document "$POLICY_DOCUMENT" \
        --query 'Policy.Arn' \
        --output text 2>/dev/null || \
        aws iam list-policies --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text)
    
    if [ -n "$POLICY_ARN" ]; then
        print_info "✓ Policy created/found: $POLICY_ARN"
        
        # Attach policy to user
        print_step "Attaching policy to user..."
        aws iam attach-user-policy \
            --user-name $IAM_USER \
            --policy-arn $POLICY_ARN || print_warn "Policy may already be attached"
        
        print_info "✓ Policy attached"
    fi
    
    # Create access key
    print_step "Creating access key for user..."
    read -p "Create new access key? (y/n) [y]: " CREATE_KEY
    CREATE_KEY=${CREATE_KEY:-y}
    
    if [[ $CREATE_KEY =~ ^[Yy]$ ]]; then
        ACCESS_KEY_OUTPUT=$(aws iam create-access-key --user-name $IAM_USER --output json)
        ACCESS_KEY_ID=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.AccessKeyId')
        SECRET_ACCESS_KEY=$(echo $ACCESS_KEY_OUTPUT | jq -r '.AccessKey.SecretAccessKey')
        
        echo ""
        echo "================================================"
        print_info "Access Key Created Successfully!"
        echo "================================================"
        echo ""
        echo -e "${YELLOW}IMPORTANT: Save these credentials securely!${NC}"
        echo "Access Key ID: $ACCESS_KEY_ID"
        echo "Secret Access Key: $SECRET_ACCESS_KEY"
        echo ""
        echo "Add these to your .env file:"
        echo "AWS_ACCESS_KEY_ID=$ACCESS_KEY_ID"
        echo "AWS_SECRET_ACCESS_KEY=$SECRET_ACCESS_KEY"
        echo ""
        
        # Save to file
        read -p "Save credentials to file? (y/n) [n]: " SAVE_CREDS
        if [[ $SAVE_CREDS =~ ^[Yy]$ ]]; then
            CREDS_FILE="aws-credentials-$(date +%Y%m%d-%H%M%S).txt"
            cat > $CREDS_FILE <<EOF
AWS Credentials for Bob's Used Bookstore
Generated: $(date)
========================================

Access Key ID: $ACCESS_KEY_ID
Secret Access Key: $SECRET_ACCESS_KEY

IAM User: $IAM_USER
Region: $AWS_REGION
S3 Bucket: $BUCKET_NAME
CloudWatch Log Group: $LOG_GROUP

IMPORTANT: Keep this file secure and delete after copying to .env
EOF
            chmod 600 $CREDS_FILE
            print_info "Credentials saved to: $CREDS_FILE"
        fi
    fi
fi

echo ""
echo "================================================"
echo "4. RDS Database Information"
echo "================================================"

print_info "RDS PostgreSQL instance setup requires manual configuration"
print_info "Use AWS Console or CLI to create an RDS instance with:"
echo ""
echo "  - Engine: PostgreSQL 14 or later"
echo "  - Instance class: db.t3.medium (or larger)"
echo "  - Storage: 20GB GP3 minimum"
echo "  - Public accessibility: Yes (for testing)"
echo "  - VPC Security Group: Allow inbound on port 5432"
echo "  - Database name: bookstore"
echo "  - Master username: bookstore_user"
echo ""
print_warn "Remember to note the endpoint address for your .env file"

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo ""
print_info "AWS Resources Configuration:"
echo "  Region: $AWS_REGION"
echo "  S3 Bucket: $BUCKET_NAME"
echo "  CloudWatch Log Group: $LOG_GROUP"
if [[ $CREATE_USER =~ ^[Yy]$ ]]; then
    echo "  IAM User: $IAM_USER"
fi
echo ""
print_info "Next Steps:"
echo "  1. Create RDS PostgreSQL instance (manual step)"
echo "  2. Update deployment/testing/config/.env with:"
echo "     - DB_HOST (RDS endpoint)"
echo "     - DB_PASSWORD"
echo "     - AWS_ACCESS_KEY_ID"
echo "     - AWS_SECRET_ACCESS_KEY"
echo "     - Files__BucketName=$BUCKET_NAME"
echo "  3. Run ./scripts/deploy.sh"
echo ""
echo "================================================"
print_info "AWS Resources Setup Complete!"
echo "================================================"

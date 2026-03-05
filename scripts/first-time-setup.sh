#!/usr/bin/env bash
# ============================================
# First-Time Setup Script
# Docker Laravel Development Environment
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

# Welcome
clear
print_header "Docker Laravel Development Environment"
echo "This script will set up your Docker environment."
echo ""
read -p "Press Enter to continue..."

# Step 1: Check Prerequisites
print_header "Step 1: Checking Prerequisites"

if ! grep -qi microsoft /proc/version 2>/dev/null; then
    print_warning "Not detected as WSL2 - script may still work on Linux/Mac"
else
    print_success "Running in WSL2"
fi

if ! command -v docker &>/dev/null; then
    print_error "Docker is not installed or not in PATH"
    exit 1
fi
print_success "Docker: $(docker --version)"

if ! docker compose version &>/dev/null; then
    if ! command -v docker-compose &>/dev/null; then
        print_error "Docker Compose not found"
        exit 1
    fi
    print_success "Docker Compose: $(docker-compose --version)"
else
    print_success "Docker Compose: $(docker compose version)"
fi

if ! docker info &>/dev/null; then
    print_error "Docker is not running"
    print_info "Please start Docker Desktop"
    exit 1
fi
print_success "Docker daemon is running"

# Step 2: Create Directory Structure
print_header "Step 2: Creating Directory Structure"

mkdir -p storage/mysql storage/mongodb storage/mongodb-restore storage/redis
mkdir -p storage/logs/nginx storage/logs/php storage/logs/supervisor storage/logs/credit-control
mkdir -p projects

for d in storage/mysql storage/mongodb storage/mongodb-restore storage/redis \
         storage/logs storage/logs/nginx storage/logs/php storage/logs/supervisor \
         storage/logs/credit-control projects; do
    touch "$d/.gitkeep" 2>/dev/null || true
done

print_success "Directory structure created"

# Step 3: Configure Environment
print_header "Step 3: Configuring Environment"

if [ -f .env ]; then
    print_warning ".env file already exists"
    read -p "Overwrite with .env.example? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing .env"
    else
        cp .env.example .env
        print_success ".env overwritten"
    fi
else
    cp .env.example .env
    print_success ".env created from .env.example"
fi

echo ""
print_info "Set secure passwords (or press Enter to keep defaults from .env.example)"
echo ""

read -sp "MySQL root password [root]: " MYSQL_ROOT_PASS
echo
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS:-root}"

read -sp "Laravel MySQL password [secret]: " MYSQL_LARAVEL_PASS
echo
MYSQL_LARAVEL_PASS="${MYSQL_LARAVEL_PASS:-secret}"

read -sp "Redis password [root]: " REDIS_PASS
echo
REDIS_PASS="${REDIS_PASS:-root}"

read -sp "MongoDB root password [root]: " MONGO_PASS
echo
MONGO_PASS="${MONGO_PASS:-root}"

read -sp "MongoDB Credit Control admin password [changeme]: " MONGO_CC_PASS
echo
MONGO_CC_PASS="${MONGO_CC_PASS:-changeme}"

# Update .env (handle both GNU and BSD sed)
if sed --version &>/dev/null; then
    sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS|" .env
    sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$MYSQL_LARAVEL_PASS|" .env
    sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$REDIS_PASS|" .env
    sed -i "s|^MONGO_ROOT_PASSWORD=.*|MONGO_ROOT_PASSWORD=$MONGO_PASS|" .env
    sed -i "s|^MONGO_CC_ADMIN_PASSWORD=.*|MONGO_CC_ADMIN_PASSWORD=$MONGO_CC_PASS|" .env
else
    sed -i '' "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS|" .env
    sed -i '' "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$MYSQL_LARAVEL_PASS|" .env
    sed -i '' "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$REDIS_PASS|" .env
    sed -i '' "s|^MONGO_ROOT_PASSWORD=.*|MONGO_ROOT_PASSWORD=$MONGO_PASS|" .env
    sed -i '' "s|^MONGO_CC_ADMIN_PASSWORD=.*|MONGO_CC_ADMIN_PASSWORD=$MONGO_CC_PASS|" .env
fi

print_success "Passwords written to .env"

# Step 4: Permissions
print_header "Step 4: Setting Permissions"

chmod +x scripts/*.sh 2>/dev/null || true
chmod -R 775 storage/ 2>/dev/null || true
print_success "Permissions set"

# Step 5: Validate
print_header "Step 5: Validating Configuration"

if docker compose config >/dev/null 2>&1; then
    print_success "docker-compose.yml is valid"
else
    print_error "docker-compose.yml has errors"
    exit 1
fi

[ -f Makefile ] && print_success "Makefile exists" || print_warning "Makefile not found"

# Summary
print_header "Setup Complete!"

echo -e "${GREEN}✓ All checks passed!${NC}"
echo ""
echo "Next steps:"
echo ""
echo "1. Start containers:  ${BLUE}make up${NC}"
echo ""
echo "2. Add a project:      ${BLUE}make new-project${NC}"
echo "   Or clone into:     ./projects/myapp/"
echo ""
echo "3. Add to hosts file (C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "   ${BLUE}127.0.0.1 myapp.local${NC}"
echo ""
echo "4. Access:            ${BLUE}http://myapp.local${NC}"
echo ""
echo "Useful: make help | make ps | make logs"
echo ""
echo "For full instructions, see: docs/SETUP.md"
echo ""
print_success "Happy coding! 🚀"

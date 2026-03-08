#!/bin/bash

COLOR='\033[1;36m'
LIME='\033[1;92m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

MIN_CPU=2
MIN_RAM_GB=2
ERRORS=0

echo ""
printf "${COLOR}========================================${NC}\n"
printf "${COLOR}     BharatSeva System Requirements     ${NC}\n"
printf "${COLOR}========================================${NC}\n"
echo ""

# ─── CPU Check ───────────────────────────────────────────────
AVAILABLE_CPU=$(nproc)
printf "CPU Cores:  Required=${MIN_CPU}  Available=${AVAILABLE_CPU}  →  "
if [ "$AVAILABLE_CPU" -ge "$MIN_CPU" ]; then
    printf "${LIME}PASS${NC}\n"
else
    printf "${RED}FAIL — Need at least ${MIN_CPU} CPU cores (found ${AVAILABLE_CPU})${NC}\n"
    ERRORS=$((ERRORS + 1))
fi

# ─── RAM Check ───────────────────────────────────────────────
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$(awk "BEGIN {printf \"%.1f\", $TOTAL_RAM_KB/1024/1024}")
TOTAL_RAM_GB_INT=$(awk "BEGIN {printf \"%d\", $TOTAL_RAM_KB/1024/1024}")
printf "RAM (GB):   Required=${MIN_RAM_GB}  Available=${TOTAL_RAM_GB}  →  "
if [ "$TOTAL_RAM_GB_INT" -ge "$MIN_RAM_GB" ]; then
    printf "${LIME}PASS${NC}\n"
else
    printf "${RED}FAIL — Need at least ${MIN_RAM_GB}GB RAM (found ${TOTAL_RAM_GB}GB)${NC}\n"
    ERRORS=$((ERRORS + 1))
fi

# ─── Disk Check ──────────────────────────────────────────────
FREE_DISK_GB=$(df / --output=avail -BG | tail -1 | tr -d 'G')
printf "Disk Space: Required=10GB  Available=${FREE_DISK_GB}GB  →  "
if [ "$FREE_DISK_GB" -ge 10 ]; then
    printf "${LIME}PASS${NC}\n"
else
    printf "${YELLOW}WARN — Less than 10GB free (found ${FREE_DISK_GB}GB)${NC}\n"
    ERRORS=$((ERRORS + 1))
fi

# ─── Helper: print install status ────────────────────────────
install_msg() { printf "${YELLOW}  ➜ $1 not found. Installing...${NC}\n"; }
pass_msg()    { printf "  ${LIME}✔ $1${NC}\n"; }
fail_msg()    { printf "  ${RED}✘ $1${NC}\n"; ERRORS=$((ERRORS + 1)); }

# ─── Docker Install & Check ──────────────────────────────────
printf "Docker:     "
if docker info > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    printf "${LIME}PASS — v${DOCKER_VERSION}${NC}\n"
else
    printf "${YELLOW}NOT FOUND${NC}\n"
    install_msg "Docker"

    # Install
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && \
    sudo sh /tmp/get-docker.sh > /dev/null 2>&1 && \
    rm /tmp/get-docker.sh

    # Add user to docker group
    sudo usermod -aG docker "$USER" > /dev/null 2>&1
    # Apply group without re-login using sg
    sudo chmod 666 /var/run/docker.sock > /dev/null 2>&1

    # Verify
    if docker info > /dev/null 2>&1; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
        pass_msg "Docker installed and working — v${DOCKER_VERSION}"
    else
        fail_msg "Docker installed but cannot connect to daemon. Try: sudo chmod 666 /var/run/docker.sock"
    fi
fi

# ─── Docker Compose Install & Check ──────────────────────────
printf "Compose:    "
if docker compose version > /dev/null 2>&1; then
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
    printf "${LIME}PASS — v${COMPOSE_VERSION}${NC}\n"
else
    printf "${YELLOW}NOT FOUND${NC}\n"
    install_msg "Docker Compose"

    # Install compose plugin
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p "$DOCKER_CONFIG/cli-plugins"
    curl -SL "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o "$DOCKER_CONFIG/cli-plugins/docker-compose" > /dev/null 2>&1
    chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"

    # Verify
    if docker compose version > /dev/null 2>&1; then
        COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
        pass_msg "Docker Compose installed and working — v${COMPOSE_VERSION}"
    else
        # Fallback: try apt
        sudo apt-get install -y docker-compose-plugin > /dev/null 2>&1
        if docker compose version > /dev/null 2>&1; then
            COMPOSE_VERSION=$(docker compose version --short 2>/dev/null || echo "unknown")
            pass_msg "Docker Compose installed via apt — v${COMPOSE_VERSION}"
        else
            fail_msg "Docker Compose install failed. Run: sudo apt-get install docker-compose-plugin"
        fi
    fi
fi

# ─── Node.js Install & Check ─────────────────────────────────
printf "Node.js:    "
if command -v node > /dev/null 2>&1; then
    NODE_VERSION=$(node --version)
    printf "${LIME}PASS — ${NODE_VERSION}${NC}\n"
else
    printf "${YELLOW}NOT FOUND${NC}\n"
    install_msg "Node.js LTS"

    # Install via NodeSource
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - > /dev/null 2>&1
    sudo apt-get install -y nodejs > /dev/null 2>&1

    # Verify
    if command -v node > /dev/null 2>&1 && command -v npm > /dev/null 2>&1; then
        NODE_VERSION=$(node --version)
        NPM_VERSION=$(npm --version)
        pass_msg "Node.js installed and working — node ${NODE_VERSION}, npm v${NPM_VERSION}"
    else
        fail_msg "Node.js install failed. Run: sudo apt-get install -y nodejs"
    fi
fi

# ─── Result ──────────────────────────────────────────────────
echo ""
printf "${COLOR}========================================${NC}\n"
if [ "$ERRORS" -eq 0 ]; then
    printf "${LIME}  ✔ All checks passed. Ready to deploy!${NC}\n"
else
    printf "${RED}  ✘ ${ERRORS} check(s) failed. Fix above issues before continuing.${NC}\n"
fi
printf "${COLOR}========================================${NC}\n"
echo ""

exit $ERRORS
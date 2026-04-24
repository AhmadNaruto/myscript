#!/usr/bin/env bash
# =============================================================================
#  Android Builder Setup — Ubuntu 24.04 LTS
#  Version: 4.0 (UI Enhanced)
#  Description: Professional Android Development Environment Installer
#  Usage: chmod +x setup-android-builder.sh && ./setup-android-builder.sh
# =============================================================================

set -euo pipefail

# ── Configuration ────────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="4.0.0"
readonly SCRIPT_NAME="$(basename "$0")"
readonly START_TIME="$(date +%s)"

# ── Color Configuration ──────────────────────────────────────────────────────
setup_colors() {
    if [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
        readonly RED='\033[0;31m'     GREEN='\033[0;32m'    YELLOW='\033[1;33m'
        readonly BLUE='\033[0;34m'    CYAN='\033[0;36m'     MAGENTA='\033[0;35m'
        readonly BOLD='\033[1m'       DIM='\033[2m'         RESET='\033[0m'
        readonly BG_GREEN='\033[42m'  BG_RED='\033[41m'     BG_BLUE='\033[44m'
    else
        readonly RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA=''
        readonly BOLD='' DIM='' RESET='' BG_GREEN='' BG_RED='' BG_BLUE=''
    fi
}
setup_colors

# ── Logging & UI Functions ───────────────────────────────────────────────────
declare -i STEP_COUNT=0
declare -i TOTAL_STEPS=6

log_timestamp() {
    date '+%H:%M:%S'
}

print_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    echo "║   ${BOLD}🤖  Android Builder Setup${RESET} ${CYAN}v${SCRIPT_VERSION}${RESET}                          ║"
    echo "║                                                                   ║"
    echo "║   ${DIM}Professional Development Environment Installer${RESET}                    ║"
    echo "║                                                                   ║"
    echo "╠═══════════════════════════════════════════════════════════════════╣"
    echo "║   ${GREEN}●${RESET} Ubuntu 24.04 LTS    ${GREEN}●${RESET} Java 21 LTS       ${GREEN}●${RESET} Gradle 9.4.1      ║"
    echo "║   ${GREEN}●${RESET} Android API 36      ${GREEN}●${RESET} Build Tools 35.0  ${GREEN}●${RESET} AGP 9.2           ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

print_footer() {
    local duration=$(( $(date +%s) - START_TIME ))
    echo -e "${BOLD}${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                   ║"
    printf "║   ${GREEN}✓${RESET} Setup completed in ${BOLD}%d seconds${RESET}                                  ║\n" "$duration"
    echo "║                                                                   ║"
    echo "║   ${DIM}Happy Coding! 🚀${RESET}                                                   ║"
    echo "║                                                                   ║"
    echo "╚═══════════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

step_header() {
    local step_num="$1"; shift
    local title="$1"; shift
    
    STEP_COUNT=$((STEP_COUNT + 1))
    
    echo ""
    echo -e "${BOLD}${BLUE}┌─────────────────────────────────────────────────────────────────┐${RESET}"
    printf "${BOLD}${BLUE}│${RESET} ${CYAN}Step %d/%d${RESET}  ${BOLD}%s${RESET}" "$step_num" "$TOTAL_STEPS" "$title"
    printf "%*s${BOLD}${BLUE}│${RESET}\n" $((57 - ${#title} - 12)) ""
    echo -e "${BOLD}${BLUE}└─────────────────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

log_info() {
    echo -e "  ${CYAN}ℹ${RESET}  $*"
}

log_success() {
    echo -e "  ${GREEN}✓${RESET}  $*"
}

log_warning() {
    echo -e "  ${YELLOW}⚠${RESET}  $*"
}

log_error() {
    echo -e "  ${RED}✗${RESET}  $*" >&2
}

# Progress Bar Function
print_progress() {
    local current="$1"
    local total="$2"
    local width=50
    local percentage=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    
    printf "\r  ${DIM}[" 
    printf "${GREEN}%${filled}s" | tr ' ' '█'
    printf "${DIM}%${empty}s" | tr ' ' '░'
    printf "] ${percentage}%%${RESET}"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# Status Badge
print_status() {
    local status="$1"; shift
    local message="$*"
    
    local badge=""
    local color=""
    
    case "$status" in
        DONE)
            badge="✓ DONE"
            color="$GREEN"
            ;;
        SKIP)
            badge="⊘ SKIP"
            color="$YELLOW"
            ;;
        FAIL)
            badge="✗ FAIL"
            color="$RED"
            ;;
        INFO)
            badge="ℹ INFO"
            color="$CYAN"
            ;;
    esac
    
    echo -e "  ${color}${BOLD}[${badge}]${RESET}  ${message}"
}

# ── Cleanup Handler ──────────────────────────────────────────────────────────
readonly TMP_DIR="$(mktemp -d)"
cleanup() {
    local exit_code=$?
    if [[ -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR" 2>/dev/null || true
    fi
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        log_error "Script terminated with error code: $exit_code"
    fi
}
trap cleanup EXIT INT TERM

# ── Configuration Values ─────────────────────────────────────────────────────
readonly ANDROID_HOME="${HOME}/android-sdk"
readonly CMDLINE_TOOLS_VERSION="11076708"
readonly GRADLE_VERSION="9.4.1"
readonly GRADLE_HOME="/opt/gradle/gradle-${GRADLE_VERSION}"
readonly ANDROID_API_LEVEL="36"
readonly BUILD_TOOLS_VERSION="35.0.0"

# Architecture Detection
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) ARCH_LABEL="linux" ;;
    aarch64|arm64) ARCH_LABEL="linux-arm" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-${ARCH_LABEL}-${CMDLINE_TOOLS_VERSION}_latest.zip"
readonly GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# Shell Profile
PROFILE_FILE="${HOME}/.bashrc"
[[ -n "${ZSH_VERSION:-}" ]] && PROFILE_FILE="${HOME}/.zshrc"
[[ "$SHELL" == *zsh ]] && PROFILE_FILE="${HOME}/.zshrc"

# ── Helper Functions ─────────────────────────────────────────────────────────
download_with_progress() {
    local url="$1"
    local output="$2"
    local label="$3"
    
    wget --show-progress --progress=bar:force:noscroll \
        --timeout=30 --tries=3 -O "$output" "$url" 2>&1 | \
        grep -E "^[0-9]+K|^[0-9]+M|100%" | tail -1 > /dev/null || true
}

append_env_block() {
    local marker="$1"
    local block="$2"
    
    if grep -qF "$marker" "$PROFILE_FILE" 2>/dev/null; then
        return 0
    fi
    
    printf "\n%s\n" "$block" >> "$PROFILE_FILE"
}

check_command() {
    command -v "$1" &>/dev/null
}

# ── Step Functions ───────────────────────────────────────────────────────────

step_system_packages() {
    step_header 1 "Installing System Packages"
    local step_start=$(date +%s)
    
    log_info "Updating package lists..."
    sudo apt-get update -qq 2>/dev/null
    
    log_info "Installing required dependencies..."
    sudo apt-get install -y --no-install-recommends \
        curl wget unzip zip git ca-certificates gnupg lsb-release \
        lib32z1 lib32stdc++6 build-essential xz-utils \
        > /dev/null 2>&1
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    print_status DONE "System packages installed (${duration}s)"
}

step_java() {
    step_header 2 "Setting up Java 21 (Eclipse Temurin)"
    local step_start=$(date +%s)
    
    if check_command java && java -version 2>&1 | grep -qE 'version "21'; then
        print_status SKIP "Java 21 already installed"
        JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
    else
        log_info "Adding Adoptium repository..."
        
        sudo mkdir -p /etc/apt/keyrings
        
        if [[ ! -f /etc/apt/keyrings/adoptium.gpg ]]; then
            wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
                | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg 2>/dev/null
        fi
        
        if [[ ! -f /etc/apt/sources.list.d/adoptium.list ]]; then
            echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" \
                | sudo tee /etc/apt/sources.list.d/adoptium.list > /dev/null
        fi
        
        log_info "Installing Eclipse Temurin JDK 21..."
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y temurin-21-jdk > /dev/null 2>&1
        
        JAVA_HOME_PATH="/usr/lib/jvm/temurin-21-jdk-amd64"
        [[ ! -d "$JAVA_HOME_PATH" ]] && \
            JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
        
        print_status DONE "Java 21 installed successfully"
    fi
    
    append_env_block "# >>> Android Builder: Java" \
"# >>> Android Builder: Java
export JAVA_HOME=\"${JAVA_HOME_PATH}\"
export PATH=\"\$JAVA_HOME/bin:\$PATH\""
    
    export JAVA_HOME="${JAVA_HOME_PATH}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    log_success "Java version: $(java -version 2>&1 | head -1)"
    print_status DONE "Java configuration complete (${duration}s)"
}

step_android_sdk() {
    step_header 3 "Setting up Android SDK Command-Line Tools"
    local step_start=$(date +%s)
    
    mkdir -p "${ANDROID_HOME}/cmdline-tools"
    
    if [[ -d "${ANDROID_HOME}/cmdline-tools/latest" ]]; then
        print_status SKIP "SDK command-line tools already present"
    else
        log_info "Downloading command-line tools (${ARCH_LABEL})..."
        download_with_progress "$CMDLINE_TOOLS_URL" "${TMP_DIR}/cmdline-tools.zip" "SDK Tools"
        
        log_info "Extracting SDK tools..."
        unzip -q "${TMP_DIR}/cmdline-tools.zip" -d "${ANDROID_HOME}/cmdline-tools" 2>/dev/null
        
        if [[ -d "${ANDROID_HOME}/cmdline-tools/cmdline-tools" ]]; then
            mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
        else
            echo "Extraction structure unexpected, attempting fix..."
            find "${ANDROID_HOME}/cmdline-tools" -type d -name "cmdline-tools" -exec mv {} "${ANDROID_HOME}/cmdline-tools/latest" \;
        fi
        
        print_status DONE "SDK command-line tools installed"
    fi
    
    export ANDROID_HOME="${ANDROID_HOME}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    print_status DONE "SDK tools configured (${duration}s)"
}

step_android_env() {
    step_header 4 "Configuring Android Environment Variables"
    local step_start=$(date +%s)
    
    append_env_block "# >>> Android Builder: SDK" \
"# >>> Android Builder: SDK
export ANDROID_HOME=\"${ANDROID_HOME}\"
export ANDROID_SDK_ROOT=\"${ANDROID_HOME}\"
export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH\"
export PATH=\"\$ANDROID_HOME/platform-tools:\$PATH\"
export PATH=\"\$ANDROID_HOME/emulator:\$PATH\""
    
    export ANDROID_HOME="${ANDROID_HOME}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    print_status DONE "Environment variables configured (${duration}s)"
}

step_sdk_packages() {
    step_header 5 "Installing SDK Packages"
    local step_start=$(date +%s)
    
    log_info "Accepting SDK licenses..."
    yes | sdkmanager --licenses > /dev/null 2>&1 || log_warning "License acceptance had minor issues"
    
    log_info "Installing core components..."
    log_info "  • Platform: android-${ANDROID_API_LEVEL}"
    log_info "  • Build Tools: ${BUILD_TOOLS_VERSION}"
    log_info "  • Platform Tools (adb)"
    
    sdkmanager --install \
        "platform-tools" \
        "platforms;android-${ANDROID_API_LEVEL}" \
        "build-tools;${BUILD_TOOLS_VERSION}" \
        "sources;android-${ANDROID_API_LEVEL}" \
        > /dev/null 2>&1
    
    log_info "Installing additional repositories..."
    sdkmanager --install \
        "extras;google;m2repository" \
        "extras;android;m2repository" \
        > /dev/null 2>&1
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    print_status DONE "SDK packages installed (${duration}s)"
}

step_gradle() {
    step_header 6 "Setting up Gradle ${GRADLE_VERSION}"
    local step_start=$(date +%s)
    
    if [[ -d "${GRADLE_HOME}" ]] && [[ -x "${GRADLE_HOME}/bin/gradle" ]]; then
        print_status SKIP "Gradle ${GRADLE_VERSION} already installed"
    else
        log_info "Downloading Gradle ${GRADLE_VERSION}..."
        download_with_progress "$GRADLE_URL" "${TMP_DIR}/gradle.zip" "Gradle"
        
        log_info "Installing to /opt/gradle..."
        sudo mkdir -p /opt/gradle
        sudo unzip -q "${TMP_DIR}/gradle.zip" -d /opt/gradle 2>/dev/null
        
        print_status DONE "Gradle ${GRADLE_VERSION} installed"
    fi
    
    append_env_block "# >>> Android Builder: Gradle" \
"# >>> Android Builder: Gradle
export GRADLE_HOME=\"${GRADLE_HOME}\"
export PATH=\"\$GRADLE_HOME/bin:\$PATH\""
    
    export GRADLE_HOME="${GRADLE_HOME}"
    export PATH="${GRADLE_HOME}/bin:${PATH}"
    
    local step_end=$(date +%s)
    local duration=$((step_end - step_start))
    
    log_success "Gradle version: $(gradle --version 2>&1 | head -1)"
    print_status DONE "Gradle configuration complete (${duration}s)"
}

# ── Verification Table ───────────────────────────────────────────────────────
print_verification_table() {
    echo ""
    echo -e "${BOLD}${CYAN}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}║                    VERIFICATION SUMMARY                           ║${RESET}"
    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════╣${RESET}"
    
    local all_passed=true
    
    verify_item() {
        local name="$1"; shift
        local cmd="$1"; shift
        local args="$*"
        
        printf "${BOLD}${CYAN}║${RESET}  ${DIM}%-12s${RESET}  " "$name"
        
        if output=$($cmd $args 2>&1 | head -1); then
            printf "${GREEN}%-45s${RESET}" "${output:0:45}"
            echo -e "${BOLD}${CYAN}║${RESET}"
        else
            printf "${RED}%-45s${RESET}" "NOT FOUND"
            echo -e "${BOLD}${CYAN}║${RESET}"
            all_passed=false
        fi
    }
    
    verify_item "Java" java -version
    verify_item "Gradle" gradle --version
    verify_item "adb" adb --version
    verify_item "sdkmanager" sdkmanager --version
    
    echo -e "${BOLD}${CYAN}╠═══════════════════════════════════════════════════════════════════╣${RESET}"
    
    # Installed Packages
    printf "${BOLD}${CYAN}║${RESET}  ${DIM}%-12s${RESET}  " "SDK Packages"
    local pkg_count=$(sdkmanager --list_installed 2>/dev/null | grep -v "^$\|Installed\|-------\|Name" | wc -l)
    printf "${GREEN}%-45s${RESET}" "${pkg_count} packages installed"
    echo -e "${BOLD}${CYAN}║${RESET}"
    
    echo -e "${BOLD}${CYAN}╚═══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    if $all_passed; then
        print_status DONE "All verification checks passed!"
    else
        print_status FAIL "Some verification checks failed. Please review above."
    fi
}

# ── Next Steps Panel ─────────────────────────────────────────────────────────
print_next_steps() {
    echo ""
    echo -e "${BOLD}${BLUE}╔═══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE}║                       NEXT STEPS                                  ║${RESET}"
    echo -e "${BOLD}${BLUE}╠═══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE}║${RESET}                                                                   ${BOLD}${BLUE}║${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}1.${RESET}  Reload shell:     ${DIM}source %-42s${RESET}${BOLD}${BLUE}║${RESET}\n" "${PROFILE_FILE}"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}2.${RESET}  Build project:    ${DIM}cd <project> && ./gradlew%-32s${RESET}${BOLD}${BLUE}║${RESET}\n" "assembleDebug"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}3.${RESET}  Install emulator: ${DIM}sdkmanager \"emulator\"%-44s${RESET}${BOLD}${BLUE}║${RESET}\n" ""
    echo -e "${BOLD}${BLUE}║${RESET}                                                                   ${BOLD}${BLUE}║${RESET}"
    echo -e "${BOLD}${BLUE}╚═══════════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ── System Info Panel ────────────────────────────────────────────────────────
print_system_info() {
    echo -e "${DIM}"
    echo "┌─────────────────────────────────────────────────────────────────┐"
    printf "│  Hostname: %-56s│\n" "$(hostname)"
    printf "│  OS:       %-56s│\n" "$(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    printf "│  Kernel:   %-56s│\n" "$(uname -r)"
    printf "│  Arch:     %-56s│\n" "$ARCH_LABEL"
    printf "│  Profile:  %-56s│\n" "$PROFILE_FILE"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo -e "${RESET}"
    echo ""
}

# ── Main Execution ───────────────────────────────────────────────────────────
main() {
    print_header
    print_system_info
    
    log_info "Starting Android Builder Setup..."
    log_info "Profile: ${PROFILE_FILE} | Arch: ${ARCH_LABEL}"
    echo ""
    
    # Execute all steps
    step_system_packages
    step_java
    step_android_sdk
    step_android_env
    step_sdk_packages
    step_gradle
    
    # Verification & Summary
    print_verification_table
    print_next_steps
    print_footer
    
    return 0
}

# Run main
main "$@"


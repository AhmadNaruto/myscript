#!/usr/bin/env bash
# =============================================================================
#  Android Builder Setup — Ubuntu 24.04 LTS
#  Version: 5.0 (Mobile-Friendly UI)
#  Description: Professional Android Development Environment Installer
#  Usage: chmod +x setup-android-builder.sh && ./setup-android-builder.sh
# =============================================================================

set -euo pipefail

# ── Script Metadata ───────────────────────────────────────────────────────────
readonly SCRIPT_VERSION="5.0.0"
readonly START_TIME="$(date +%s)"

# ── Terminal Width Detection ──────────────────────────────────────────────────
# Clamp to 40–80 chars; default 60 for narrow terminals (Termux etc.)
_TERM_WIDTH="$(tput cols 2>/dev/null || echo 60)"
(( _TERM_WIDTH < 40 )) && _TERM_WIDTH=40
(( _TERM_WIDTH > 80 )) && _TERM_WIDTH=80
readonly TERM_WIDTH="$_TERM_WIDTH"

# Inner content width (box border takes 4 chars: "║  " + "  ║")
readonly INNER_WIDTH=$(( TERM_WIDTH - 4 ))

# ── Color Configuration ───────────────────────────────────────────────────────
setup_colors() {
    if [[ -t 1 ]] && [[ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]]; then
        RED='\033[0;31m'    GREEN='\033[0;32m'   YELLOW='\033[1;33m'
        BLUE='\033[0;34m'   CYAN='\033[0;36m'    MAGENTA='\033[0;35m'
        BOLD='\033[1m'      DIM='\033[2m'         RESET='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' CYAN='' MAGENTA=''
        BOLD='' DIM='' RESET=''
    fi
    readonly RED GREEN YELLOW BLUE CYAN MAGENTA BOLD DIM RESET
}
setup_colors

# ── Box Drawing Helpers ───────────────────────────────────────────────────────
# Repeat a character N times
repeat_char() {
    local char="$1" count="$2"
    printf "%${count}s" | tr ' ' "$char"
}

box_top()    { echo -e "${BOLD}${CYAN}╔$(repeat_char '═' $(( TERM_WIDTH - 2 )))╗${RESET}"; }
box_bottom() { echo -e "${BOLD}${CYAN}╚$(repeat_char '═' $(( TERM_WIDTH - 2 )))╝${RESET}"; }
box_sep()    { echo -e "${BOLD}${CYAN}╠$(repeat_char '═' $(( TERM_WIDTH - 2 )))╣${RESET}"; }
box_empty()  { echo -e "${BOLD}${CYAN}║$(repeat_char ' ' $(( TERM_WIDTH - 2 )))║${RESET}"; }

# Print one line inside a box, left-padded by 2 spaces
# Usage: box_line <color_prefix> <text> <color_reset>
box_line() {
    local prefix="${1:-}" text="${2:-}" suffix="${3:-$RESET}"
    # Strip ANSI for length calculation
    local plain
    plain="$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')"
    local pad=$(( INNER_WIDTH - ${#plain} ))
    (( pad < 0 )) && pad=0
    printf "${BOLD}${CYAN}║${RESET}  %b%b%$(( pad ))s  ${BOLD}${CYAN}║${RESET}\n" \
        "$prefix" "$text" ""
}

# ── Step Tracking ─────────────────────────────────────────────────────────────
declare -i _CURRENT_STEP=0
STEPS=(
    "System Packages"
    "Java 21 (Eclipse Temurin)"
    "Android SDK Command-Line Tools"
    "Android Environment Variables"
    "SDK Packages"
    "Gradle"
)
readonly TOTAL_STEPS="${#STEPS[@]}"

# ── Logging Functions ─────────────────────────────────────────────────────────
log_info()    { echo -e "  ${CYAN}→${RESET}  $*"; }
log_success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
log_warning() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
log_error()   { echo -e "  ${RED}✗${RESET}  $*" >&2; }

# Status badge: DONE | SKIP | FAIL | INFO
print_status() {
    local status="$1"; shift
    local msg="$*"
    local badge color
    case "$status" in
        DONE) badge="✓ DONE"; color="$GREEN"  ;;
        SKIP) badge="⊘ SKIP"; color="$YELLOW" ;;
        FAIL) badge="✗ FAIL"; color="$RED"    ;;
        INFO) badge="ℹ INFO"; color="$CYAN"   ;;
    esac
    echo -e "  ${color}${BOLD}[${badge}]${RESET}  ${msg}"
}

# ── UI Panels ─────────────────────────────────────────────────────────────────
print_header() {
    clear
    echo ""
    box_top
    box_empty
    box_line "" "${BOLD}🤖  Android Builder Setup${RESET} ${CYAN}v${SCRIPT_VERSION}${RESET}"
    box_line "" "${DIM}Android Dev Environment Installer${RESET}"
    box_empty
    box_sep
    box_line "" "${GREEN}●${RESET} Ubuntu 24.04 LTS   ${GREEN}●${RESET} Java 21 LTS"
    box_line "" "${GREEN}●${RESET} Android API 36     ${GREEN}●${RESET} Build Tools 35.0.0"
    box_line "" "${GREEN}●${RESET} Gradle 9.4.1       ${GREEN}●${RESET} AGP 9.2"
    box_empty
    box_bottom
    echo ""
}

print_system_info() {
    local os kernel
    os="$(lsb_release -ds 2>/dev/null || echo 'Unknown')"
    kernel="$(uname -r)"

    echo -e "${DIM}"
    echo "┌$(repeat_char '─' $(( TERM_WIDTH - 2 )))┐"
    printf "│  %-$(( INNER_WIDTH - 2 ))s  │\n" "Host : $(hostname)"
    printf "│  %-$(( INNER_WIDTH - 2 ))s  │\n" "OS   : ${os}"
    printf "│  %-$(( INNER_WIDTH - 2 ))s  │\n" "Arch : ${ARCH_LABEL}"
    printf "│  %-$(( INNER_WIDTH - 2 ))s  │\n" "Shell: ${PROFILE_FILE}"
    echo "└$(repeat_char '─' $(( TERM_WIDTH - 2 )))┘"
    echo -e "${RESET}"
}

step_header() {
    local title="$1"
    _CURRENT_STEP=$(( _CURRENT_STEP + 1 ))
    echo ""
    echo -e "${BOLD}${BLUE}┌$(repeat_char '─' $(( TERM_WIDTH - 2 )))┐${RESET}"
    printf "${BOLD}${BLUE}│${RESET} ${CYAN}[%d/%d]${RESET} ${BOLD}%s${RESET}\n" \
        "$_CURRENT_STEP" "$TOTAL_STEPS" "$title"
    echo -e "${BOLD}${BLUE}└$(repeat_char '─' $(( TERM_WIDTH - 2 )))┘${RESET}"
    echo ""
}

# Inline progress bar, width adapts to terminal
print_progress() {
    local current="$1" total="$2"
    local bar_width=$(( TERM_WIDTH - 16 ))
    (( bar_width < 10 )) && bar_width=10
    local pct=$(( current * 100 / total ))
    local filled=$(( current * bar_width / total ))
    local empty=$(( bar_width - filled ))

    printf "\r  ${DIM}["
    (( filled  > 0 )) && printf "${GREEN}%${filled}s${DIM}"  | tr ' ' '█'
    (( empty   > 0 )) && printf "%${empty}s"  | tr ' ' '░'
    printf "] %3d%%${RESET}" "$pct"

    [[ "$current" -eq "$total" ]] && echo ""
}

print_verification_table() {
    local all_ok=true

    echo ""
    echo -e "${BOLD}${CYAN}╔$(repeat_char '═' $(( TERM_WIDTH - 2 )))╗${RESET}"
    printf "${BOLD}${CYAN}║${RESET}  ${BOLD}%-$(( INNER_WIDTH ))s${RESET}${BOLD}${CYAN}║${RESET}\n" \
        "VERIFICATION SUMMARY"
    echo -e "${BOLD}${CYAN}╠$(repeat_char '═' $(( TERM_WIDTH - 2 )))╣${RESET}"

    _verify_row() {
        local label="$1" cmd="$2"; shift 2
        local out status_color
        # java -version outputs to stderr; redirect both streams
        if out="$("$cmd" "$@" 2>&1 | head -1)"; then
            status_color="$GREEN"
        else
            out="NOT FOUND"
            status_color="$RED"
            all_ok=false
        fi
        # Truncate output to fit inner width
        local max=$(( INNER_WIDTH - ${#label} - 4 ))
        out="${out:0:$max}"
        printf "${BOLD}${CYAN}║${RESET}  ${BOLD}%-10s${RESET}  ${status_color}%s${RESET}\n" \
            "$label" "$out"
    }

    _verify_row "Java"      java      -version
    _verify_row "Gradle"    gradle    --version
    _verify_row "adb"       adb       version
    _verify_row "sdkmgr"    sdkmanager --version

    echo -e "${BOLD}${CYAN}╠$(repeat_char '═' $(( TERM_WIDTH - 2 )))╣${RESET}"

    local pkg_count
    pkg_count="$(sdkmanager --list_installed 2>/dev/null \
        | grep -cE '^\s+[a-zA-Z]' || echo 0)"
    printf "${BOLD}${CYAN}║${RESET}  ${BOLD}%-10s${RESET}  ${GREEN}%s packages installed${RESET}\n" \
        "Packages" "$pkg_count"

    echo -e "${BOLD}${CYAN}╚$(repeat_char '═' $(( TERM_WIDTH - 2 )))╝${RESET}"
    echo ""

    if $all_ok; then
        print_status DONE "All checks passed!"
    else
        print_status FAIL "Some checks failed — review above."
    fi
}

print_next_steps() {
    echo ""
    echo -e "${BOLD}${BLUE}╔$(repeat_char '═' $(( TERM_WIDTH - 2 )))╗${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  ${BOLD}%-$(( INNER_WIDTH ))s${RESET}${BOLD}${BLUE}║${RESET}\n" "NEXT STEPS"
    echo -e "${BOLD}${BLUE}╠$(repeat_char '═' $(( TERM_WIDTH - 2 )))╣${RESET}"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}1.${RESET}  %-$(( INNER_WIDTH - 4 ))s${BOLD}${BLUE}║${RESET}\n" \
        "Reload: source ${PROFILE_FILE}"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}2.${RESET}  %-$(( INNER_WIDTH - 4 ))s${BOLD}${BLUE}║${RESET}\n" \
        "Build: ./gradlew assembleDebug"
    printf "${BOLD}${BLUE}║${RESET}  ${YELLOW}3.${RESET}  %-$(( INNER_WIDTH - 4 ))s${BOLD}${BLUE}║${RESET}\n" \
        "Emulator: sdkmanager \"emulator\""
    echo -e "${BOLD}${BLUE}╚$(repeat_char '═' $(( TERM_WIDTH - 2 )))╝${RESET}"
    echo ""
}

print_footer() {
    local duration=$(( $(date +%s) - START_TIME ))
    echo ""
    echo -e "${BOLD}${CYAN}╔$(repeat_char '═' $(( TERM_WIDTH - 2 )))╗${RESET}"
    box_empty
    printf "${BOLD}${CYAN}║${RESET}  ${GREEN}✓${RESET} Done in ${BOLD}%ds${RESET}%-$(( INNER_WIDTH - 12 - ${#duration} ))s${BOLD}${CYAN}║${RESET}\n" \
        "$duration" ""
    box_line "" "${DIM}Happy Coding! 🚀${RESET}"
    box_empty
    box_bottom
    echo ""
}

# ── Cleanup Handler ───────────────────────────────────────────────────────────
readonly TMP_DIR="$(mktemp -d)"
cleanup() {
    local code=$?
    rm -rf "$TMP_DIR" 2>/dev/null || true
    [[ $code -ne 0 ]] && { echo ""; log_error "Aborted (exit $code)"; }
}
trap cleanup EXIT INT TERM

# ── Configuration ─────────────────────────────────────────────────────────────
readonly ANDROID_HOME="${HOME}/android-sdk"
readonly CMDLINE_TOOLS_VERSION="11076708"
readonly GRADLE_VERSION="9.4.1"
readonly GRADLE_HOME="/opt/gradle/gradle-${GRADLE_VERSION}"
readonly ANDROID_API_LEVEL="36"
readonly BUILD_TOOLS_VERSION="35.0.0"

# Architecture Detection
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)          ARCH_LABEL="linux"     ;;
    aarch64|arm64)   ARCH_LABEL="linux-arm" ;;
    *) log_error "Unsupported architecture: $ARCH"; exit 1 ;;
esac
readonly ARCH_LABEL

readonly CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-${ARCH_LABEL}-${CMDLINE_TOOLS_VERSION}_latest.zip"
readonly GRADLE_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"

# Shell Profile Detection
PROFILE_FILE="${HOME}/.bashrc"
[[ "${SHELL:-}" == *zsh ]] && PROFILE_FILE="${HOME}/.zshrc"
[[ -n "${ZSH_VERSION:-}" ]] && PROFILE_FILE="${HOME}/.zshrc"
readonly PROFILE_FILE

# ── Helper Functions ──────────────────────────────────────────────────────────
check_command() { command -v "$1" &>/dev/null; }

download_with_progress() {
    local url="$1" output="$2" label="$3"
    log_info "Downloading ${label}..."
    wget -q --show-progress --progress=dot:giga \
        --timeout=60 --tries=3 -O "$output" "$url" 2>&1 || {
        log_error "Failed to download: ${label}"
        return 1
    }
}

append_env_block() {
    local marker="$1" block="$2"
    grep -qF "$marker" "$PROFILE_FILE" 2>/dev/null && return 0
    printf "\n%s\n" "$block" >> "$PROFILE_FILE"
}

# ── Installation Steps ────────────────────────────────────────────────────────

step_system_packages() {
    step_header "System Packages"
    local t0=$(date +%s)

    log_info "Updating package lists..."
    sudo apt-get update -qq 2>/dev/null

    log_info "Installing dependencies..."
    sudo apt-get install -y --no-install-recommends \
        curl wget unzip zip git ca-certificates gnupg lsb-release \
        lib32z1 lib32stdc++6 build-essential xz-utils \
        >/dev/null 2>&1

    print_status DONE "Packages installed ($(( $(date +%s) - t0 ))s)"
}

step_java() {
    step_header "Java 21 (Eclipse Temurin)"
    local t0=$(date +%s)

    if check_command java && java -version 2>&1 | grep -qE '"21\.'; then
        print_status SKIP "Java 21 already installed"
        # Resolve JAVA_HOME portably for both x86_64 and aarch64
        JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"
    else
        log_info "Adding Adoptium repository..."
        sudo mkdir -p /etc/apt/keyrings

        if [[ ! -f /etc/apt/keyrings/adoptium.gpg ]]; then
            wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
                | sudo gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg 2>/dev/null
        fi

        if [[ ! -f /etc/apt/sources.list.d/adoptium.list ]]; then
            echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] \
https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" \
                | sudo tee /etc/apt/sources.list.d/adoptium.list >/dev/null
        fi

        log_info "Installing Temurin JDK 21..."
        sudo apt-get update -qq 2>/dev/null
        sudo apt-get install -y temurin-21-jdk >/dev/null 2>&1

        # Resolve JAVA_HOME portably (works for amd64 AND aarch64)
        JAVA_HOME_PATH="$(dirname "$(dirname "$(readlink -f "$(which java)")")")"

        print_status DONE "Java 21 installed"
    fi

    append_env_block "# >>> Android Builder: Java" \
"# >>> Android Builder: Java
export JAVA_HOME=\"${JAVA_HOME_PATH}\"
export PATH=\"\$JAVA_HOME/bin:\$PATH\""

    export JAVA_HOME="${JAVA_HOME_PATH}"
    export PATH="${JAVA_HOME}/bin:${PATH}"

    log_success "$(java -version 2>&1 | head -1)"
    print_status DONE "Java configured ($(( $(date +%s) - t0 ))s)"
}

step_android_sdk() {
    step_header "Android SDK Command-Line Tools"
    local t0=$(date +%s)

    mkdir -p "${ANDROID_HOME}/cmdline-tools"

    if [[ -d "${ANDROID_HOME}/cmdline-tools/latest" ]]; then
        print_status SKIP "SDK tools already present"
    else
        download_with_progress \
            "$CMDLINE_TOOLS_URL" "${TMP_DIR}/cmdline-tools.zip" "SDK Tools"

        log_info "Extracting..."
        unzip -q "${TMP_DIR}/cmdline-tools.zip" \
            -d "${ANDROID_HOME}/cmdline-tools" 2>/dev/null

        # Normalise extracted directory name (Google changes it occasionally)
        if [[ -d "${ANDROID_HOME}/cmdline-tools/cmdline-tools" ]]; then
            mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" \
               "${ANDROID_HOME}/cmdline-tools/latest"
        else
            # Fallback: find and move whatever was extracted
            local found
            found="$(find "${ANDROID_HOME}/cmdline-tools" -maxdepth 1 \
                -type d -not -name 'cmdline-tools' -not -name 'latest' \
                | head -1)"
            [[ -n "$found" ]] && mv "$found" "${ANDROID_HOME}/cmdline-tools/latest"
        fi

        print_status DONE "SDK tools installed"
    fi

    export ANDROID_HOME="${ANDROID_HOME}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"

    print_status DONE "SDK tools configured ($(( $(date +%s) - t0 ))s)"
}

step_android_env() {
    step_header "Android Environment Variables"
    local t0=$(date +%s)

    append_env_block "# >>> Android Builder: SDK" \
"# >>> Android Builder: SDK
export ANDROID_HOME=\"${ANDROID_HOME}\"
export ANDROID_SDK_ROOT=\"${ANDROID_HOME}\"
export PATH=\"\$ANDROID_HOME/cmdline-tools/latest/bin:\$PATH\"
export PATH=\"\$ANDROID_HOME/platform-tools:\$PATH\"
export PATH=\"\$ANDROID_HOME/emulator:\$PATH\""

    export ANDROID_HOME="${ANDROID_HOME}"
    export ANDROID_SDK_ROOT="${ANDROID_HOME}"
    export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:\
${ANDROID_HOME}/platform-tools:${PATH}"

    print_status DONE "Env vars configured ($(( $(date +%s) - t0 ))s)"
}

step_sdk_packages() {
    step_header "SDK Packages"
    local t0=$(date +%s)

    log_info "Accepting licenses..."
    yes | sdkmanager --licenses >/dev/null 2>&1 \
        || log_warning "Some licenses may need manual acceptance"

    log_info "Installing:"
    log_info "  • platforms;android-${ANDROID_API_LEVEL}"
    log_info "  • build-tools;${BUILD_TOOLS_VERSION}"
    log_info "  • platform-tools (adb)"
    log_info "  • sources;android-${ANDROID_API_LEVEL}"

    sdkmanager --install \
        "platform-tools" \
        "platforms;android-${ANDROID_API_LEVEL}" \
        "build-tools;${BUILD_TOOLS_VERSION}" \
        "sources;android-${ANDROID_API_LEVEL}" \
        >/dev/null 2>&1

    log_info "Installing Maven extras..."
    sdkmanager --install \
        "extras;google;m2repository" \
        "extras;android;m2repository" \
        >/dev/null 2>&1

    print_status DONE "SDK packages installed ($(( $(date +%s) - t0 ))s)"
}

step_gradle() {
    step_header "Gradle ${GRADLE_VERSION}"
    local t0=$(date +%s)

    if [[ -d "${GRADLE_HOME}" ]] && [[ -x "${GRADLE_HOME}/bin/gradle" ]]; then
        print_status SKIP "Gradle ${GRADLE_VERSION} already installed"
    else
        download_with_progress "$GRADLE_URL" "${TMP_DIR}/gradle.zip" \
            "Gradle ${GRADLE_VERSION}"

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

    log_success "$(gradle --version 2>&1 | head -1)"
    print_status DONE "Gradle configured ($(( $(date +%s) - t0 ))s)"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    print_header
    print_system_info

    log_info "Starting setup  |  ${TOTAL_STEPS} steps"
    echo ""

    step_system_packages
    step_java
    step_android_sdk
    step_android_env
    step_sdk_packages
    step_gradle

    print_verification_table
    print_next_steps
    print_footer
}

main "$@"


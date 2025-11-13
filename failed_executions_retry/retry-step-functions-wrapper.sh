#!/bin/bash

##############################################################################
# Script: retry-step-functions-wrapper.sh
#
# Purpose:
#   Wrapper script to simplify execution of retry-failed-step-functions.sh
#   Provides an interactive mode or accepts environment variables for configuration
#
# Usage (Interactive):
#   ./retry-step-functions-wrapper.sh
#
# Usage (With Environment Variables):
#   export EXECUTION_DATE="2025-11-13"
#   export AWS_REGION="us-east-1"
#   export AWS_ACCOUNT_ID="123456789012"
#   export AWS_PROFILE="default"
#   export STATE_MACHINE="MyStateMachine"
#   ./retry-step-functions-wrapper.sh
#
##############################################################################

set -o pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly MAIN_SCRIPT="$SCRIPT_DIR/retry-failed-step-functions.sh"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_header() {
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}  Step Functions Retry Script${NC}"
    echo -e "${BLUE}=====================================${NC}"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

check_main_script() {
    if [[ ! -f "$MAIN_SCRIPT" ]]; then
        print_error "Main script not found: $MAIN_SCRIPT"
        exit 1
    fi

    if [[ ! -x "$MAIN_SCRIPT" ]]; then
        print_error "Main script is not executable: $MAIN_SCRIPT"
        echo "Attempting to fix permissions..."
        chmod +x "$MAIN_SCRIPT"
    fi
}

read_input() {
    local prompt="$1"
    local default="$2"
    local input

    if [[ -n "$default" ]]; then
        read -p "$(echo -e ${BLUE})$prompt${NC} (${YELLOW}$default${NC}): " input
        input="${input:-$default}"
    else
        while [[ -z "$input" ]]; do
            read -p "$(echo -e ${BLUE})$prompt${NC}: " input
            if [[ -z "$input" ]]; then
                print_error "This field cannot be empty"
            fi
        done
    fi

    echo "$input"
}

interactive_mode() {
    print_header

    print_info "Interactive Mode - Please provide the following information:"
    echo ""

    EXECUTION_DATE=$(read_input "Execution date (YYYY-MM-DD)" "$(date -d yesterday +%Y-%m-%d)")
    AWS_REGION=$(read_input "AWS Region" "us-east-1")
    AWS_ACCOUNT_ID=$(read_input "AWS Account ID (12 digits)")
    AWS_PROFILE=$(read_input "AWS Profile" "default")
    STATE_MACHINE=$(read_input "State Machine Name")

    print_info ""
    echo ""
}

load_from_env() {
    # Check if environment variables are set
    if [[ -z "$EXECUTION_DATE" ]] || [[ -z "$AWS_REGION" ]] || \
       [[ -z "$AWS_ACCOUNT_ID" ]] || [[ -z "$AWS_PROFILE" ]] || \
       [[ -z "$STATE_MACHINE" ]]; then
        return 1
    fi
    return 0
}

confirm_parameters() {
    echo -e "${YELLOW}Please confirm the following parameters:${NC}"
    echo ""
    echo "  Execution Date:    $EXECUTION_DATE"
    echo "  AWS Region:        $AWS_REGION"
    echo "  AWS Account ID:    $AWS_ACCOUNT_ID"
    echo "  AWS Profile:       $AWS_PROFILE"
    echo "  State Machine:     $STATE_MACHINE"
    echo ""

    read -p "$(echo -e ${BLUE})Is this correct? (y/n)${NC}: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Cancelled by user"
        exit 1
    fi
}

run_main_script() {
    print_info "Executing retry script..."
    echo ""

    if "$MAIN_SCRIPT" \
        --date "$EXECUTION_DATE" \
        --region "$AWS_REGION" \
        --account-id "$AWS_ACCOUNT_ID" \
        --profile "$AWS_PROFILE" \
        --state-machine "$STATE_MACHINE"; then
        print_success "Retry script completed successfully"
        return 0
    else
        print_error "Retry script failed with exit code $?"
        return 1
    fi
}

show_usage() {
    cat <<EOF
${BLUE}Step Functions Retry Wrapper${NC}

${YELLOW}Usage:${NC}

  ${GREEN}Interactive Mode:${NC}
    ./retry-step-functions-wrapper.sh

  ${GREEN}With Environment Variables:${NC}
    export EXECUTION_DATE="2025-11-13"
    export AWS_REGION="us-east-1"
    export AWS_ACCOUNT_ID="123456789012"
    export AWS_PROFILE="default"
    export STATE_MACHINE="MyStateMachine"
    ./retry-step-functions-wrapper.sh

  ${GREEN}One-liner:${NC}
    EXECUTION_DATE=2025-11-13 AWS_REGION=us-east-1 AWS_ACCOUNT_ID=123456789012 \\
    AWS_PROFILE=default STATE_MACHINE=MyStateMachine ./retry-step-functions-wrapper.sh

${YELLOW}Environment Variables:${NC}

  EXECUTION_DATE    Execution date in YYYY-MM-DD format (required)
  AWS_REGION        AWS region name (required)
  AWS_ACCOUNT_ID    AWS account ID, 12 digits (required)
  AWS_PROFILE       AWS CLI profile name (required)
  STATE_MACHINE     Step Functions state machine name (required)

${YELLOW}Examples:${NC}

  # Interactive mode (prompts for all parameters)
  ./retry-step-functions-wrapper.sh

  # With environment variables set
  export EXECUTION_DATE=2025-11-13
  ./retry-step-functions-wrapper.sh

  # All in one line
  EXECUTION_DATE=2025-11-13 AWS_REGION=us-east-1 AWS_ACCOUNT_ID=123456789012 \\
  AWS_PROFILE=default STATE_MACHINE=MyStateMachine ./retry-step-functions-wrapper.sh

EOF
}

main() {
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        show_usage
        exit 0
    fi

    check_main_script

    # Try to load from environment variables
    if ! load_from_env; then
        # Fall back to interactive mode
        interactive_mode
    else
        print_info "Parameters loaded from environment variables"
        echo ""
    fi

    # Show what we're about to do
    confirm_parameters

    # Run the main script
    echo ""
    run_main_script
    exit $?
}

# Run main function
main "$@"

#!/bin/bash

##############################################################################
# Diagnostic Script for Step Functions Retry Setup
#
# Usage: ./diagnose-setup.sh --profile cpe_admin-cpe --region us-east-1
#
##############################################################################

set -o pipefail

readonly PROFILE="${1:-default}"
readonly REGION="${2:-us-east-1}"
readonly ACCOUNT_ID="${3:-}"
readonly STATE_MACHINE="${4:-}"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  AWS Step Functions Setup Diagnostics${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BLUE}▶ $1${NC}"
    echo -e "${BLUE}──────────────────────────────────────────${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

test_command_exists() {
    local cmd="$1"
    local name="$2"
    
    if command -v "$cmd" &>/dev/null; then
        local version=$($cmd --version 2>&1 | head -1)
        print_success "$name is installed: $version"
        return 0
    else
        print_error "$name is NOT installed"
        return 1
    fi
}

test_aws_credentials() {
    local profile="$1"
    local region="$2"
    
    local output
    output=$(aws sts get-caller-identity \
        --profile "$profile" \
        --region "$region" \
        --output json 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "AWS credentials are valid"
        
        local account=$(echo "$output" | jq -r '.Account' 2>/dev/null)
        local arn=$(echo "$output" | jq -r '.Arn' 2>/dev/null)
        
        print_info "Account: $account"
        print_info "ARN: $arn"
        return 0
    else
        print_error "AWS credentials are NOT valid"
        print_info "Output: $output"
        return 1
    fi
}

test_aws_profile_config() {
    local profile="$1"
    
    local config_output
    config_output=$(aws configure list --profile "$profile" 2>&1)
    
    if [[ $? -eq 0 ]]; then
        print_success "AWS profile '$profile' is configured"
        echo "$config_output" | sed 's/^/      /'
        return 0
    else
        print_error "AWS profile '$profile' is NOT configured"
        print_info "Output: $config_output"
        return 1
    fi
}

test_state_machines() {
    local profile="$1"
    local region="$2"
    
    local output
    output=$(aws stepfunctions list-state-machines \
        --profile "$profile" \
        --region "$region" \
        --output json 2>&1)
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to list state machines"
        print_info "Output: $output"
        return 1
    fi
    
    local count=$(echo "$output" | jq '.stateMachines | length' 2>/dev/null)
    
    if [[ "$count" -eq 0 ]]; then
        print_warning "No state machines found in $region"
        return 1
    fi
    
    print_success "Found $count state machine(s) in region $region"
    echo "$output" | jq -r '.stateMachines[] | "\(.name) - \(.stateMachineArn)"' | sed 's/^/      /'
    return 0
}

test_failed_executions() {
    local profile="$1"
    local region="$2"
    local state_machine="$3"
    local account_id="$4"
    
    if [[ -z "$state_machine" ]] || [[ -z "$account_id" ]]; then
        print_warning "Skipping execution test (state machine or account ID not provided)"
        return 0
    fi
    
    local arn="arn:aws:states:${region}:${account_id}:stateMachine:${state_machine}"
    
    print_info "Testing with state machine ARN: $arn"
    
    local output
    output=$(aws stepfunctions list-executions \
        --state-machine-arn "$arn" \
        --status-filter FAILED \
        --profile "$profile" \
        --region "$region" \
        --max-results 10 \
        --output json 2>&1)
    
    if [[ $? -ne 0 ]]; then
        print_error "Failed to list executions"
        print_info "Output: $output"
        return 1
    fi
    
    local count=$(echo "$output" | jq '.executions | length' 2>/dev/null)
    
    if [[ "$count" -eq 0 ]]; then
        print_warning "No failed executions found (this may be normal if there were no failures)"
        return 0
    fi
    
    print_success "Found $count failed execution(s) (showing last 10)"
    echo "$output" | jq -r '.executions[] | "\(.name) - \(.stopDate)"' | sed 's/^/      /'
    return 0
}

test_jq() {
    if ! command -v jq &>/dev/null; then
        print_error "jq is NOT installed"
        return 1
    fi
    
    local version=$(jq --version)
    print_success "jq is installed: $version"
    
    # Test jq with sample JSON
    local test_json='{"test": "value", "number": 123}'
    if echo "$test_json" | jq . &>/dev/null; then
        print_success "jq can parse JSON"
        return 0
    else
        print_error "jq cannot parse JSON properly"
        return 1
    fi
}

show_next_steps() {
    print_section "Next Steps"
    
    echo ""
    echo "If all checks passed:"
    echo "1. Run the retry script:"
    echo ""
    echo "   ./retry-failed-step-functions.sh \\"
    echo "     --date 2025-11-13 \\"
    echo "     --region $REGION \\"
    echo "     --account-id $ACCOUNT_ID \\"
    echo "     --profile $PROFILE \\"
    echo "     --state-machine $STATE_MACHINE"
    echo ""
    echo "Notes:"
    echo "  • Diagnostic script shows last 10 failed executions"
    echo "  • Main script will process ALL failures for the specified date"
    echo "  • Failed executions are sorted by stop date (newest first)"
    echo ""
    echo "If checks failed, refer to TROUBLESHOOTING.md for solutions."
    echo ""
}

main() {
    print_header
    
    echo "Configuration:"
    echo "  Profile: $PROFILE"
    echo "  Region: $REGION"
    if [[ -n "$ACCOUNT_ID" ]]; then
        echo "  Account ID: $ACCOUNT_ID"
    fi
    if [[ -n "$STATE_MACHINE" ]]; then
        echo "  State Machine: $STATE_MACHINE"
    fi
    echo ""
    
    # Check dependencies
    print_section "Checking Dependencies"
    test_command_exists "aws" "AWS CLI"
    test_command_exists "jq" "jq"
    test_jq
    
    # Check AWS configuration
    print_section "Checking AWS Configuration"
    test_aws_profile_config "$PROFILE"
    test_aws_credentials "$PROFILE" "$REGION"
    
    # Check AWS permissions
    print_section "Checking AWS Permissions"
    test_state_machines "$PROFILE" "$REGION"
    
    if [[ -n "$STATE_MACHINE" ]] && [[ -n "$ACCOUNT_ID" ]]; then
        test_failed_executions "$PROFILE" "$REGION" "$STATE_MACHINE" "$ACCOUNT_ID"
    fi
    
    # Show next steps
    show_next_steps
}

# Run diagnostics
main "$@"

#!/bin/bash

##############################################################################
# Script: retry-failed-step-functions.sh
#
# Purpose:
#   Retrieves failed executions of an AWS Step Functions state machine for a
#   given date and restarts any that failed at the PatchDrupalSection state.
#   New executions are named based on the first part of the failed execution
#   name with "-r" appended (e.g., ca9961be-4d81-5245-48af-b0c716acab71_af5c8774...
#   becomes ca9961be-r).
#
# Usage:
#   ./retry-failed-step-functions.sh \
#     --date YYYY-MM-DD \
#     --region us-east-1 \
#     --account-id 123456789012 \
#     --profile my-profile \
#     --state-machine my-state-machine
#
# Parameters:
#   --date            Execution date in YYYY-MM-DD format (required)
#   --region          AWS region (e.g., us-east-1, us-west-2) (required)
#   --account-id      AWS account ID (required)
#   --profile         AWS CLI profile name (required)
#   --state-machine   State machine name (required)
#   --help            Display usage information
#
# Dependencies:
#   - AWS CLI (v2 recommended)
#   - jq (JSON query tool)
#
##############################################################################

set -o pipefail

# Script configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly FAILED_STATE="PatchDrupalSection"
readonly WAIT_BETWEEN_EXECUTIONS=5  # seconds
readonly MAX_RETRIES=3

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'  # No Color

# Variables
DATE=""
REGION=""
ACCOUNT_ID=""
PROFILE=""
STATE_MACHINE=""
VERBOSE=false

##############################################################################
# Output Functions
##############################################################################

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

print_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $1" >&2
    fi
}

##############################################################################
# Validation Functions
##############################################################################

validate_date_format() {
    local date="$1"
    if ! [[ "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        print_error "Invalid date format. Expected YYYY-MM-DD, got: $date"
        return 1
    fi
    
    # Validate that the date is valid (cross-platform compatible)
    local year month day
    year="${date:0:4}"
    month="${date:5:2}"
    day="${date:8:2}"
    
    # Basic validation
    if (( month < 1 || month > 12 )); then
        print_error "Invalid month in date: $date"
        return 1
    fi
    
    if (( day < 1 || day > 31 )); then
        print_error "Invalid day in date: $date"
        return 1
    fi
    
    # Try to validate with date command (works on Linux)
    if command -v date &>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses different date command
            if ! date -f "%Y-%m-%d" -j "$date" &>/dev/null 2>&1; then
                print_verbose "Could not validate date with macOS date command, but format looks valid"
            fi
        else
            # Linux
            if ! date -d "$date" &>/dev/null 2>&1; then
                print_verbose "Could not validate date with Linux date command, but format looks valid"
            fi
        fi
    fi
    
    print_verbose "Date format validated: $date"
    return 0
}

validate_aws_region() {
    local region="$1"
    if ! [[ "$region" =~ ^[a-z]{2}-[a-z]+-[0-9]$ ]]; then
        print_warning "Region format looks unusual: $region (continuing anyway)"
    fi
    return 0
}

validate_aws_account_id() {
    local account_id="$1"
    if ! [[ "$account_id" =~ ^[0-9]{12}$ ]]; then
        print_error "Invalid AWS account ID format. Must be 12 digits, got: $account_id"
        return 1
    fi
    return 0
}

check_dependencies() {
    local missing_deps=0

    if ! command -v aws &>/dev/null; then
        print_error "AWS CLI is not installed or not in PATH"
        missing_deps=$((missing_deps + 1))
    fi

    if ! command -v jq &>/dev/null; then
        print_error "jq is not installed or not in PATH"
        missing_deps=$((missing_deps + 1))
    fi

    if [[ $missing_deps -gt 0 ]]; then
        print_error "Missing $missing_deps dependency/dependencies"
        return 1
    fi
    return 0
}

##############################################################################
# AWS Functions
##############################################################################

test_aws_credentials() {
    local profile="$1"
    local region="$2"

    print_info "Testing AWS credentials with profile: $profile"

    if ! aws sts get-caller-identity \
        --profile "$profile" \
        --region "$region" \
        &>/dev/null; then
        print_error "Failed to authenticate with AWS CLI. Check profile: $profile"
        return 1
    fi

    print_success "AWS credentials validated"
    return 0
}

get_state_machine_arn() {
    local state_machine="$1"
    local account_id="$2"
    local region="$3"

    # Construct the expected ARN format
    local arn="arn:aws:states:${region}:${account_id}:stateMachine:${state_machine}"

    # Only echo the ARN - no verbose messages here to avoid mixing with output
    echo "$arn"
}

get_failed_executions() {
    local state_machine_arn="$1"
    local start_date="$2"
    local end_date="$3"
    local region="$4"
    local profile="$5"

    print_info "Fetching failed executions for $start_date"

    # Add one day to end_date to make it inclusive (cross-platform compatible)
    local end_date_inclusive
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        end_date_inclusive=$(date -f "%Y-%m-%d" -j -v+1d "$end_date" +%Y-%m-%d 2>/dev/null || echo "$end_date")
    else
        # Linux
        end_date_inclusive=$(date -d "$end_date + 1 day" +%Y-%m-%d 2>/dev/null || echo "$end_date")
    fi
    if [[ -z "$end_date_inclusive" ]]; then
        end_date_inclusive="$end_date"
    fi

    local executions
    local aws_output
    
    print_verbose "State Machine ARN: $state_machine_arn"
    print_verbose "Profile: $profile, Region: $region"
    print_verbose "Querying for failed executions (max 100 results)..."
    
    # Run the AWS command
    aws_output=$(aws stepfunctions list-executions \
        --state-machine-arn "$state_machine_arn" \
        --status-filter FAILED \
        --profile "$profile" \
        --region "$region" \
        --max-results 100 \
        --output json 2>&1)
    
    local aws_exit_code=$?
    
    # For debugging - save the raw response
    if [[ -n "$VERBOSE" ]] && [[ "$VERBOSE" == "true" ]]; then
        echo "$aws_output" > /tmp/aws_response_debug.json 2>/dev/null
        print_verbose "Raw AWS response saved to /tmp/aws_response_debug.json"
    fi
    
    if [[ $aws_exit_code -ne 0 ]]; then
        print_error "AWS CLI failed with exit code $aws_exit_code"
        print_error "Command: aws stepfunctions list-executions"
        print_error "State Machine ARN: $state_machine_arn"
        print_error "Profile: $profile"
        print_error "Region: $region"
        print_error ""
        print_error "AWS Error Output:"
        echo "$aws_output" | while IFS= read -r line; do
            print_error "  $line"
        done
        print_verbose "Full AWS output: $aws_output"
        return 1
    fi
    
    print_verbose "AWS response received successfully"
    print_verbose "Response size: ${#aws_output} bytes"
    print_verbose "Response preview (first 150 chars): ${aws_output:0:150}"
    
    # Check if response looks like an error (starts with 'An error occurred')
    if [[ "$aws_output" =~ ^An\ error\ occurred ]]; then
        print_error "AWS API returned an error:"
        echo "$aws_output" | sed 's/^/  /'
        return 1
    fi
    
    # Validate JSON before trying to parse
    if ! echo "$aws_output" | jq empty 2>/dev/null; then
        print_error "AWS CLI returned invalid JSON"
        print_error "Raw AWS response (first 500 chars):"
        echo "${aws_output:0:500}" | sed 's/^/  /'
        print_error ""
        print_error "Full response length: ${#aws_output} bytes"
        print_verbose "Full raw response: $aws_output"
        return 1
    fi
    
    # Filter executions by start date
    # Handle both timezone-aware and timezone-naive ISO dates
    print_verbose "Attempting to filter executions by date: $start_date"
    
    # Debug: Show what we're filtering
    local exec_count=$(echo "$aws_output" | jq '.executions | length' 2>/dev/null || echo "0")
    print_verbose "Total executions in AWS response: $exec_count"
    
    # Use jq to output an array of matching executions
    local jq_filter='.executions | map(select(.stopDate | startswith($start_date)))'
    print_verbose "JQ Filter: $jq_filter"
    
    executions=$(echo "$aws_output" | jq --arg start_date "$start_date" \
        '.executions | map(select(.stopDate | startswith($start_date)))' 2>/dev/null)
    
    local filter_exit=$?
    
    if [[ $filter_exit -ne 0 ]]; then
        print_error "Failed to parse execution data with jq"
        # Try again to capture error
        local jq_err=$(echo "$aws_output" | jq --arg start_date "$start_date" \
            '.executions | map(select(.stopDate | startswith($start_date)))' 2>&1)
        print_error "jq error output:"
        echo "$jq_err" | sed 's/^/  /'
        print_error ""
        print_error "Start date was: $start_date"
        print_error "AWS Response (first 300 chars): ${aws_output:0:300}"
        print_verbose "Full AWS response: $aws_output"
        return 1
    fi
    
    print_verbose "JQ filter completed successfully"
    print_verbose "Filter result (first 100 chars): ${executions:0:100}"
    
    # Check if we got any matches
    local match_count=$(echo "$executions" | jq 'length' 2>/dev/null || echo "0")
    print_verbose "Match count: $match_count"
    
    if [[ "$match_count" == "0" ]] || [[ -z "$executions" ]]; then
        print_info "No failed executions found for date: $start_date"
        print_verbose "Matched 0 executions out of failed list"
        return 0
    fi
    
    print_verbose "Found $match_count execution(s) matching the date"
    
    # Output each execution as a separate line (for while read loop)
    # Suppress stderr to prevent jq errors from appearing in output
    echo "$executions" | jq -c '.[]' 2>/dev/null
    return 0
}

get_execution_details() {
    local execution_arn="$1"
    local region="$2"
    local profile="$3"

    local details
    details=$(aws stepfunctions describe-execution \
        --execution-arn "$execution_arn" \
        --profile "$profile" \
        --region "$region" \
        --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        print_error "Failed to describe execution: $execution_arn"
        return 1
    fi

    echo "$details"
    return 0
}

get_execution_history() {
    local execution_arn="$1"
    local region="$2"
    local profile="$3"

    local history
    history=$(aws stepfunctions get-execution-history \
        --execution-arn "$execution_arn" \
        --profile "$profile" \
        --region "$region" \
        --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        print_error "Failed to get execution history: $execution_arn"
        return 1
    fi

    echo "$history"
    return 0
}

failed_at_target_state() {
    local execution_arn="$1"
    local target_state="$2"
    local region="$3"
    local profile="$4"

    local history
    history=$(get_execution_history "$execution_arn" "$region" "$profile")

    if [[ -z "$history" ]]; then
        return 1
    fi

    # Look for a StateFailed event with the target state name
    if echo "$history" | jq -e ".events[] | select(.type==\"StateFailed\" and .stateFailedEventDetails.state==\"$target_state\")" &>/dev/null; then
        return 0
    fi

    return 1
}

start_new_execution() {
    local state_machine_arn="$1"
    local execution_name="$2"
    local region="$3"
    local profile="$4"
    local input="${5:-{}}"

    print_info "Starting new execution: $execution_name"

    local response
    response=$(aws stepfunctions start-execution \
        --state-machine-arn "$state_machine_arn" \
        --name "$execution_name" \
        --input "$input" \
        --profile "$profile" \
        --region "$region" \
        --output json 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        print_error "Failed to start execution: $execution_name"
        return 1
    fi

    local execution_arn
    execution_arn=$(echo "$response" | jq -r '.executionArn')

    print_success "New execution started: $execution_arn"
    echo "$execution_arn"
    return 0
}

##############################################################################
# Processing Functions
##############################################################################

extract_execution_name_prefix() {
    local execution_name="$1"

    # Extract the first part before the underscore
    local prefix="${execution_name%%_*}"

    echo "${prefix}-r"
}

process_failed_executions() {
    local state_machine_arn="$1"
    local date="$2"
    local region="$3"
    local profile="$4"
    local failed_state="$5"

    local failed_executions
    failed_executions=$(get_failed_executions "$state_machine_arn" "$date" "$date" "$region" "$profile")

    if [[ -z "$failed_executions" ]]; then
        print_info "No failed executions found for $date"
        return 0
    fi

    local execution_count=0
    local restarted_count=0
    local failed_to_restart=0

    while IFS= read -r execution; do
        # Skip empty lines
        if [[ -z "$execution" ]]; then
            continue
        fi
        
        execution_count=$((execution_count + 1))
        
        print_verbose "Processing execution $execution_count"

        local execution_arn
        execution_arn=$(echo "$execution" | jq -r '.executionArn' 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_error "Failed to parse execution ARN"
            print_error "Execution data: $execution"
            print_error "jq error: $execution_arn"
            continue
        fi
        
        if [[ -z "$execution_arn" ]]; then
            print_warning "Could not parse execution ARN from: $execution"
            continue
        fi

        local execution_name
        execution_name=$(echo "$execution" | jq -r '.name' 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_error "Failed to parse execution name"
            print_error "Execution data: $execution"
            print_error "jq error: $execution_name"
            continue
        fi
        
        if [[ -z "$execution_name" ]]; then
            print_warning "Could not parse execution name from: $execution"
            continue
        fi

        print_info "Checking execution ($execution_count): $execution_name"

        # Check if this execution failed at the target state
        if failed_at_target_state "$execution_arn" "$failed_state" "$region" "$profile"; then
            print_info "  -> Failed at $failed_state state"

            # Get the execution input to use for the retry
            local details
            details=$(get_execution_details "$execution_arn" "$region" "$profile")

            local execution_input
            execution_input=$(echo "$details" | jq -r '.input // "{}"')

            # Extract new execution name
            local new_execution_name
            new_execution_name=$(extract_execution_name_prefix "$execution_name")

            print_info "  -> Will restart as: $new_execution_name"

            # Start the new execution
            if start_new_execution "$state_machine_arn" "$new_execution_name" "$region" "$profile" "$execution_input"; then
                restarted_count=$((restarted_count + 1))

                # Wait before starting the next execution
                print_info "  -> Waiting $WAIT_BETWEEN_EXECUTIONS seconds before next execution..."
                sleep "$WAIT_BETWEEN_EXECUTIONS"
            else
                failed_to_restart=$((failed_to_restart + 1))
            fi
        else
            print_info "  -> Did not fail at $failed_state state, skipping"
        fi
    done <<< "$failed_executions"

    print_info ""
    print_info "====== Summary ======"
    print_info "Total failed executions found: $execution_count"
    print_info "Executions restarted: $restarted_count"
    if [[ $failed_to_restart -gt 0 ]]; then
        print_warning "Failed to restart: $failed_to_restart"
    fi
    print_info ""

    if [[ $restarted_count -gt 0 ]]; then
        print_success "Retry process completed with $restarted_count execution(s) restarted"
        return 0
    else
        print_warning "No executions were restarted"
        return 1
    fi
}

##############################################################################
# Usage and Help
##############################################################################

show_usage() {
    cat <<EOF
Usage: $SCRIPT_NAME [OPTIONS]

Description:
  Retrieves failed executions of an AWS Step Functions state machine for a
  given date and restarts any that failed at the $FAILED_STATE state.

Required Options:
  --date DATE              Execution date in YYYY-MM-DD format
  --region REGION          AWS region (e.g., us-east-1, us-west-2)
  --account-id ACCOUNT_ID  AWS account ID (12 digits)
  --profile PROFILE        AWS CLI profile name
  --state-machine NAME     Step Functions state machine name

Optional Options:
  --verbose                Enable verbose output
  --help                   Display this help message

Example:
  $SCRIPT_NAME \\
    --date 2025-11-13 \\
    --region us-east-1 \\
    --account-id 123456789012 \\
    --profile default \\
    --state-machine MyStateMachine

EOF
}

##############################################################################
# Argument Parsing
##############################################################################

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --date)
                DATE="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --account-id)
                ACCOUNT_ID="$2"
                shift 2
                ;;
            --profile)
                PROFILE="$2"
                shift 2
                ;;
            --state-machine)
                STATE_MACHINE="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

##############################################################################
# Main
##############################################################################

main() {
    parse_arguments "$@"

    # Validate all required parameters are provided
    if [[ -z "$DATE" ]] || [[ -z "$REGION" ]] || [[ -z "$ACCOUNT_ID" ]] || [[ -z "$PROFILE" ]] || [[ -z "$STATE_MACHINE" ]]; then
        print_error "Missing required parameters"
        show_usage
        exit 1
    fi

    print_info "Step Functions Execution Retry Script"
    print_info "======================================"
    print_info "Date: $DATE"
    print_info "Region: $REGION"
    print_info "Account ID: $ACCOUNT_ID"
    print_info "Profile: $PROFILE"
    print_info "State Machine: $STATE_MACHINE"
    print_info "Target State: $FAILED_STATE"
    print_info ""

    # Validate dependencies
    if ! check_dependencies; then
        print_error "Dependency check failed"
        exit 1
    fi

    # Validate inputs
    if ! validate_date_format "$DATE"; then
        exit 1
    fi

    if ! validate_aws_region "$REGION"; then
        exit 1
    fi

    if ! validate_aws_account_id "$ACCOUNT_ID"; then
        exit 1
    fi

    # Test AWS credentials
    if ! test_aws_credentials "$PROFILE" "$REGION"; then
        exit 1
    fi

    # Get state machine ARN
    local state_machine_arn
    state_machine_arn=$(get_state_machine_arn "$STATE_MACHINE" "$ACCOUNT_ID" "$REGION")
    
    print_verbose "Resolved state machine ARN: $state_machine_arn"

    # Process failed executions
    if ! process_failed_executions "$state_machine_arn" "$DATE" "$REGION" "$PROFILE" "$FAILED_STATE"; then
        exit 1
    fi

    exit 0
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

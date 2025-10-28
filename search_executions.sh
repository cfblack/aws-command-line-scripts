#!/bin/bash

# Usage: ./search_executions.sh <date> <object_id> <region> <account_id> <profile>
# Example: ./search_executions.sh 2025-10-27 65232714 us-west-2 123456789012 my-profile

if [ $# -ne 5 ]; then
    echo "Usage: $0 <date> <object_id> <region> <account_id> <profile>"
    echo "Example: $0 2025-10-27 65232714 us-west-2 123456789012 my-profile"
    exit 1
fi

DATE="$1"
OBJECT_ID="$2"
REGION="$3"
ACCOUNT_ID="$4"
PROFILE="$5"

echo "Searching for executions on $DATE with object ID $OBJECT_ID using profile $PROFILE..."
echo ""

# Get execution ARNs as a JSON array
execution_arns=$(aws stepfunctions list-executions \
  --profile "$PROFILE" \
  --region "$REGION" \
  --state-machine-arn "arn:aws:states:$REGION:$ACCOUNT_ID:stateMachine:RelatedSectionContent-production" \
  --query "executions[?starts_with(startDate, '$DATE')].executionArn" \
  --output json)

# Get the count of executions
count=$(echo "$execution_arns" | jq '. | length')

# Process each execution ARN
for ((i=0; i<$count; i++)); do
  execution_arn=$(echo "$execution_arns" | jq -r ".[$i]")
  
  if [ -n "$execution_arn" ] && [ "$execution_arn" != "null" ]; then
    # Get full execution details including status and input
    execution_details=$(aws stepfunctions describe-execution \
      --profile "$PROFILE" \
      --region "$REGION" \
      --execution-arn "$execution_arn" \
      --output json 2>&1)
    
    # Check if the command was successful
    if [ $? -eq 0 ]; then
      input=$(echo "$execution_details" | jq -r '.input')
      status=$(echo "$execution_details" | jq -r '.status')
      
      if echo "$input" | grep -q "$OBJECT_ID"; then
        # URL-encode the execution ARN for the console URL
        encoded_arn=$(echo -n "$execution_arn" | jq -sRr @uri)
        console_url="https://${ACCOUNT_ID}-p2f4gusb.${REGION}.console.aws.amazon.com/states/home?region=${REGION}#/v2/executions/details/${encoded_arn}"
        
        echo "Execution ARN: $execution_arn"
        echo "Status: $status"
        echo "Console URL: $console_url"
        echo "Input: $input"
        echo "---"
      fi
    fi
  fi
done

echo "Search complete!"
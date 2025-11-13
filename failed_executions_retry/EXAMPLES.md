# Step Functions Retry Script - Configuration & Usage Examples

## Configuration File Approach

If you prefer to use a configuration file instead of command-line arguments, you can create a config file and source it:

### Create a config file (e.g., `retry-config.sh`)

```bash
#!/bin/bash

# Step Functions Retry Configuration

# Execution date (YYYY-MM-DD format)
# Use: EXECUTION_DATE="2025-11-13"
# Or dynamically: EXECUTION_DATE=$(date -d yesterday +%Y-%m-%d)
EXECUTION_DATE="$(date -d yesterday +%Y-%m-%d)"

# AWS Region
AWS_REGION="us-east-1"

# AWS Account ID
AWS_ACCOUNT_ID="123456789012"

# AWS CLI Profile
AWS_PROFILE="default"

# Step Functions State Machine Name
STATE_MACHINE_NAME="MyStateMachine"

# Optional: Enable verbose output (true/false)
VERBOSE_MODE="false"
```

### Modified Script to Use Configuration

```bash
# Source the configuration file
source ./retry-config.sh

# Run the script with sourced variables
./retry-failed-step-functions.sh \
  --date "$EXECUTION_DATE" \
  --region "$AWS_REGION" \
  --account-id "$AWS_ACCOUNT_ID" \
  --profile "$AWS_PROFILE" \
  --state-machine "$STATE_MACHINE_NAME"
```

## Usage Examples

### Example 1: Daily Automated Retry

Process failed executions from yesterday:

```bash
#!/bin/bash

YESTERDAY=$(date -d yesterday +%Y-%m-%d)

./retry-failed-step-functions.sh \
  --date "$YESTERDAY" \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Example 2: Multiple Regions

Retry failed executions in multiple regions:

```bash
#!/bin/bash

REGIONS=("us-east-1" "us-west-2" "eu-west-1")
EXECUTION_DATE="2025-11-13"

for region in "${REGIONS[@]}"; do
  echo "Processing region: $region"
  
  ./retry-failed-step-functions.sh \
    --date "$EXECUTION_DATE" \
    --region "$region" \
    --account-id 123456789012 \
    --profile default \
    --state-machine MyStateMachine
done
```

### Example 3: Multiple State Machines

Modify the script to retry specific state machines:

```bash
#!/bin/bash

STATE_MACHINES=("StateMachine-A" "StateMachine-B" "StateMachine-C")
EXECUTION_DATE="2025-11-13"

for state_machine in "${STATE_MACHINES[@]}"; do
  echo "Processing state machine: $state_machine"
  
  ./retry-failed-step-functions.sh \
    --date "$EXECUTION_DATE" \
    --region us-east-1 \
    --account-id 123456789012 \
    --profile default \
    --state-machine "$state_machine"
done
```

### Example 4: With Error Handling and Logging

```bash
#!/bin/bash

set -o pipefail

LOG_FILE="/var/log/step-functions-retry.log"
EXECUTION_DATE="$(date -d yesterday +%Y-%m-%d)"

{
  echo "========================================"
  echo "Step Functions Retry Script"
  echo "Execution Date: $EXECUTION_DATE"
  echo "Timestamp: $(date)"
  echo "========================================"
  
  if ./retry-failed-step-functions.sh \
    --date "$EXECUTION_DATE" \
    --region us-east-1 \
    --account-id 123456789012 \
    --profile default \
    --state-machine MyStateMachine; then
    echo "SUCCESS: Retry completed successfully at $(date)"
  else
    echo "ERROR: Retry failed with exit code $? at $(date)"
    exit 1
  fi
} | tee -a "$LOG_FILE"
```

### Example 5: Retry with Specific Date Range

Process multiple days:

```bash
#!/bin/bash

START_DATE="2025-11-10"
END_DATE="2025-11-13"

current_date="$START_DATE"

while [[ "$current_date" < "$END_DATE" ]]; do
  echo "Processing: $current_date"
  
  ./retry-failed-step-functions.sh \
    --date "$current_date" \
    --region us-east-1 \
    --account-id 123456789012 \
    --profile default \
    --state-machine MyStateMachine
  
  # Move to next day
  current_date=$(date -d "$current_date + 1 day" +%Y-%m-%d)
done
```

### Example 6: With Notifications

Send notification on completion:

```bash
#!/bin/bash

EXECUTION_DATE="$(date -d yesterday +%Y-%m-%d)"
NOTIFICATION_EMAIL="ops-team@example.com"

RESULT=$(./retry-failed-step-functions.sh \
  --date "$EXECUTION_DATE" \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine 2>&1)

EXIT_CODE=$?

# Send email notification
{
  echo "Step Functions Retry Execution Report"
  echo "======================================"
  echo "Date: $EXECUTION_DATE"
  echo "Status: $([ $EXIT_CODE -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')"
  echo ""
  echo "Output:"
  echo "$RESULT"
} | mail -s "Step Functions Retry Report - $EXECUTION_DATE" "$NOTIFICATION_EMAIL"

exit $EXIT_CODE
```

### Example 7: Verbose Debugging

Troubleshoot issues with verbose output:

```bash
#!/bin/bash

./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose
```

## Cron Scheduling Examples

### Daily Retry at 2 AM

```cron
0 2 * * * bash -c 'cd /opt/scripts && ./retry-failed-step-functions.sh --date $(date -d yesterday +\%Y-\%m-\%d) --region us-east-1 --account-id 123456789012 --profile default --state-machine MyStateMachine' >> /var/log/step-functions-retry.log 2>&1
```

### Retry Every Hour

```cron
0 * * * * /opt/scripts/retry-failed-step-functions.sh --date $(date +\%Y-\%m-\%d) --region us-east-1 --account-id 123456789012 --profile default --state-machine MyStateMachine >> /var/log/step-functions-retry.log 2>&1
```

### Multiple Regions Daily

```cron
0 2 * * * for region in us-east-1 us-west-2 eu-west-1; do /opt/scripts/retry-failed-step-functions.sh --date $(date -d yesterday +\%Y-\%m-\%d) --region $region --account-id 123456789012 --profile default --state-machine MyStateMachine; done >> /var/log/step-functions-retry.log 2>&1
```

## Docker Usage

### Create a Dockerfile

```dockerfile
FROM amazonlinux:2

RUN yum update -y && \
    yum install -y aws-cli jq bash

COPY retry-failed-step-functions.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/retry-failed-step-functions.sh

ENTRYPOINT ["retry-failed-step-functions.sh"]
```

### Build the Docker image

```bash
docker build -t step-functions-retry:latest .
```

### Run the Docker container

```bash
docker run --rm \
  -e AWS_PROFILE=default \
  -v ~/.aws:/root/.aws:ro \
  step-functions-retry:latest \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

## AWS Lambda Integration

### Lambda Function

```python
import json
import subprocess
import os
from datetime import datetime, timedelta

def lambda_handler(event, context):
    """
    Lambda handler to invoke the Step Functions retry script
    """
    
    # Get execution date (default to yesterday)
    execution_date = event.get('date', (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d'))
    region = event.get('region', 'us-east-1')
    account_id = event.get('account_id', os.environ.get('AWS_ACCOUNT_ID'))
    profile = event.get('profile', 'default')
    state_machine = event.get('state_machine', os.environ.get('STATE_MACHINE_NAME'))
    
    # Prepare command
    cmd = [
        '/opt/step-functions-retry/retry-failed-step-functions.sh',
        '--date', execution_date,
        '--region', region,
        '--account-id', account_id,
        '--profile', profile,
        '--state-machine', state_machine
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return {
            'statusCode': result.returncode,
            'body': json.dumps({
                'message': 'Retry completed',
                'stdout': result.stdout,
                'stderr': result.stderr,
                'date': execution_date
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }
```

### Lambda Environment Variables

```
AWS_ACCOUNT_ID=123456789012
STATE_MACHINE_NAME=MyStateMachine
```

### Invoke Lambda

```bash
aws lambda invoke \
  --function-name step-functions-retry \
  --payload '{"date":"2025-11-13","region":"us-east-1"}' \
  response.json
```

## Monitoring and Alerts

### CloudWatch Integration

Create a custom metric to track retries:

```bash
#!/bin/bash

RESTARTED_COUNT=$(./retry-failed-step-functions.sh ... 2>&1 | grep "Executions restarted:" | awk '{print $3}')

aws cloudwatch put-metric-data \
  --metric-name RestartedExecutions \
  --namespace StepFunctions \
  --value "$RESTARTED_COUNT" \
  --region us-east-1
```

## Best Practices

1. **Test First**: Always test with `--verbose` before scheduling
2. **Use Profiles**: Keep different profiles for dev/prod
3. **Log Output**: Redirect output to log files for audit trails
4. **Schedule Wisely**: Run during maintenance windows
5. **Monitor Results**: Check logs regularly for failures
6. **Validate Input**: Ensure correct date formats before automation
7. **Rate Limiting**: The 5-second delay is reasonable; adjust if needed
8. **Error Handling**: Wrap scripts with error handling for production use

## Troubleshooting Tips

1. Test AWS credentials first:
   ```bash
   aws sts get-caller-identity --profile your-profile
   ```

2. Verify state machine exists:
   ```bash
   aws stepfunctions list-state-machines --region us-east-1 --profile default
   ```

3. Check execution history manually:
   ```bash
   aws stepfunctions list-executions \
     --state-machine-arn arn:aws:states:us-east-1:123456789012:stateMachine:MyStateMachine \
     --status-filter FAILED \
     --region us-east-1 \
     --profile default
   ```

4. View full execution history:
   ```bash
   aws stepfunctions get-execution-history \
     --execution-arn arn:aws:states:... \
     --region us-east-1 \
     --profile default
   ```

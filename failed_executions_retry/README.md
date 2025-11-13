# Step Functions Failed Execution Retry Script

A Bash script that automatically retries failed AWS Step Functions executions that failed at a specific state (`PatchDrupalSection`) with intelligently named executions and built-in delays.

## Features

- **Targeted Retries**: Only restarts executions that failed at the specified state
- **Smart Naming**: Generates new execution names based on the original execution (e.g., `ca9961be-4d81-...` becomes `ca9961be-r`)
- **Rate Limiting**: 5-second delay between each new execution to prevent API throttling
- **Input Preservation**: Carries over the original execution input to retry executions
- **Robust Error Handling**: Comprehensive validation and error checking
- **Verbose Logging**: Optional debug output for troubleshooting
- **Color-coded Output**: Easy-to-read status messages

## Prerequisites

### Required Tools

1. **AWS CLI v2** - Install from [AWS CLI documentation](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. **jq** - JSON query tool
   - macOS: `brew install jq`
   - Ubuntu/Debian: `apt-get install jq`
   - Amazon Linux: `yum install jq`

### AWS Permissions

Your AWS profile needs the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "states:ListExecutions",
        "states:DescribeExecution",
        "states:GetExecutionHistory",
        "states:StartExecution"
      ],
      "Resource": "arn:aws:states:*:ACCOUNT_ID:stateMachine:*"
    }
  ]
}
```

## Installation

1. Download the script:
```bash
wget https://example.com/retry-failed-step-functions.sh
# or
curl -O https://example.com/retry-failed-step-functions.sh
```

2. Make it executable:
```bash
chmod +x retry-failed-step-functions.sh
```

3. Place it in your PATH or a convenient location

## Usage

### Basic Usage

```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--date` | Yes | Execution date in YYYY-MM-DD format | `2025-11-13` |
| `--region` | Yes | AWS region | `us-east-1`, `us-west-2` |
| `--account-id` | Yes | AWS account ID (12 digits) | `123456789012` |
| `--profile` | Yes | AWS CLI profile name | `default`, `production` |
| `--state-machine` | Yes | Step Functions state machine name | `MyStateMachine` |
| `--verbose` | No | Enable verbose debug output | (no value) |
| `--help` | No | Display help message | (no value) |

### Examples

**Retry failed executions from yesterday:**
```bash
./retry-failed-step-functions.sh \
  --date $(date -d yesterday +%Y-%m-%d) \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

**With verbose output for debugging:**
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose
```

**Using a named profile:**
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-west-2 \
  --account-id 987654321098 \
  --profile production \
  --state-machine ProductionStateMachine
```

## Behavior

### Execution Name Transformation

The script extracts the first part of the failed execution name (before the first underscore) and appends `-r` to create a new execution name:

| Original Execution Name | New Execution Name |
|------------------------|-------------------|
| `ca9961be-4d81-5245-48af-b0c716acab71_af5c8774-0990-cd4a-48ea-fda97628bd41` | `ca9961be-r` |
| `exec-001_abc123def456` | `exec-001-r` |
| `simple-execution-name` | `simple-execution-r` |

### Execution Flow

1. Validates all required parameters
2. Checks for AWS CLI and jq availability
3. Tests AWS credentials
4. Lists all failed executions for the specified date
5. For each failed execution:
   - Checks if it failed at the `PatchDrupalSection` state
   - If yes: Generates a new name and starts a new execution with the same input
   - Waits 5 seconds before starting the next execution
6. Displays summary statistics

### Rate Limiting

The script includes a 5-second delay between starting each execution to prevent AWS API throttling and to ensure stable operation. This is configurable by modifying the `WAIT_BETWEEN_EXECUTIONS` variable in the script.

## Output

### Successful Run

```
[INFO] Step Functions Execution Retry Script
[INFO] ======================================
[INFO] Date: 2025-11-13
[INFO] Region: us-east-1
[INFO] Account ID: 123456789012
[INFO] Profile: default
[INFO] State Machine: MyStateMachine
[INFO] Target State: PatchDrupalSection

[SUCCESS] AWS credentials validated
[INFO] Fetching failed executions for 2025-11-13
[INFO] Checking execution (1): ca9961be-4d81-5245-48af-b0c716acab71_af5c8774-0990-cd4a-48ea-fda97628bd41
[INFO]   -> Failed at PatchDrupalSection state
[INFO]   -> Will restart as: ca9961be-r
[SUCCESS] New execution started: arn:aws:states:us-east-1:123456789012:execution:MyStateMachine:ca9961be-r
[INFO]   -> Waiting 5 seconds before next execution...

[INFO] ====== Summary ======
[INFO] Total failed executions found: 1
[INFO] Executions restarted: 1
[INFO] 
[SUCCESS] Retry process completed with 1 execution(s) restarted
```

### Error Handling

The script includes comprehensive error handling for common issues:

- **Missing dependencies**: Alerts if AWS CLI or jq is not installed
- **Invalid parameters**: Validates date format, AWS account ID, and region
- **Authentication failure**: Tests credentials before attempting operations
- **API errors**: Catches and reports AWS API failures
- **Invalid dates**: Prevents execution with malformed dates

## Troubleshooting

### "AWS CLI is not installed or not in PATH"

Install AWS CLI v2:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### "jq is not installed or not in PATH"

Install jq:
- macOS: `brew install jq`
- Ubuntu: `sudo apt-get install jq`
- CentOS/RHEL: `sudo yum install jq`

### "Failed to authenticate with AWS CLI"

1. Verify your AWS profile is configured correctly:
   ```bash
   aws configure --profile your-profile
   ```

2. Test credentials:
   ```bash
   aws sts get-caller-identity --profile your-profile
   ```

3. Check IAM permissions match those specified in the Prerequisites section

### "No failed executions found"

This could mean:
- No executions failed on the specified date
- The date format is incorrect (should be YYYY-MM-DD)
- The executions failed but not at the `PatchDrupalSection` state

Use `--verbose` flag to see more details.

### "Failed to start execution: execution_name"

This typically indicates:
- An execution with that name already exists
- The AWS account doesn't have permissions to start executions
- The state machine ARN is incorrect

## Advanced Configuration

### Modify Target State

To retry executions that failed at a different state, edit the script and change:

```bash
readonly FAILED_STATE="PatchDrupalSection"
```

to your desired state name.

### Adjust Wait Time

To change the delay between executions, modify:

```bash
readonly WAIT_BETWEEN_EXECUTIONS=5  # seconds
```

## Scheduling with Cron

Run the script daily at 2 AM to retry yesterday's failed executions:

```bash
0 2 * * * /path/to/retry-failed-step-functions.sh --date $(date -d yesterday +\%Y-\%m-\%d) --region us-east-1 --account-id 123456789012 --profile default --state-machine MyStateMachine >> /var/log/step-functions-retry.log 2>&1
```

## Scheduling with Lambda

Convert the script for use in AWS Lambda by:

1. Installing required tools (AWS CLI, jq) in the Lambda layer
2. Setting environment variables for the parameters
3. Calling the script from a Lambda handler

## License

This script is provided as-is for use with AWS services.

## Support

For issues or suggestions:

1. Enable verbose output: `--verbose`
2. Check AWS CloudTrail for API errors
3. Verify IAM permissions
4. Check AWS CLI configuration: `aws configure list --profile your-profile`

## Related Documentation

- [AWS Step Functions Documentation](https://docs.aws.amazon.com/step-functions/)
- [AWS CLI Reference - Step Functions](https://docs.aws.amazon.com/cli/latest/reference/stepfunctions/index.html)
- [AWS IAM Documentation](https://docs.aws.amazon.com/iam/)
- [jq Documentation](https://stedolan.github.io/jq/)

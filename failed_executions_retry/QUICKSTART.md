# Quick Start Guide

Get the script running in 5 minutes!

## Step 1: Install Prerequisites

### macOS
```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install AWS CLI and jq
brew install awscli jq
```

### Ubuntu/Debian
```bash
# Update package manager
sudo apt-get update

# Install AWS CLI and jq
sudo apt-get install -y awscli jq
```

### Amazon Linux / CentOS / RHEL
```bash
# Install AWS CLI and jq
sudo yum install -y aws-cli jq
```

### Verify Installation
```bash
aws --version
jq --version
```

## Step 2: Configure AWS Credentials

If you haven't already configured AWS CLI:

```bash
aws configure --profile default
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

Verify it works:
```bash
aws sts get-caller-identity --profile default
```

## Step 3: Download the Script

```bash
# Download to current directory
wget https://your-repo-url/retry-failed-step-functions.sh

# Make it executable
chmod +x retry-failed-step-functions.sh
```

## Step 4: Run Your First Retry

Replace these values with your actual details:

```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

## Step 5: Check the Results

Look for output like:

```
[SUCCESS] AWS credentials validated
[INFO] Fetching failed executions for 2025-11-13
[INFO] Checking execution (1): abc123...
[INFO]   -> Failed at PatchDrupalSection state
[INFO]   -> Will restart as: abc123-r
[SUCCESS] New execution started: arn:aws:states:...

[INFO] ====== Summary ======
[INFO] Total failed executions found: 1
[INFO] Executions restarted: 1
[SUCCESS] Retry process completed with 1 execution(s) restarted
```

## Common Parameters

| What | Parameter | Example |
|------|-----------|---------|
| **Date** | `--date` | `2025-11-13` (yesterday) |
| **AWS Region** | `--region` | `us-east-1` |
| **Account ID** | `--account-id` | `123456789012` |
| **AWS Profile** | `--profile` | `default` or `production` |
| **State Machine** | `--state-machine` | `MyStateMachine` |

## One-Liners

### Retry Yesterday's Failed Executions
```bash
./retry-failed-step-functions.sh \
  --date $(date -d yesterday +%Y-%m-%d) \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Debug with Verbose Output
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose
```

### Get Help
```bash
./retry-failed-step-functions.sh --help
```

## Troubleshooting the First Run

### "AWS CLI is not installed"
```bash
# Verify AWS CLI is installed
aws --version

# If not installed, see Step 1 above
```

### "Failed to authenticate with AWS CLI"
```bash
# Verify your AWS credentials are configured
aws sts get-caller-identity --profile default

# If this fails, run:
aws configure --profile default
```

### "jq is not installed"
```bash
# Verify jq is installed
jq --version

# If not installed, see Step 1 above
```

### "No failed executions found"
This is normal if there were no failed executions on that date. Try:
```bash
# Run with verbose output to see what's happening
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose
```

### "Permission denied" error
```bash
# Make sure the script is executable
chmod +x retry-failed-step-functions.sh

# Try again
./retry-failed-step-functions.sh ...
```

## Next Steps

1. **Schedule It**: Set up a cron job to run daily (see EXAMPLES.md)
2. **Monitor It**: Check logs regularly
3. **Customize It**: Adjust for different state machines or regions
4. **Automate It**: Integrate with your CI/CD pipeline

## Need Help?

### View Documentation
```bash
# See the full README
cat README.md

# See usage examples
cat EXAMPLES.md

# See script help
./retry-failed-step-functions.sh --help
```

### Debug an Issue
```bash
# Run with verbose output
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose > debug.log 2>&1

# Review the log
cat debug.log
```

### Manually Check Executions

Check for failed executions manually using AWS CLI:
```bash
# List all failed executions
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:us-east-1:123456789012:stateMachine:MyStateMachine \
  --status-filter FAILED \
  --region us-east-1 \
  --profile default \
  --output json | jq '.executions[] | {name, status, stopDate}'
```

## Tips for Production Use

1. **Test First**: Always test with a non-production state machine first
2. **Check Permissions**: Ensure your AWS profile has the required permissions
3. **Monitor Logs**: Keep logs to audit what was retried
4. **Use Meaningful Dates**: Double-check your date parameters
5. **Start Small**: Test with one state machine before expanding
6. **Review Results**: Check the CloudWatch logs to confirm executions ran correctly

## Uninstalling

```bash
# Remove the script
rm retry-failed-step-functions.sh

# To remove AWS CLI and jq (optional)
# macOS
brew uninstall awscli jq

# Ubuntu/Debian
sudo apt-get remove -y awscli jq

# Amazon Linux / CentOS / RHEL
sudo yum remove -y aws-cli jq
```

## That's It!

You're now ready to use the Step Functions retry script. Start with the one-liners above and expand from there!

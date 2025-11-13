# AWS Step Functions Retry Script - Complete Package

Welcome! This package contains everything you need to automatically retry failed AWS Step Functions executions.

## 📦 What's Included

```
├── retry-failed-step-functions.sh      ← Main script (the workhorse)
├── retry-step-functions-wrapper.sh     ← Interactive wrapper (easy mode)
├── README.md                           ← Full documentation
├── QUICKSTART.md                       ← Start here! (5 min setup)
├── EXAMPLES.md                         ← Real-world usage examples
├── PERMISSIONS.md                      ← File permissions guide
└── INDEX.md                            ← This file
```

## 🚀 Get Started in 3 Steps

### Step 1: Setup (2 minutes)
```bash
# Make scripts executable
chmod +x *.sh

# Verify AWS CLI and jq are installed
aws --version && jq --version

# Configure AWS (if needed)
aws configure --profile default
```

### Step 2: Run (1 minute)
```bash
# Option A: Interactive mode (prompts for all settings)
./retry-step-functions-wrapper.sh

# Option B: Direct command
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Step 3: Schedule (if desired)
Add to your crontab for daily automatic retries:
```bash
crontab -e
```

Add this line:
```
0 2 * * * /path/to/retry-failed-step-functions.sh \
  --date $(date -d yesterday +\%Y-\%m-\%d) \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine >> /var/log/step-functions-retry.log 2>&1
```

## 📖 Documentation Guide

**New to the script?**
→ Start with [QUICKSTART.md](QUICKSTART.md)

**Want detailed info?**
→ Read [README.md](README.md)

**Looking for examples?**
→ Check [EXAMPLES.md](EXAMPLES.md)

**File permission issues?**
→ See [PERMISSIONS.md](PERMISSIONS.md)

## 🎯 What This Script Does

1. ✅ Finds failed Step Functions executions for a specific date
2. ✅ Filters for only those that failed at `PatchDrupalSection` state
3. ✅ Creates intelligently named retry executions (e.g., `abc123-r`)
4. ✅ Preserves the original execution input
5. ✅ Waits 5 seconds between retries (prevents API throttling)
6. ✅ Provides detailed logging of all actions

## 💡 Common Commands

### Retry yesterday's failures
```bash
./retry-failed-step-functions.sh \
  --date $(date -d yesterday +%Y-%m-%d) \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Retry a specific date
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-10 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine
```

### Debug with verbose output
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine \
  --verbose
```

### Interactive mode
```bash
./retry-step-functions-wrapper.sh
```

### Get help
```bash
./retry-failed-step-functions.sh --help
```

## 🔧 Prerequisites

### Required
- **AWS CLI v2** - [Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **jq** - JSON query tool (apt/brew/yum)
- **AWS Credentials** - Configured profile with Step Functions permissions

### Optional but Recommended
- **AWS Account** - Your own to test with
- **Bash 4+** - Modern shell (usually pre-installed)

## 📋 Parameter Reference

| Parameter | Required | Example | Description |
|-----------|----------|---------|-------------|
| `--date` | Yes | `2025-11-13` | Execution date (YYYY-MM-DD) |
| `--region` | Yes | `us-east-1` | AWS region |
| `--account-id` | Yes | `123456789012` | 12-digit AWS account ID |
| `--profile` | Yes | `default` | AWS CLI profile name |
| `--state-machine` | Yes | `MyStateMachine` | State machine name |
| `--verbose` | No | (no value) | Enable debug output |
| `--help` | No | (no value) | Show help message |

## 🔐 AWS Permissions Required

Your IAM user/role needs these permissions:

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

## 🐛 Troubleshooting

### AWS CLI not found
```bash
aws --version  # Check if installed
# If not installed, see QUICKSTART.md
```

### jq not found
```bash
jq --version   # Check if installed
# If not installed, see QUICKSTART.md
```

### Authentication failed
```bash
aws sts get-caller-identity --profile default
# Should show your AWS account and user details
```

### Permission denied running script
```bash
chmod +x retry-failed-step-functions.sh
# Then try again
```

### No executions found
This is normal if there were no failures on that date. Use `--verbose` to see details:
```bash
./retry-failed-step-functions.sh ... --verbose
```

## 📚 Learning Resources

- [AWS Step Functions Documentation](https://docs.aws.amazon.com/step-functions/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Bash Scripting Guide](https://www.gnu.org/software/bash/manual/)

## 🤝 Support & Feedback

### Debug an Issue
1. Run with `--verbose` flag
2. Check CloudTrail for API errors
3. Verify AWS CLI credentials: `aws configure list`
4. Review the error message carefully

### Check AWS CLI Setup
```bash
# Verify installation
aws --version

# List configured profiles
aws configure list

# Test credentials
aws sts get-caller-identity --profile YOUR_PROFILE
```

### Manual AWS CLI Check
```bash
# List failed executions
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:REGION:ACCOUNT:stateMachine:NAME \
  --status-filter FAILED \
  --region REGION \
  --profile PROFILE
```

## 📝 Example Workflow

```bash
# 1. First time setup
chmod +x retry-failed-step-functions.sh
aws configure --profile default

# 2. Test with help
./retry-failed-step-functions.sh --help

# 3. Try interactive mode
./retry-step-functions-wrapper.sh

# 4. Or use direct command
./retry-failed-step-functions.sh \
  --date $(date -d yesterday +%Y-%m-%d) \
  --region us-east-1 \
  --account-id 123456789012 \
  --profile default \
  --state-machine MyStateMachine

# 5. Review the output and logs
# 6. Schedule in cron if successful
```

## 🎓 Next Steps

1. **Read QUICKSTART.md** - Get running immediately
2. **Explore EXAMPLES.md** - See advanced usage
3. **Check README.md** - Understand all features
4. **Schedule it** - Automate daily retries
5. **Monitor it** - Set up logging and alerts

## ✨ Features at a Glance

- ✅ **Smart Naming** - Auto-generates meaningful names (`abc123-r`)
- ✅ **State Filtering** - Only retries `PatchDrupalSection` failures
- ✅ **Input Preservation** - Reuses original execution input
- ✅ **Rate Limiting** - 5-second delay prevents API throttling
- ✅ **Error Handling** - Comprehensive validation and recovery
- ✅ **Verbose Logging** - Optional debug output
- ✅ **Color Output** - Easy-to-read status messages
- ✅ **Flexible Execution** - CLI or interactive mode
- ✅ **Schedulable** - Works with cron, Lambda, etc.

## 🚨 Important Notes

1. **Always test first** - Try with a non-prod state machine
2. **Check permissions** - Ensure IAM role has required access
3. **Verify parameters** - Double-check dates and region
4. **Review results** - Check CloudWatch logs after execution
5. **Keep logs** - Audit trail of all retries

## 📞 Quick Help

| Issue | Solution |
|-------|----------|
| "Command not found" | Run `chmod +x retry-failed-step-functions.sh` |
| "Permission denied" | Run `chmod +x *.sh` |
| "AWS CLI not found" | Install: See QUICKSTART.md |
| "jq not found" | Install: See QUICKSTART.md |
| "No auth" | Run `aws configure --profile default` |
| "No executions found" | Date might be wrong; try `--verbose` |

## 🎯 Ready to Go?

1. ✅ Run `chmod +x *.sh`
2. ✅ Read [QUICKSTART.md](QUICKSTART.md)
3. ✅ Execute the script
4. ✅ Check the output
5. ✅ Schedule for automation (optional)

**Happy retrying!** 🚀

---

Questions? Errors? Refer to [README.md](README.md) for complete documentation.

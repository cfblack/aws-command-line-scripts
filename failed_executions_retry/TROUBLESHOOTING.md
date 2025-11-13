# Troubleshooting Guide - AWS CLI and JSON Issues

## Quick Diagnostic

Before troubleshooting, run the diagnostic script to identify the issue:

```bash
chmod +x diagnose-setup.sh

./diagnose-setup.sh \
  cpe_admin-cpe \
  us-east-1 \
  469225647823 \
  individualSectionSM
```

This will check:
- ✓ AWS CLI is installed
- ✓ jq is installed  
- ✓ AWS profile is configured
- ✓ AWS credentials are valid
- ✓ Can list state machines
- ✓ Can list failed executions

---

## Error: "jq: parse error: Invalid numeric literal"

This error occurs when the script receives invalid JSON from the AWS CLI.

### Common Causes

1. **AWS Credentials Not Working**
   - The AWS CLI returns an error message instead of JSON
   - The profile doesn't have permissions to access Step Functions

2. **Invalid State Machine ARN**
   - The state machine doesn't exist in that region
   - The account ID is incorrect
   - The region is incorrect

3. **AWS CLI Version Issues**
   - Using an old version of AWS CLI
   - AWS CLI not properly configured

### Solutions

#### Step 1: Test AWS Credentials

```bash
aws sts get-caller-identity --profile cpe_admin-cpe --region us-east-1
```

Expected output:
```json
{
    "UserId": "AIDAI...",
    "Account": "469225647823",
    "Arn": "arn:aws:iam::469225647823:user/username"
}
```

If this fails, your credentials are not working.

#### Step 2: Verify State Machine Exists

```bash
aws stepfunctions list-state-machines \
  --profile cpe_admin-cpe \
  --region us-east-1
```

Look for `individualSectionSM` in the results.

#### Step 3: Test List Executions Directly

```bash
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM \
  --status-filter FAILED \
  --profile cpe_admin-cpe \
  --region us-east-1 \
  --output json
```

This should return valid JSON like:
```json
{
    "executions": [
        {
            "executionArn": "arn:aws:states:...",
            "name": "execution-name",
            "status": "FAILED",
            "stopDate": "2025-11-13T10:30:00.000Z"
        }
    ]
}
```

If you see an error message instead, check:
- Is the state machine ARN correct?
- Do you have `stepfunctions:ListExecutions` permission?

#### Step 4: Check IAM Permissions

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
      "Resource": "arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM"
    }
  ]
}
```

Ask your AWS administrator to verify these permissions are attached to your user/role.

#### Step 5: Debug the Script

Run the script with `--verbose` to see exactly what's happening:

```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 469225647823 \
  --profile cpe_admin-cpe \
  --state-machine individualSectionSM \
  --verbose
```

Look for lines that say:
- `[DEBUG] Raw AWS response received` - This shows what the AWS CLI is returning
- `[DEBUG] State Machine ARN: arn:aws:states:...` - Verify this is correct

#### Step 6: Upgrade AWS CLI

Make sure you're running AWS CLI v2:

```bash
aws --version
```

Should show: `aws-cli/2.x.x`

If you're on v1, upgrade:

```bash
# macOS
brew upgrade awscli

# Ubuntu/Debian
pip3 install --upgrade awscli

# Or download from
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
```

### Verification Checklist

- [ ] `aws sts get-caller-identity` works
- [ ] `aws stepfunctions list-state-machines` shows your state machine
- [ ] `aws stepfunctions list-executions` returns valid JSON
- [ ] You have the required IAM permissions
- [ ] AWS CLI is version 2.x or higher
- [ ] Profile name is correct: `cpe_admin-cpe`
- [ ] Region is correct: `us-east-1`
- [ ] Account ID is correct: `469225647823`
- [ ] State machine name is correct: `individualSectionSM`

### Common Fix Checklist

**If you see "No failed executions found":**
- This might be normal if there were no failures on that date
- Try a different date when you know there were failures
- Use the AWS console to verify

**If you see a jq parse error:**
1. Run with `--verbose` to see the raw response
2. Test each AWS CLI command individually (see Step 3-5 above)
3. Check your credentials and permissions

**If you see "Failed to authenticate":**
1. Verify profile exists: `aws configure list --profile cpe_admin-cpe`
2. Re-configure if needed: `aws configure --profile cpe_admin-cpe`
3. Check credentials file: `cat ~/.aws/credentials`

### Manual AWS CLI Commands

Test each of these commands individually:

```bash
# 1. Test credentials
aws sts get-caller-identity \
  --profile cpe_admin-cpe \
  --region us-east-1

# 2. List state machines
aws stepfunctions list-state-machines \
  --profile cpe_admin-cpe \
  --region us-east-1

# 3. List failed executions
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM \
  --status-filter FAILED \
  --profile cpe_admin-cpe \
  --region us-east-1

# 4. Describe a specific execution (replace with real ARN)
aws stepfunctions describe-execution \
  --execution-arn arn:aws:states:us-east-1:469225647823:execution:individualSectionSM:abc123 \
  --profile cpe_admin-cpe \
  --region us-east-1

# 5. Get execution history (replace with real ARN)
aws stepfunctions get-execution-history \
  --execution-arn arn:aws:states:us-east-1:469225647823:execution:individualSectionSM:abc123 \
  --profile cpe_admin-cpe \
  --region us-east-1
```

### If All Else Fails

1. Save the raw AWS response:
   ```bash
   aws stepfunctions list-executions \
     --state-machine-arn arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM \
     --status-filter FAILED \
     --profile cpe_admin-cpe \
     --region us-east-1 \
     --output json > response.json
   
   cat response.json
   ```

2. Validate it's valid JSON:
   ```bash
   jq . response.json
   ```

3. Share the response with your AWS administrator for review

## Success Indicators

When everything is working, you should see:

```
[INFO] Testing AWS credentials with profile: cpe_admin-cpe
[SUCCESS] AWS credentials validated
[INFO] Fetching failed executions for 2025-11-13
[DEBUG] Raw AWS response received (first 100 chars): {"executions":[{"executionArn":"arn:aws...
[INFO] Checking execution (1): execution-name-123
[INFO]   -> Failed at PatchDrupalSection state
[SUCCESS] New execution started: arn:aws:states:...
```

---

## Need More Help?

1. Check the main [README.md](README.md)
2. Review [EXAMPLES.md](EXAMPLES.md) for usage patterns
3. Enable verbose mode for detailed debugging
4. Test each AWS CLI command individually

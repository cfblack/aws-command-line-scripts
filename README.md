# AWS CLI Scripts

A collection of useful command-line scripts for working with AWS services.

## Prerequisites

- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- [jq](https://stedolan.github.io/jq/) - Command-line JSON processor
- Bash shell (macOS/Linux)

### Installing jq on macOS

```bash
brew install jq
```

## Scripts

### search_executions.sh

Search AWS Step Functions executions by date and object ID.

**Usage:**

```bash
./search_executions.sh <date> <object_id> <region> <account_id> <profile>
```

**Parameters:**

- `date` - Execution date in YYYY-MM-DD format
- `object_id` - Object ID to search for in execution inputs
- `region` - AWS region (e.g., us-east-1, us-west-2)
- `account_id` - AWS account ID
- `profile` - AWS CLI profile name

**Example:**

```bash
./search_executions.sh 2025-10-27 65232714 us-east-1 469225647823 my-profile
```

**Output:**

For each matching execution, the script displays:
- Execution ARN
- Execution status (RUNNING, SUCCEEDED, FAILED, etc.)
- AWS Console URL for viewing the execution
- Full execution input JSON

**Setup:**

1. Make the script executable:
   ```bash
   chmod +x search_executions.sh
   ```

2. Ensure you have the appropriate AWS permissions for:
   - `stepfunctions:ListExecutions`
   - `stepfunctions:DescribeExecution`

## AWS Profile Configuration

To see your available AWS profiles:

```bash
aws configure list-profiles
```

To configure a new profile:

```bash
aws configure --profile profile-name
```

## License

MIT
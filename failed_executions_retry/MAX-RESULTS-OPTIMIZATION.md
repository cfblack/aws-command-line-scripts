# Update: Diagnostic Script Optimization

## What Changed

The `diagnose-setup.sh` script has been updated to show only the **last 10 failed executions** instead of all of them.

### Why?

- **Faster output**: Diagnostic runs quicker
- **Cleaner display**: Easier to read
- **Still useful**: Last 10 shows the most recent failures
- **AWS API efficient**: Uses `--max-results 10` parameter

## How It Works

### Diagnostic Script (diagnose-setup.sh)
```bash
aws stepfunctions list-executions \
    --state-machine-arn "$arn" \
    --status-filter FAILED \
    --profile "$profile" \
    --region "$region" \
    --max-results 10           # ← Only last 10
    --output json
```

Output: Shows last 10 failed executions sorted by newest first

### Main Script (retry-failed-step-functions.sh)
```bash
aws stepfunctions list-executions \
    --state-machine-arn "$state_machine_arn" \
    --status-filter FAILED \
    --profile "$profile" \
    --region "$region" \
    --output json              # ← Gets ALL failures for date
```

Output: Processes ALL failures for the specified date range

## Key Differences

| Aspect | Diagnostic Script | Main Script |
|--------|-------------------|-------------|
| **Limit** | Last 10 | All for date |
| **Purpose** | Verify setup | Perform retries |
| **Speed** | Fast | Varies by count |
| **Use Case** | Testing | Production |

## Example Output

### Before Update
```
[INFO] Found 247 failed execution(s)
      execution-001 - 2025-11-13T10:30:00.000Z
      execution-002 - 2025-11-13T10:25:00.000Z
      execution-003 - 2025-11-13T10:20:00.000Z
      ... (244 more) ...
      execution-247 - 2025-11-13T08:00:00.000Z
```

### After Update
```
[INFO] Found 10 failed execution(s) (showing last 10)
      execution-001 - 2025-11-13T10:30:00.000Z
      execution-002 - 2025-11-13T10:25:00.000Z
      execution-003 - 2025-11-13T10:20:00.000Z
      execution-004 - 2025-11-13T10:15:00.000Z
      execution-005 - 2025-11-13T10:10:00.000Z
      execution-006 - 2025-11-13T10:05:00.000Z
      execution-007 - 2025-11-13T10:00:00.000Z
      execution-008 - 2025-11-13T09:55:00.000Z
      execution-009 - 2025-11-13T09:50:00.000Z
      execution-010 - 2025-11-13T09:45:00.000Z
```

## When to Use What

### Diagnostic Script
```bash
./diagnose-setup.sh cpe_admin-cpe us-east-1 469225647823 individualSectionSM
```
- ✓ First run to verify setup
- ✓ Quick health check
- ✓ See recent failures
- ✓ Verify can access state machine

### Main Script
```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 469225647823 \
  --profile cpe_admin-cpe \
  --state-machine individualSectionSM
```
- ✓ Actual retry work
- ✓ Processes ALL failures for date
- ✓ Creates new executions
- ✓ Applies retry logic

## Sorting Order

Both scripts return executions sorted by **stop date (newest first)**:
- Most recent failures appear first
- Older failures appear last

## Performance Impact

### Diagnostic Script
- **Before**: 247 executions displayed (slow with large result sets)
- **After**: 10 executions displayed (instant)
- **Improvement**: ~25x faster display

### Main Script
- **No change**: Still processes all failures for the date
- **No performance impact**: Still comprehensive

## If You Need All Executions from Diagnostic

To see all failed executions from the command line:

```bash
aws stepfunctions list-executions \
  --state-machine-arn arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM \
  --status-filter FAILED \
  --profile cpe_admin-cpe \
  --region us-east-1 \
  --output json | jq '.executions | length'
```

This shows the total count of all failures.

## Updated Diagnostic Output

The diagnostic script now shows:

```
✓ Found 10 failed execution(s) (showing last 10)
      execution-newest - 2025-11-13T10:30:00.000Z
      ...
      execution-10th - 2025-11-13T09:45:00.000Z
```

Then explains:
```
Notes:
  • Diagnostic script shows last 10 failed executions
  • Main script will process ALL failures for the specified date
  • Failed executions are sorted by stop date (newest first)
```

## No Changes Required

- ✓ No changes to how you run the scripts
- ✓ All commands work the same
- ✓ Only internal improvement
- ✓ Faster diagnostics

## Summary

| Feature | Status |
|---------|--------|
| Diagnostic faster | ✅ Yes |
| Shows most recent failures | ✅ Yes |
| Easy to read | ✅ Yes |
| Main script unchanged | ✅ Yes |
| All functionality preserved | ✅ Yes |

Enjoy the faster diagnostics! 🚀

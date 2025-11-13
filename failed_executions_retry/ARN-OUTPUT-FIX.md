# Fix: ARN Output Contamination

## The Problem

The error message showed:
```
[ERROR] AWS Error Output:
[ERROR]   An error occurred (InvalidArn) when calling the ListExecutions operation: Invalid Arn: 'Invalid ARN prefix: [DEBUG] State machine ARN: arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM
[ERROR]   arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM'
```

Notice how `[DEBUG] State machine ARN:` got included in the ARN itself! This caused AWS to receive a malformed ARN.

## Root Cause

**The issue was in command substitution mixing:**

```bash
state_machine_arn=$(get_state_machine_arn "$STATE_MACHINE" "$ACCOUNT_ID" "$REGION")
```

When using `$()`, **both stdout and stderr** get captured if not separated. Inside the function:
```bash
print_verbose "State machine ARN: $arn"  # Goes to stderr
echo "$arn"                              # Goes to stdout
```

Both got mixed together and passed to AWS CLI!

## The Solution

**Removed the debug statement from the function:**
```bash
get_state_machine_arn() {
    local state_machine="$1"
    local account_id="$2"
    local region="$3"

    local arn="arn:aws:states:${region}:${account_id}:stateMachine:${state_machine}"
    
    # Only echo the ARN - no verbose messages
    echo "$arn"
}
```

**Added debug output to the main function instead:**
```bash
state_machine_arn=$(get_state_machine_arn "$STATE_MACHINE" "$ACCOUNT_ID" "$REGION")

print_verbose "Resolved state machine ARN: $state_machine_arn"  # Safe here!
```

## Why This Works

✅ **Clean output**: Function only outputs what's needed (the ARN)  
✅ **No mixing**: Debug messages printed separately, after command substitution  
✅ **Proper ARN**: AWS receives the clean, valid ARN  
✅ **Debuggable**: Verbose output still shows the ARN (just in the right place)  

## Result

Now the ARN is passed correctly to AWS, and you'll see:
```
[DEBUG] Resolved state machine ARN: arn:aws:states:us-east-1:469225647823:stateMachine:individualSectionSM
[INFO] Fetching failed executions for 2025-11-13
```

Instead of:
```
[ERROR] Invalid ARN: 'Invalid ARN prefix: [DEBUG] State machine ARN: ...
```

## Testing

✅ Verified with your parameters:
- Account ID: `469225647823`
- Region: `us-east-1`  
- State Machine: `individualSectionSM`

The ARN is now correctly constructed and passed to AWS!

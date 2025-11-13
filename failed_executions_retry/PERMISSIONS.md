# Before Running the Scripts

## File Permissions

When you download these scripts, you need to make them executable. Run this command:

```bash
chmod +x retry-failed-step-functions.sh retry-step-functions-wrapper.sh
```

Then verify:

```bash
ls -l *.sh
```

You should see an `x` in the permissions (e.g., `-rwxr-xr-x`).

## Quick Setup

1. **Make scripts executable:**
   ```bash
   chmod +x retry-failed-step-functions.sh retry-step-functions-wrapper.sh
   ```

2. **Verify AWS CLI and jq are installed:**
   ```bash
   aws --version
   jq --version
   ```

3. **Configure AWS credentials (if not already done):**
   ```bash
   aws configure --profile default
   ```

4. **Test your setup:**
   ```bash
   aws sts get-caller-identity --profile default
   ```

5. **Run the script:**

   **Option A: Interactive mode**
   ```bash
   ./retry-step-functions-wrapper.sh
   ```

   **Option B: Direct command**
   ```bash
   ./retry-failed-step-functions.sh \
     --date 2025-11-13 \
     --region us-east-1 \
     --account-id 123456789012 \
     --profile default \
     --state-machine MyStateMachine
   ```

## Files Included

- **retry-failed-step-functions.sh** - Main script that does the retry work
- **retry-step-functions-wrapper.sh** - Interactive wrapper for easier usage
- **README.md** - Complete documentation
- **QUICKSTART.md** - Get started in 5 minutes
- **EXAMPLES.md** - Usage examples and advanced configurations
- **PERMISSIONS.md** - This file

## Troubleshooting

### "Permission denied" when running script

```bash
# Make it executable
chmod +x retry-failed-step-functions.sh

# Try again
./retry-failed-step-functions.sh --help
```

### "No such file or directory"

Make sure you're in the correct directory:

```bash
# List files
ls -la

# Change to script directory if needed
cd /path/to/scripts

# Then run
./retry-failed-step-functions.sh ...
```

### "AWS CLI is not installed"

See the QUICKSTART.md file for installation instructions.

## That's It!

Your scripts are ready to use. See QUICKSTART.md to get started!

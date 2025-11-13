# Version 1.1 - Updates and Fixes

## 🔧 Recent Fixes

### Fix 1: macOS Date Validation ✅
- **Problem**: Script failed on macOS with "Invalid date" error
- **Cause**: macOS uses BSD `date` command, not GNU `date`
- **Solution**: Added OS detection and appropriate date commands
- **Files Updated**: `retry-failed-step-functions.sh`

### Fix 2: JSON Parsing Error Handling ✅
- **Problem**: "jq: parse error: Invalid numeric literal" when AWS CLI fails
- **Cause**: Script wasn't validating JSON before parsing
- **Solution**: Added JSON validation and better error messages
- **Files Updated**: `retry-failed-step-functions.sh`

### Fix 3: Better Error Messages ✅
- **Problem**: Cryptic errors made troubleshooting difficult
- **Cause**: Limited logging and error context
- **Solution**: Added verbose debug output and clear error descriptions
- **Files Updated**: `retry-failed-step-functions.sh`

## 📦 Complete File List

### Executable Scripts
1. **retry-failed-step-functions.sh** (15 KB)
   - Main script - does the actual retry work
   - Cross-platform compatible (macOS/Linux)
   - Full error handling and logging

2. **retry-step-functions-wrapper.sh** (6 KB)
   - Interactive wrapper for easier usage
   - Optional - use if you prefer prompts

3. **diagnose-setup.sh** (7 KB)
   - NEW: Diagnostic tool to verify setup
   - Checks AWS CLI, jq, credentials, permissions
   - Recommended: Run this first!

### Documentation

4. **00-START-HERE.txt** - Quick reference guide
5. **INDEX.md** - Navigation guide
6. **QUICKSTART.md** - 5-minute setup
7. **README.md** - Complete documentation
8. **EXAMPLES.md** - Usage examples
9. **TROUBLESHOOTING.md** - Issue resolution guide
10. **CHANGELOG.md** - Version history
11. **PERMISSIONS.md** - File permissions help

## 🚀 Quick Start (Updated)

```bash
# 1. Make all scripts executable
chmod +x *.sh

# 2. Run diagnostics FIRST (NEW!)
./diagnose-setup.sh cpe_admin-cpe us-east-1 469225647823 individualSectionSM

# 3. If diagnostics pass, run the retry script
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 469225647823 \
  --profile cpe_admin-cpe \
  --state-machine individualSectionSM
```

## 🔍 How to Use the Diagnostic Script

The diagnostic script checks everything:

```bash
./diagnose-setup.sh PROFILE REGION ACCOUNT_ID STATE_MACHINE
```

Example:
```bash
./diagnose-setup.sh cpe_admin-cpe us-east-1 469225647823 individualSectionSM
```

Output will show:
- ✓/✗ AWS CLI installed
- ✓/✗ jq installed
- ✓/✗ AWS profile configured
- ✓/✗ AWS credentials valid
- ✓/✗ Can access Step Functions
- ✓/✗ Can list your state machine
- ✓/✗ Can list failed executions

## 🛠️ Troubleshooting Workflow

If you get an error:

1. **First**: Run the diagnostic script
   ```bash
   ./diagnose-setup.sh cpe_admin-cpe us-east-1 469225647823 individualSectionSM
   ```

2. **Check output**: Look for ✗ marks to find the problem

3. **Refer to TROUBLESHOOTING.md** for solutions

4. **If still stuck**: Run with verbose flag
   ```bash
   ./retry-failed-step-functions.sh ... --verbose
   ```

## 📊 Common Error Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "jq: parse error" | AWS CLI returning error | Run diagnostic script |
| "AWS CLI not found" | AWS CLI not installed | Install AWS CLI v2 |
| "Failed to authenticate" | Invalid credentials | Check `aws configure` |
| "No failed executions" | No failures on that date | Try a different date |
| "Invalid date" | Wrong date format | Use YYYY-MM-DD |

## ✅ Validation Checklist

Before running the script, verify:

- [ ] AWS CLI v2 is installed (`aws --version`)
- [ ] jq is installed (`jq --version`)
- [ ] AWS profile is configured (`aws configure list --profile cpe_admin-cpe`)
- [ ] Credentials are valid (`aws sts get-caller-identity --profile cpe_admin-cpe`)
- [ ] State machine exists (`aws stepfunctions list-state-machines --profile cpe_admin-cpe`)
- [ ] You have proper IAM permissions (see README.md)

## 🎯 Recommended Reading Order

For first-time users:
1. **00-START-HERE.txt** - Overview (2 min)
2. **diagnose-setup.sh** - Run diagnostics (1 min)
3. **TROUBLESHOOTING.md** - If errors (5 min)
4. **QUICKSTART.md** - Setup (5 min)
5. **retry-failed-step-functions.sh** - Run script (1 min)

For advanced users:
1. **README.md** - Full documentation
2. **EXAMPLES.md** - Advanced patterns
3. **retry-failed-step-functions.sh** - Source code review

## 🔄 Update from v1.0

If you're upgrading from v1.0:

1. **Backup old script** (optional):
   ```bash
   cp retry-failed-step-functions.sh retry-failed-step-functions.sh.backup
   ```

2. **Download new version** and replace

3. **No changes to usage** - all commands work the same

4. **New feature**: Run diagnostics first if you have issues

## 📝 What's New in v1.1

- ✅ macOS compatibility fixed
- ✅ Better JSON error handling
- ✅ Verbose debug output improved
- ✅ New diagnostic script added
- ✅ Enhanced troubleshooting guide
- ✅ Better error messages
- ✅ Cross-platform date handling

## 🐛 Known Issues

- None at this time!

Report issues or suggest improvements by running diagnostics and checking verbose output.

## 💡 Pro Tips

1. **Run diagnostics first** - Saves troubleshooting time
2. **Use verbose mode** - `--verbose` flag shows detailed info
3. **Test with small date** - Start with known failure date
4. **Check CloudWatch logs** - Verify execution ran correctly
5. **Schedule with cron** - Automate daily retries (see EXAMPLES.md)

## 📞 Getting Help

1. Run `./diagnose-setup.sh` - identifies the issue
2. Check **TROUBLESHOOTING.md** - solutions for common problems
3. Review **EXAMPLES.md** - see working examples
4. Use `--verbose` flag - see detailed debug output
5. Check **README.md** - comprehensive documentation

## 🎓 Next Steps

1. Make scripts executable: `chmod +x *.sh`
2. Run diagnostics: `./diagnose-setup.sh cpe_admin-cpe us-east-1 469225647823 individualSectionSM`
3. Fix any issues found
4. Run the retry script
5. Verify results in AWS console

---

**Version**: 1.1  
**Date**: November 2025  
**Status**: Stable ✅  
**Platform Support**: macOS, Linux (Ubuntu, CentOS, Amazon Linux)  
**Dependencies**: AWS CLI v2, jq, Bash 4+

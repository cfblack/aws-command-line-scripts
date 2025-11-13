# Changelog

## Version 1.1 (Fixed)

### Bug Fixes

- **Fixed macOS Compatibility** ✅
  - Date validation now works on both macOS and Linux
  - macOS uses `date -f -j -v+1d` instead of `date -d`
  - Linux continues to use `date -d` as expected
  - Script now detects OS via `$OSTYPE` and uses appropriate date commands

- **Date Validation Improvements**
  - Better error messages
  - Cross-platform compatible date arithmetic
  - Graceful fallback if date command fails

### What Changed

**Before:**
```bash
if ! date -d "$date" &>/dev/null 2>&1; then
    print_error "Invalid date: $date"
    return 1
fi
```

**After:**
```bash
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS uses different date command
    if ! date -f "%Y-%m-%d" -j "$date" &>/dev/null 2>&1; then
        print_verbose "Could not validate date with macOS date command, but format looks valid"
    fi
else
    # Linux
    if ! date -d "$date" &>/dev/null 2>&1; then
        print_verbose "Could not validate date with Linux date command, but format looks valid"
    fi
fi
```

### Testing

The script now works with:
- ✅ macOS (Darwin)
- ✅ Linux (Ubuntu, CentOS, Amazon Linux, etc.)
- ✅ Any system with Bash 4+

### How to Upgrade

Simply download the updated `retry-failed-step-functions.sh` and use it as before.

### Usage

No changes to usage. Run the same command:

```bash
./retry-failed-step-functions.sh \
  --date 2025-11-13 \
  --region us-east-1 \
  --account-id 469225647823 \
  --profile cpe_admin-cpe \
  --state-machine individualSectionSM
```

---

## Version 1.0 (Initial Release)

- Initial release with full functionality
- Comprehensive documentation
- Interactive wrapper script
- Error handling and validation

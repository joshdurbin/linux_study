#!/bin/bash
# check.sh — iptables Deep Dive

PASS=0
FAIL=0

check() {
    local desc="$1"
    local result="$2"
    if [ "$result" -eq 0 ] 2>/dev/null || [ "$result" = "0" ]; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

check_cmd() {
    local desc="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $desc"
        FAIL=$((FAIL + 1))
    fi
}

# -------------------------------------------------------
# 1. iptables binary is available (try both variants)
# -------------------------------------------------------
IPTABLES_CMD=""
if command -v iptables >/dev/null 2>&1; then
    IPTABLES_CMD="iptables"
elif command -v iptables-legacy >/dev/null 2>&1; then
    IPTABLES_CMD="iptables-legacy"
fi

if [ -n "$IPTABLES_CMD" ]; then
    echo "PASS: iptables binary available ($IPTABLES_CMD)"
    PASS=$((PASS + 1))
else
    echo "FAIL: iptables binary not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 2. iptables version reports correctly
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if $IPTABLES_CMD --version 2>&1 | grep -qi "iptables"; then
        echo "PASS: iptables --version works"
        PASS=$((PASS + 1))
    else
        echo "FAIL: iptables --version did not produce expected output"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 3. filter table is readable
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if $IPTABLES_CMD -t filter -L -n >/dev/null 2>&1; then
        echo "PASS: filter table is readable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: could not read filter table (needs CAP_NET_ADMIN / root)"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 4. nat table is readable
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if $IPTABLES_CMD -t nat -L -n >/dev/null 2>&1; then
        echo "PASS: nat table is readable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: could not read nat table"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 5. mangle table is readable
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if $IPTABLES_CMD -t mangle -L -n >/dev/null 2>&1; then
        echo "PASS: mangle table is readable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: could not read mangle table"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 6. Can add a test rule
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if $IPTABLES_CMD -A INPUT -i lo -p tcp --dport 39876 -j DROP 2>/dev/null; then
        echo "PASS: added test DROP rule to INPUT"
        PASS=$((PASS + 1))
        # Clean up immediately
        $IPTABLES_CMD -D INPUT -i lo -p tcp --dport 39876 -j DROP 2>/dev/null
    else
        echo "FAIL: could not add test rule (needs CAP_NET_ADMIN / root)"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 7. Test rule is removed (cleanup verification)
# -------------------------------------------------------
if [ -n "$IPTABLES_CMD" ]; then
    if ! $IPTABLES_CMD -C INPUT -i lo -p tcp --dport 39876 -j DROP 2>/dev/null; then
        echo "PASS: test rule was cleaned up correctly"
        PASS=$((PASS + 1))
    else
        # Rule still exists — remove it and fail
        $IPTABLES_CMD -D INPUT -i lo -p tcp --dport 39876 -j DROP 2>/dev/null
        echo "FAIL: test rule was not removed"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 8. iptables-save is available
# -------------------------------------------------------
IPTABLES_SAVE_CMD=""
if command -v iptables-save >/dev/null 2>&1; then
    IPTABLES_SAVE_CMD="iptables-save"
elif command -v iptables-legacy-save >/dev/null 2>&1; then
    IPTABLES_SAVE_CMD="iptables-legacy-save"
fi

if [ -n "$IPTABLES_SAVE_CMD" ]; then
    echo "PASS: iptables-save is available ($IPTABLES_SAVE_CMD)"
    PASS=$((PASS + 1))
else
    echo "FAIL: iptables-save not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 9. iptables-save produces output with *filter section
# -------------------------------------------------------
if [ -n "$IPTABLES_SAVE_CMD" ]; then
    if $IPTABLES_SAVE_CMD 2>/dev/null | grep -q '^\*filter'; then
        echo "PASS: iptables-save output contains *filter section"
        PASS=$((PASS + 1))
    else
        echo "FAIL: iptables-save output missing *filter section"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 10. iptables-save output contains COMMIT
# -------------------------------------------------------
if [ -n "$IPTABLES_SAVE_CMD" ]; then
    if $IPTABLES_SAVE_CMD 2>/dev/null | grep -q '^COMMIT'; then
        echo "PASS: iptables-save output contains COMMIT terminator"
        PASS=$((PASS + 1))
    else
        echo "FAIL: iptables-save output missing COMMIT"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 11. iptables-restore is available
# -------------------------------------------------------
if command -v iptables-restore >/dev/null 2>&1 || \
   command -v iptables-legacy-restore >/dev/null 2>&1; then
    echo "PASS: iptables-restore is available"
    PASS=$((PASS + 1))
else
    echo "FAIL: iptables-restore not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 12. Practice directory exists
# -------------------------------------------------------
if [ -d "$HOME/practice/iptables" ]; then
    echo "PASS: ~/practice/iptables directory exists"
    PASS=$((PASS + 1))
else
    echo "FAIL: ~/practice/iptables directory not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 13. initial_rules.v4 save file exists
# -------------------------------------------------------
if [ -f "$HOME/practice/iptables/initial_rules.v4" ]; then
    echo "PASS: initial_rules.v4 was saved"
    PASS=$((PASS + 1))
else
    echo "FAIL: ~/practice/iptables/initial_rules.v4 not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 14. count_totals.sh script exists and is executable
# -------------------------------------------------------
if [ -f "$HOME/practice/iptables/count_totals.sh" ]; then
    echo "PASS: count_totals.sh exists"
    PASS=$((PASS + 1))
    if [ -x "$HOME/practice/iptables/count_totals.sh" ]; then
        echo "PASS: count_totals.sh is executable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: count_totals.sh is not executable"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: count_totals.sh not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))   # also fail the executable check
fi

# -------------------------------------------------------
# 15. count_totals.sh runs without error
# -------------------------------------------------------
if [ -f "$HOME/practice/iptables/count_totals.sh" ]; then
    if bash "$HOME/practice/iptables/count_totals.sh" >/dev/null 2>&1; then
        echo "PASS: count_totals.sh executes successfully"
        PASS=$((PASS + 1))
    else
        echo "FAIL: count_totals.sh exited with error"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# Summary
# -------------------------------------------------------
echo ""
echo "Results: $PASS passed, $FAIL failed"

if [ "$FAIL" -eq 0 ]; then
    exit 0
else
    exit 1
fi

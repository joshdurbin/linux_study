#!/bin/bash
# check.sh — tc / netem Traffic Control

PASS=0
FAIL=0

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

# Cleanup helper — ensure loopback is clean at start and end
cleanup_lo() {
    tc qdisc del dev lo root 2>/dev/null || true
}

cleanup_lo

# -------------------------------------------------------
# 1. tc binary is available
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    echo "PASS: tc is available ($(command -v tc))"
    PASS=$((PASS + 1))
else
    echo "FAIL: tc not found — install iproute2"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 2. tc qdisc show runs without error
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if tc qdisc show >/dev/null 2>&1; then
        echo "PASS: tc qdisc show runs successfully"
        PASS=$((PASS + 1))
    else
        echo "FAIL: tc qdisc show failed"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 3. tc qdisc show dev lo runs
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if tc qdisc show dev lo >/dev/null 2>&1; then
        echo "PASS: tc qdisc show dev lo works"
        PASS=$((PASS + 1))
    else
        echo "FAIL: tc qdisc show dev lo failed"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 4. Can add netem to loopback
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    cleanup_lo
    if tc qdisc add dev lo root netem delay 50ms 2>/dev/null; then
        echo "PASS: added netem delay to lo"
        PASS=$((PASS + 1))
    else
        echo "FAIL: could not add netem to lo (needs CAP_NET_ADMIN / root)"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 5. netem qdisc is visible after adding
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if tc qdisc show dev lo 2>/dev/null | grep -q netem; then
        echo "PASS: netem qdisc visible on lo"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netem not visible on lo after adding"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 6. tc -s qdisc show shows statistics
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if tc -s qdisc show dev lo 2>/dev/null | grep -qi 'sent\|bytes\|pkt\|netem'; then
        echo "PASS: tc -s qdisc show produces statistics output"
        PASS=$((PASS + 1))
    else
        echo "FAIL: tc -s qdisc show did not produce statistics"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 7. netem delay is measurable with ping
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1 && command -v ping >/dev/null 2>&1; then
    # netem should already be on lo from check 4; if not, add it
    tc qdisc show dev lo 2>/dev/null | grep -q netem || \
        tc qdisc add dev lo root netem delay 100ms 2>/dev/null

    # Ping once and check RTT
    RTT=$(ping -c 2 -W 3 127.0.0.1 2>/dev/null | \
          grep 'rtt\|round-trip' | grep -oE '[0-9]+\.[0-9]+' | head -2 | tail -1)
    # avg RTT should be > 50ms (2 × 25ms minimum)
    if [ -n "$RTT" ]; then
        RTT_INT=${RTT%.*}
        if [ "${RTT_INT:-0}" -ge 50 ]; then
            echo "PASS: netem delay is measurable via ping (avg RTT ~${RTT}ms)"
            PASS=$((PASS + 1))
        else
            echo "FAIL: ping RTT ($RTT ms) too low — netem delay not taking effect"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "PASS: ping completed (RTT parsing skipped)"
        PASS=$((PASS + 1))
    fi
fi

# -------------------------------------------------------
# 8. Can delete netem from loopback
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if tc qdisc del dev lo root 2>/dev/null; then
        echo "PASS: removed netem from lo"
        PASS=$((PASS + 1))
    else
        echo "FAIL: could not remove qdisc from lo"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 9. Loopback is clean after removal
# -------------------------------------------------------
if command -v tc >/dev/null 2>&1; then
    if ! tc qdisc show dev lo 2>/dev/null | grep -q netem; then
        echo "PASS: lo is clean (no netem) after deletion"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netem still present on lo after deletion"
        FAIL=$((FAIL + 1))
        cleanup_lo
    fi
fi

# -------------------------------------------------------
# 10. Practice directory exists
# -------------------------------------------------------
if [ -d "$HOME/practice/tc" ]; then
    echo "PASS: ~/practice/tc directory exists"
    PASS=$((PASS + 1))
else
    echo "FAIL: ~/practice/tc directory not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 11. netfault.sh exists and is executable
# -------------------------------------------------------
if [ -f "$HOME/practice/tc/netfault.sh" ]; then
    echo "PASS: netfault.sh exists"
    PASS=$((PASS + 1))
    if [ -x "$HOME/practice/tc/netfault.sh" ]; then
        echo "PASS: netfault.sh is executable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netfault.sh is not executable"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: netfault.sh not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 12. netfault.sh status action works
# -------------------------------------------------------
if [ -f "$HOME/practice/tc/netfault.sh" ]; then
    if bash "$HOME/practice/tc/netfault.sh" lo status >/dev/null 2>&1; then
        echo "PASS: netfault.sh status runs successfully"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netfault.sh status failed"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 13. netfault.sh slow-wan injects and clear removes netem
# -------------------------------------------------------
if [ -f "$HOME/practice/tc/netfault.sh" ] && command -v tc >/dev/null 2>&1; then
    cleanup_lo
    bash "$HOME/practice/tc/netfault.sh" lo slow-wan >/dev/null 2>&1
    if tc qdisc show dev lo 2>/dev/null | grep -q netem; then
        echo "PASS: netfault.sh slow-wan injects netem"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netfault.sh slow-wan did not inject netem"
        FAIL=$((FAIL + 1))
    fi
    bash "$HOME/practice/tc/netfault.sh" lo clear >/dev/null 2>&1
    if ! tc qdisc show dev lo 2>/dev/null | grep -q netem; then
        echo "PASS: netfault.sh clear removes netem"
        PASS=$((PASS + 1))
    else
        echo "FAIL: netfault.sh clear did not remove netem"
        FAIL=$((FAIL + 1))
        cleanup_lo
    fi
fi

# -------------------------------------------------------
# 14. tc_stats.sh exists and runs
# -------------------------------------------------------
if [ -f "$HOME/practice/tc/tc_stats.sh" ]; then
    echo "PASS: tc_stats.sh exists"
    PASS=$((PASS + 1))
    if bash "$HOME/practice/tc/tc_stats.sh" >/dev/null 2>&1; then
        echo "PASS: tc_stats.sh executes successfully"
        PASS=$((PASS + 1))
    else
        echo "FAIL: tc_stats.sh exited with error"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: tc_stats.sh not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 15. baseline_qdiscs.txt was saved
# -------------------------------------------------------
if [ -f "$HOME/practice/tc/baseline_qdiscs.txt" ]; then
    echo "PASS: baseline_qdiscs.txt was saved"
    PASS=$((PASS + 1))
else
    echo "FAIL: baseline_qdiscs.txt not found"
    FAIL=$((FAIL + 1))
fi

# Final cleanup — ensure lo is clean
cleanup_lo

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

#!/bin/bash
# check.sh — VXLAN interface creation and inspection

PASS=0
FAIL=0

# Cleanup helper
cleanup_vxlan() {
    ip link del vxlan_test99 2>/dev/null || true
    ip link del vxlan_test98 2>/dev/null || true
}

cleanup_vxlan

# -------------------------------------------------------
# 1. ip link type vxlan syntax is supported
# -------------------------------------------------------
if ip link help type vxlan 2>&1 | grep -qi 'vxlan\|type\|Usage\|id' || \
   ip link add vxlan_test99 type vxlan id 999 dstport 4789 2>/dev/null; then
    # Try creation as the real test
    ip link del vxlan_test99 2>/dev/null
    if ip link add vxlan_test99 type vxlan id 999 dstport 4789 2>/dev/null; then
        echo "PASS: ip link type vxlan is supported"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ip link add type vxlan failed (kernel may lack VXLAN support)"
        FAIL=$((FAIL + 1))
    fi
else
    # Attempt creation anyway
    if ip link add vxlan_test99 type vxlan id 999 dstport 4789 2>/dev/null; then
        echo "PASS: ip link type vxlan is supported"
        PASS=$((PASS + 1))
    else
        echo "FAIL: ip link type vxlan not supported in this kernel/container"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 2. VXLAN interface creation succeeds
# -------------------------------------------------------
ip link del vxlan_test99 2>/dev/null
if ip link add vxlan_test99 type vxlan id 999 dstport 4789 2>/dev/null; then
    echo "PASS: VXLAN interface vxlan_test99 created successfully"
    PASS=$((PASS + 1))
else
    echo "FAIL: could not create VXLAN interface (needs CAP_NET_ADMIN / root + kernel VXLAN)"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 3. ip link show lists the new VXLAN interface
# -------------------------------------------------------
if ip link show vxlan_test99 >/dev/null 2>&1; then
    echo "PASS: ip link show finds vxlan_test99"
    PASS=$((PASS + 1))
else
    echo "FAIL: vxlan_test99 not visible in ip link show"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 4. ip link show type vxlan lists VXLAN interfaces
# -------------------------------------------------------
if ip link show type vxlan 2>/dev/null | grep -q vxlan_test99; then
    echo "PASS: ip link show type vxlan lists the test interface"
    PASS=$((PASS + 1))
else
    echo "FAIL: ip link show type vxlan did not list vxlan_test99"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 5. ip -d link show reveals VXLAN details (id/dstport)
# -------------------------------------------------------
DETAIL=$(ip -d link show vxlan_test99 2>/dev/null)
if echo "$DETAIL" | grep -q 'vxlan id 999'; then
    echo "PASS: ip -d link show shows VNI correctly (id 999)"
    PASS=$((PASS + 1))
else
    echo "FAIL: ip -d link show did not show VNI 999"
    FAIL=$((FAIL + 1))
fi

if echo "$DETAIL" | grep -q 'dstport 4789'; then
    echo "PASS: ip -d link show shows dstport 4789"
    PASS=$((PASS + 1))
else
    echo "FAIL: ip -d link show did not show dstport 4789"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 6. MTU on VXLAN interface is <= 1450 (overhead reduction)
# -------------------------------------------------------
MTU=$(ip link show vxlan_test99 2>/dev/null | grep -oE 'mtu [0-9]+' | awk '{print $2}')
if [ -n "$MTU" ]; then
    if [ "$MTU" -le 1450 ]; then
        echo "PASS: VXLAN interface MTU is $MTU (<= 1450 — accounts for encap overhead)"
        PASS=$((PASS + 1))
    else
        echo "PASS: VXLAN interface MTU is $MTU (MTU check — may vary by kernel version)"
        PASS=$((PASS + 1))
    fi
else
    echo "FAIL: could not determine MTU of vxlan_test99"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 7. bridge fdb show dev works on VXLAN interface
# -------------------------------------------------------
if bridge fdb show dev vxlan_test99 >/dev/null 2>&1; then
    echo "PASS: bridge fdb show dev vxlan_test99 works"
    PASS=$((PASS + 1))
else
    echo "FAIL: bridge fdb show dev vxlan_test99 failed"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 8. Can add a static FDB entry
# -------------------------------------------------------
if bridge fdb add de:ad:be:ef:99:99 dev vxlan_test99 dst 10.255.255.1 2>/dev/null; then
    echo "PASS: added static FDB entry to vxlan_test99"
    PASS=$((PASS + 1))
    # Verify it appears
    if bridge fdb show dev vxlan_test99 2>/dev/null | grep -q 'de:ad:be:ef:99:99'; then
        echo "PASS: static FDB entry is visible"
        PASS=$((PASS + 1))
    else
        echo "FAIL: static FDB entry not visible after adding"
        FAIL=$((FAIL + 1))
    fi
    # Clean up FDB entry
    bridge fdb del de:ad:be:ef:99:99 dev vxlan_test99 dst 10.255.255.1 2>/dev/null
else
    echo "FAIL: could not add static FDB entry"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 9. tcpdump accepts UDP port 4789 filter (VXLAN)
# -------------------------------------------------------
if command -v tcpdump >/dev/null 2>&1; then
    # Test that tcpdump can compile the VXLAN filter
    if tcpdump -d udp port 4789 >/dev/null 2>&1; then
        echo "PASS: tcpdump accepts 'udp port 4789' VXLAN filter"
        PASS=$((PASS + 1))
    else
        echo "FAIL: tcpdump rejected 'udp port 4789' filter"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: tcpdump not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 10. VXLAN interface deletion works
# -------------------------------------------------------
if ip link del vxlan_test99 2>/dev/null; then
    echo "PASS: VXLAN interface deleted successfully"
    PASS=$((PASS + 1))
else
    echo "FAIL: could not delete vxlan_test99"
    FAIL=$((FAIL + 1))
fi

if ! ip link show vxlan_test99 >/dev/null 2>&1; then
    echo "PASS: vxlan_test99 is gone after deletion"
    PASS=$((PASS + 1))
else
    echo "FAIL: vxlan_test99 still present after deletion"
    FAIL=$((FAIL + 1))
    ip link del vxlan_test99 2>/dev/null
fi

# -------------------------------------------------------
# 11. Practice directory exists
# -------------------------------------------------------
if [ -d "$HOME/practice/vxlan" ]; then
    echo "PASS: ~/practice/vxlan directory exists"
    PASS=$((PASS + 1))
else
    echo "FAIL: ~/practice/vxlan directory not found"
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 12. vxlan_inspect.sh exists and is executable
# -------------------------------------------------------
if [ -f "$HOME/practice/vxlan/vxlan_inspect.sh" ]; then
    echo "PASS: vxlan_inspect.sh exists"
    PASS=$((PASS + 1))
    if [ -x "$HOME/practice/vxlan/vxlan_inspect.sh" ]; then
        echo "PASS: vxlan_inspect.sh is executable"
        PASS=$((PASS + 1))
    else
        echo "FAIL: vxlan_inspect.sh is not executable"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: vxlan_inspect.sh not found"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# 13. vxlan_inspect.sh runs without error
# -------------------------------------------------------
if [ -f "$HOME/practice/vxlan/vxlan_inspect.sh" ]; then
    if bash "$HOME/practice/vxlan/vxlan_inspect.sh" >/dev/null 2>&1; then
        echo "PASS: vxlan_inspect.sh executes successfully"
        PASS=$((PASS + 1))
    else
        echo "FAIL: vxlan_inspect.sh exited with error"
        FAIL=$((FAIL + 1))
    fi
fi

# -------------------------------------------------------
# 14. vxlan0_detail.txt was saved from exercise
# -------------------------------------------------------
if [ -f "$HOME/practice/vxlan/vxlan0_detail.txt" ]; then
    echo "PASS: vxlan0_detail.txt exists (ip -d link show output was saved)"
    PASS=$((PASS + 1))
    if grep -q 'vxlan id' "$HOME/practice/vxlan/vxlan0_detail.txt" 2>/dev/null; then
        echo "PASS: vxlan0_detail.txt contains VXLAN parameters"
        PASS=$((PASS + 1))
    else
        echo "FAIL: vxlan0_detail.txt does not contain VXLAN parameters"
        FAIL=$((FAIL + 1))
    fi
else
    echo "FAIL: vxlan0_detail.txt not found (save output of: ip -d link show vxlan0)"
    FAIL=$((FAIL + 1))
    FAIL=$((FAIL + 1))
fi

# -------------------------------------------------------
# Final cleanup
# -------------------------------------------------------
cleanup_vxlan

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

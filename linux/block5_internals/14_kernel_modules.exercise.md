# Exercise: Kernel Modules

## Tasks

1. **Module inventory**: Survey loaded modules and the module path:
   ```bash
   echo "=== Loaded modules ===" > ~/practice/modules_inventory.txt
   lsmod | head -20 >> ~/practice/modules_inventory.txt
   echo "=== Module count ===" >> ~/practice/modules_inventory.txt
   lsmod | wc -l >> ~/practice/modules_inventory.txt
   echo "=== /lib/modules path ===" >> ~/practice/modules_inventory.txt
   ls /lib/modules/$(uname -r)/ >> ~/practice/modules_inventory.txt
   ```

2. **modinfo inspection**: Get metadata for two common modules:
   ```bash
   {
     echo "=== ext4 ===" 
     modinfo ext4 2>/dev/null || modinfo overlay 2>/dev/null || echo "module not found"
     echo "=== br_netfilter ==="
     modinfo br_netfilter 2>/dev/null || echo "module not found"
   } > ~/practice/modinfo_output.txt
   ```

3. **Load and inspect a module**: Load the `dummy` network module:
   ```bash
   sudo modprobe dummy 2>/dev/null || echo "modprobe dummy failed" > ~/practice/module_load.txt
   lsmod | grep dummy > ~/practice/module_load.txt
   ip link show dummy0 2>/dev/null >> ~/practice/module_load.txt || echo "no dummy0 interface" >> ~/practice/module_load.txt
   sudo modprobe -r dummy 2>/dev/null || true
   ```

4. **Module dependencies**: Show what `br_netfilter` depends on:
   ```bash
   modprobe --show-depends br_netfilter 2>/dev/null > ~/practice/module_deps.txt || \
   modinfo -F depends br_netfilter 2>/dev/null > ~/practice/module_deps.txt || \
   echo "dependency info not available" > ~/practice/module_deps.txt
   ```

5. **Module parameters**: Find parameters for any loaded module:
   ```bash
   # Find a module that exposes parameters via /sys
   MODULE=$(lsmod | awk 'NR>1{print $1}' | while read m; do
     ls /sys/module/$m/parameters/ 2>/dev/null | head -1 | grep -q . && echo $m && break
   done)
   echo "Module with params: $MODULE" > ~/practice/module_params.txt
   ls /sys/module/$MODULE/parameters/ >> ~/practice/module_params.txt 2>/dev/null
   ```

## Hints

- `dummy` module creates a virtual network interface — useful for testing without real hardware
- `modprobe --show-depends` shows the full chain of modules that would be loaded
- `/sys/module/<name>/parameters/` exposes runtime-readable (sometimes writable) module parameters
- `modprobe -r` removes the module and its unused dependencies

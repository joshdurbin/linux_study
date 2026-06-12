# Kernel Modules

Kernel modules are `.ko` (kernel object) files that extend the running kernel without a reboot. Drivers, filesystems, and kernel features are all loadable modules.

## Module Files

```bash
# Modules live in /lib/modules/$(uname -r)/
ls /lib/modules/$(uname -r)/
# build/   kernel/   modules.alias   modules.dep   modules.symbols ...

# Find a specific module file
find /lib/modules/$(uname -r) -name "ext4.ko*"
find /lib/modules/$(uname -r) -name "*.ko*" | grep vxlan
```

## lsmod — List Loaded Modules

```bash
lsmod                      # all loaded modules
lsmod | grep ext4          # filter by name
lsmod | wc -l              # how many are loaded

# Output columns: Module  Size  Used_by(count module_list)
# Used_by > 0 means other modules depend on it
```

## modinfo — Module Metadata

```bash
modinfo ext4               # description, version, author, params, dependencies
modinfo overlay            # overlay filesystem module
modinfo -F filename ext4   # just the .ko file path
modinfo -F parm ext4       # just parameters
```

## modprobe — Load and Remove Modules

```bash
# Load a module (with dependencies)
sudo modprobe overlay
sudo modprobe br_netfilter   # required for Kubernetes networking

# Remove a module
sudo modprobe -r overlay

# Load with parameters
sudo modprobe tcp_bbr        # enable BBR congestion control
sudo modprobe dummy numdummies=2

# Dry run — show what would happen
modprobe --dry-run overlay

# List module dependencies
modprobe --show-depends br_netfilter
```

## insmod / rmmod — Low-Level

```bash
# insmod: load a specific .ko file (no dependency resolution)
sudo insmod /lib/modules/$(uname -r)/kernel/net/ipv4/tcp_bbr.ko

# rmmod: remove by name (fails if in use)
sudo rmmod tcp_bbr

# Force remove (dangerous, can crash system)
sudo rmmod -f tcp_bbr
```

## Persistent Module Loading

```bash
# /etc/modules — loaded at boot (one module per line)
cat /etc/modules
echo "br_netfilter" | sudo tee -a /etc/modules

# /etc/modules-load.d/ — modern way (systemd-modules-load.service)
echo "br_netfilter" | sudo tee /etc/modules-load.d/k8s.conf
```

## Module Configuration

```bash
# /etc/modprobe.d/ — options, aliases, blacklists
ls /etc/modprobe.d/

# Set module parameters persistently
echo "options tcp_bbr" | sudo tee /etc/modprobe.d/tcp_bbr.conf

# Blacklist a module (prevent loading)
echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# Alias: map a virtual name to a real module
# echo "alias net-pf-10 ipv6" >> /etc/modprobe.d/ipv6.conf
```

## Kernel Module Parameters

```bash
# View current parameter values (loaded module)
cat /sys/module/ext4/parameters/errors   # if parameter is exposed

# View available parameters from modinfo
modinfo -F parm usbcore

# Set at load time
modprobe usbcore blinkenlights=1

# After loading, some params writable via /sys
echo 1 > /sys/module/printk/parameters/time
```

## depmod — Rebuild Dependency Database

```bash
# Run after adding new .ko files (e.g., after DKMS build)
sudo depmod -a

# Check dependencies without updating
depmod --dry-run -n
```

## Signing and Security

```bash
# Check if module is signed
modinfo ext4 | grep sig
# sig_id:   PKCS#7, sha512 (on secure boot systems)

# Check secure boot status
mokutil --sb-state
```

## Further Reading

- [Kernel module documentation — kernel.org](https://www.kernel.org/doc/html/latest/kbuild/modules.html) — the kernel's build system documentation for `.ko` modules: the `Makefile` format, out-of-tree builds, `DKMS`, and the `modpost` symbol-checking step.
- [modprobe(8) — man7.org](https://man7.org/linux/man-pages/man8/modprobe.8.html) — complete `modprobe` reference covering dependency resolution, module options, blacklisting, aliases, and the `/etc/modprobe.d/` configuration syntax.
- [linux-kernel-labs — Kernel Modules lab](https://linux-kernel-labs.github.io/refs/heads/master/labs/kernel_modules.html) — hands-on lab for writing, building, and loading a real `.ko` module with `module_param`, `/proc` entries, and `module_init`/`module_exit` handlers.
- [LWN — Module signing](https://lwn.net/Articles/532706/) — explains the kernel module signing infrastructure: how `CONFIG_MODULE_SIG` works, PKCS#7 signatures, the MOK (Machine Owner Key) database, and implications for Secure Boot systems.

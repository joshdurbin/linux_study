# Dynamic Linker, Shared Libraries, and LD_PRELOAD

Understanding how Linux loads programs — the dynamic linker, shared library resolution, and LD_PRELOAD — is essential for debugging dependency issues, security auditing, and writing instrumentation tools.

## How ELF Programs Load

1. The kernel maps the ELF binary into memory
2. Reads `PT_INTERP` segment — points to the dynamic linker (`/lib64/ld-linux-x86-64.so.2`)
3. The dynamic linker finds and maps all required shared libraries
4. Resolves symbols (function addresses) via the GOT/PLT
5. Calls `main()`

```bash
# See which dynamic linker an ELF uses
readelf -l /bin/ls | grep interpreter
file /bin/ls
```

## ldd — List Dynamic Dependencies

```bash
ldd /bin/ls              # shows all shared libraries and their resolved paths
ldd /usr/bin/curl
ldd /lib/x86_64-linux-gnu/libc.so.6   # libc itself

# Security note: never run ldd on untrusted binaries
# (ldd executes the binary's init code to resolve deps)
# Use readelf -d instead:
readelf -d /bin/ls | grep NEEDED
```

Output example:
```
linux-vdso.so.1 (0x00007ffc...)     # virtual DSO — no file
libcurl.so.4 => /usr/lib/.../libcurl.so.4
libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
/lib64/ld-linux-x86-64.so.2         # the dynamic linker
```

## ldconfig — Shared Library Cache

```bash
ldconfig -p                          # list all cached libraries
ldconfig -p | grep libssl            # find libssl

# Rebuild the cache after installing new libraries
sudo ldconfig

# Add a custom library directory
echo "/opt/myapp/lib" | sudo tee /etc/ld.so.conf.d/myapp.conf
sudo ldconfig
```

Library search order:
1. `RPATH` embedded in the binary (deprecated)
2. `LD_LIBRARY_PATH` environment variable
3. `/etc/ld.so.cache` (built by ldconfig from `/etc/ld.so.conf`)
4. `/lib`, `/usr/lib` default paths

## LD_PRELOAD — Intercept Library Calls

`LD_PRELOAD` loads a shared library before all others, allowing you to override any libc/library function:

```bash
# Classic: intercept malloc to log allocations
# Your shared library's malloc() is called instead of libc's

# Practical example: fake time for testing
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1 \
  FAKETIME="2025-01-01 00:00:00" date

# Trace all open() calls without strace (using a preloaded shim)
LD_PRELOAD=./trace_open.so /usr/bin/program

# Security implication: LD_PRELOAD is ignored for SUID binaries
ls -la /usr/bin/sudo   # note the 's' in permissions
```

Writing a minimal LD_PRELOAD shim:
```c
// override_write.c
#define _GNU_SOURCE
#include <unistd.h>
#include <dlfcn.h>
ssize_t write(int fd, const void *buf, size_t count) {
    static ssize_t (*real_write)(int, const void*, size_t) = NULL;
    if (!real_write) real_write = dlsym(RTLD_NEXT, "write");
    // log fd writes here
    return real_write(fd, buf, count);
}
// gcc -shared -fPIC -o override_write.so override_write.c -ldl
```

## ltrace — Library Call Tracer

Like `strace` but for user-space library calls (libc, libssl, etc.):

```bash
ltrace /bin/ls 2>&1 | head -20     # all library calls
ltrace -e malloc,free /bin/ls      # only malloc/free
ltrace -l libc.so.6 ls             # only calls to libc
ltrace -c ls                       # count mode (like strace -c)
```

## Symbol Inspection

```bash
nm /usr/lib/x86_64-linux-gnu/libc.so.6 | grep " T " | grep "malloc"   # defined symbols
nm /bin/ls | grep " U "     # undefined (externally resolved) symbols
objdump -d /bin/ls | head -60  # disassemble
strings /bin/ls | head -20     # printable strings (useful for secrets hunting)
```

## Further Reading

- [ld.so(8) — man7.org](https://man7.org/linux/man-pages/man8/ld.so.8.html) — the definitive reference for the dynamic linker: library search order, `LD_PRELOAD`, `LD_LIBRARY_PATH`, `LD_DEBUG` for tracing resolution, rpath, and the `/etc/ld.so.cache` format.
- [dlopen(3) — man7.org](https://man7.org/linux/man-pages/man3/dlopen.3.html) — documents the runtime dynamic linking API: `dlopen`, `dlsym`, `RTLD_NEXT` (used in LD_PRELOAD shims), `RTLD_LAZY` vs `RTLD_NOW`, and `dlclose`.
- [Linkers and Loaders — Ian Lance Taylor](https://www.lurklurk.org/linkers/linkers.html) — a thorough guide to how linkers and loaders work: ELF structure, PLT/GOT lazy binding, RPATH, symbol versioning, and the full dynamic linking resolution process.
- [LWN — How programs get run: ELF binaries](https://lwn.net/Articles/631631/) — LWN article tracing ELF program startup from the `execve` syscall through kernel ELF parsing, `PT_INTERP` loading, and the dynamic linker's initialization sequence.
- [Julia Evans — LD_PRELOAD is super fun](https://jvns.ca/blog/2014/11/27/ld-preload-is-super-fun-and-easy/) — practical introduction to LD_PRELOAD with working examples showing how to intercept `malloc`, `write`, and `time`, and the security boundary (ignored for SUID binaries).

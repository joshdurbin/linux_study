# Exercise: Dynamic Linker and Shared Libraries

## Tasks

1. **ldd inspection**: Run `ldd /bin/ls` and `ldd /usr/bin/curl`. Save both outputs to `~/practice/ldd_output.txt`. Note which shared libraries appear in both.

2. **Library cache**: Run `ldconfig -p | wc -l` (total cached libraries) and `ldconfig -p | grep libssl` (find OpenSSL). Save to `~/practice/ldconfig_output.txt`.

3. **Interpreter and NEEDED sections**: Use `readelf` to inspect `/bin/bash`:
   ```bash
   readelf -l /bin/bash | grep interpreter >> ~/practice/readelf_bash.txt
   readelf -d /bin/bash | grep NEEDED >> ~/practice/readelf_bash.txt
   ```
   Save to `~/practice/readelf_bash.txt`.

4. **LD_PRELOAD demo**: Use the `faketime` library if available, or demonstrate LD_PRELOAD with a simple test:
   ```bash
   # Check if faketime is available
   if ldconfig -p | grep -q faketime; then
     LD_PRELOAD=/usr/lib/x86_64-linux-gnu/faketime/libfaketime.so.1 \
       FAKETIME="2030-01-01 00:00:00" date > ~/practice/ld_preload_demo.txt
   else
     echo "LD_PRELOAD=/path/to/shim.so command" > ~/practice/ld_preload_demo.txt
     echo "LD_PRELOAD is ignored for SUID binaries (security)" >> ~/practice/ld_preload_demo.txt
   fi
   ```

5. **ltrace**: Run `ltrace -c ls /tmp 2>&1 | head -20` and save to `~/practice/ltrace_output.txt`. Compare the library calls shown to what `strace -c ls /tmp` would show.

## Hints

- `readelf -d binary | grep NEEDED` is safer than `ldd` for untrusted binaries
- `ldconfig -p` reads from `/etc/ld.so.cache` — no need for sudo to read
- `ltrace` may not be installed: `sudo apt-get install -y ltrace`

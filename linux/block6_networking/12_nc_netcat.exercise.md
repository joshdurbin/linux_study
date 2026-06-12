# Exercise: nc / ncat

## Tasks

1. **Port scan with nc**: Test which common ports are open on localhost:
   ```bash
   nc -zvw2 localhost 22 80 443 3306 5432 8080 2>&1 > ~/practice/nc_portscan.txt
   echo "Scan complete" >> ~/practice/nc_portscan.txt
   ```

2. **File transfer**: Use nc to transfer a file between two local processes:
   ```bash
   echo "nc file transfer test - $(date)" > /tmp/nc_send.txt
   nc -l 19999 > /tmp/nc_recv.txt &
   NC_PID=$!
   sleep 0.3
   nc localhost 19999 < /tmp/nc_send.txt
   wait $NC_PID 2>/dev/null
   diff /tmp/nc_send.txt /tmp/nc_recv.txt && echo "MATCH" || echo "MISMATCH"
   cp /tmp/nc_recv.txt ~/practice/nc_transfer.txt
   ```

3. **HTTP probe**: Use nc to make a raw HTTP request and save the response headers:
   ```bash
   printf "HEAD / HTTP/1.0\r\nHost: localhost\r\n\r\n" | \
     nc -w3 localhost 80 2>/dev/null > ~/practice/nc_http.txt || \
   printf "HEAD / HTTP/1.0\r\nHost: example.com\r\n\r\n" | \
     nc -w3 example.com 80 2>/dev/null > ~/practice/nc_http.txt || \
   echo "no HTTP server reachable" > ~/practice/nc_http.txt
   ```

4. **Service wait script**: Write `~/practice/wait_for_port.sh` — a script that uses `nc -z` in a loop to wait for a port to become available, with a timeout:
   ```bash
   cat > ~/practice/wait_for_port.sh << 'EOF'
   #!/bin/bash
   HOST=${1:-localhost}
   PORT=${2:-8080}
   TIMEOUT=${3:-30}
   elapsed=0
   until nc -z "$HOST" "$PORT" 2>/dev/null; do
     sleep 1; ((elapsed++))
     [[ $elapsed -ge $TIMEOUT ]] && echo "Timeout waiting for $HOST:$PORT" && exit 1
   done
   echo "$HOST:$PORT is available (after ${elapsed}s)"
   EOF
   chmod +x ~/practice/wait_for_port.sh
   ```

## Hints

- `nc -zvw2` uses a 2-second timeout per port — adjust with `-w`
- The background listener (`&`) must be started before the sender
- `nc -l PORT` (GNU/Linux syntax) vs `nc -l -p PORT` (BSD syntax) — Ubuntu uses the GNU version

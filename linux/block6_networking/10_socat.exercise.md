# Exercise: socat

## Tasks

1. **Install and verify**: Run `which socat || sudo apt-get install -y socat` then `socat -V`. Save the version output to `~/practice/socat_version.txt`.

2. **TCP echo relay**: In one terminal, start a listener:
   ```bash
   socat TCP-LISTEN:7777,fork EXEC:'cat'
   ```
   In another (or use background + sleep):
   ```bash
   echo "hello socat" | socat - TCP:localhost:7777
   ```
   Save the echo output to `~/practice/socat_echo.txt`.

3. **Unix socket proxy**: Use socat to forward a local port to the Docker socket (read-only probe):
   ```bash
   socat TCP-LISTEN:12375,fork,reuseaddr UNIX-CONNECT:/var/run/docker.sock &
   curl -s http://localhost:12375/version 2>/dev/null || echo "docker socket not available"
   ```
   Save the result to `~/practice/socat_docker_proxy.txt`.

4. **File transfer simulation**: Use socat to transfer a file between two local "endpoints":
   ```bash
   echo "socat file transfer test" > /tmp/socat_send.txt
   socat TCP-LISTEN:7778 FILE:/tmp/socat_recv.txt &
   socat FILE:/tmp/socat_send.txt TCP:localhost:7778
   cat /tmp/socat_recv.txt
   ```
   Save the received content to `~/practice/socat_transfer.txt`.

5. **Write a cheatsheet**: Document 3 socat use cases from the lesson in `~/practice/socat_cheatsheet.txt`, including the command for each.

## Hints

- Use `&` to background a listener, then `kill %1` to clean it up
- `socat -d -d` gives verbose output if something isn't connecting
- The Docker socket probe (task 3) is expected to fail gracefully if Docker isn't running in the container

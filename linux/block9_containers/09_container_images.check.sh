#!/bin/bash
PASS=0; FAIL=0
check() { if eval "$2"; then echo "PASS: $1"; ((PASS++)); else echo "FAIL: $1"; ((FAIL++)); fi; }

# Check 1: docker is available
check "docker CLI is available" \
  "command -v docker > /dev/null 2>&1"

# Check 2: docker daemon is reachable
check "docker daemon is reachable" \
  "docker info > /dev/null 2>&1"

# Check 3: practice directory exists
check "~/practice/container_images directory exists" \
  "[ -d \$HOME/practice/container_images ]"

# Check 4: simple Dockerfile exists
check "simple/Dockerfile exists" \
  "[ -f \$HOME/practice/container_images/simple/Dockerfile ]"

# Check 5: simple Dockerfile references FROM
check "simple/Dockerfile has a FROM instruction" \
  "grep -qi '^FROM' \$HOME/practice/container_images/simple/Dockerfile"

# Check 6: simple Dockerfile references RUN or COPY
check "simple/Dockerfile has RUN or COPY instructions" \
  "grep -qE '^(RUN|COPY)' \$HOME/practice/container_images/simple/Dockerfile"

# Check 7: study-simple image was built
check "study-simple:v1 image exists locally" \
  "docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q 'study-simple:v1'"

# Check 8: docker history works on the built image
check "docker history runs successfully on study-simple:v1" \
  "docker history study-simple:v1 > /dev/null 2>&1"

# Check 9: docker inspect produces JSON with Config key
check "docker inspect study-simple:v1 produces JSON with Config" \
  "docker inspect study-simple:v1 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); exit(0 if \"Config\" in d[0] else 1)'"

# Check 10: image has more than 1 layer (i.e., we actually added layers)
check "study-simple:v1 has more than 1 RootFS layer" \
  "CNT=\$(docker inspect study-simple:v1 --format '{{len .RootFS.Layers}}' 2>/dev/null); [ \"\${CNT:-0}\" -gt 1 ]"

# Check 11: multi-stage Dockerfile exists
check "multistage/Dockerfile.multistage exists" \
  "[ -f \$HOME/practice/container_images/multistage/Dockerfile.multistage ]"

# Check 12: multi-stage Dockerfile uses AS keyword (multi-stage)
check "Dockerfile.multistage uses multi-stage AS syntax" \
  "grep -qi ' AS ' \$HOME/practice/container_images/multistage/Dockerfile.multistage"

# Check 13: multi-stage Dockerfile uses COPY --from
check "Dockerfile.multistage uses COPY --from" \
  "grep -qi 'COPY --from' \$HOME/practice/container_images/multistage/Dockerfile.multistage"

# Check 14: study-multistage image was built
check "study-multistage:v1 image exists locally" \
  "docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q 'study-multistage:v1'"

# Check 15: .dockerignore file exists
check ".dockerignore file exists in dockerignore/ directory" \
  "[ -f \$HOME/practice/container_images/dockerignore/.dockerignore ]"

# Check 16: .dockerignore excludes sensitive files
check ".dockerignore excludes .env or credentials" \
  "grep -qE '\.env|credentials' \$HOME/practice/container_images/dockerignore/.dockerignore"

# Check 17: study-context:with-ignore image does not contain .env
check "study-context:with-ignore image does not contain .env file" \
  "docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -q 'study-context:with-ignore' && \
   docker run --rm study-context:with-ignore bash -c '! test -f /app/.env' 2>/dev/null || \
   docker image ls --format '{{.Repository}}:{{.Tag}}' | grep -vq 'study-context:with-ignore'"

# Check 18: notes file exists with image/layer content
check "image_notes.txt exists" \
  "[ -f \$HOME/practice/container_images/image_notes.txt ]"

check "image_notes.txt mentions layer" \
  "grep -qi 'layer' \$HOME/practice/container_images/image_notes.txt"

check "image_notes.txt mentions overlay" \
  "grep -qi 'overlay' \$HOME/practice/container_images/image_notes.txt"

# Check 19: can run a container from the built image (smoke test)
check "study-simple:v1 can run successfully" \
  "docker run --rm study-simple:v1 > /dev/null 2>&1"

# Check 20: study-multistage:v1 can run successfully
check "study-multistage:v1 can run successfully" \
  "docker run --rm study-multistage:v1 > /dev/null 2>&1"

echo "---"
echo "$PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]

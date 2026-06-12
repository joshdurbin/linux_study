# Exercise: Reliability Patterns

Complete the following tasks. Save your notes to `~/practice/reliability_patterns.txt`.

## Task 1 — Document All Six Patterns

```bash
mkdir -p ~/practice
cat > ~/practice/reliability_patterns.txt << 'EOF'
Reliability Patterns
=====================

1. CIRCUIT BREAKER
-------------------
Prevents cascading failures by stopping calls to a failing dependency.

States:
  Closed (normal):   requests flow through; count failures
  Open (failing):    requests fail immediately; no calls to dependency; start timer
  Half-Open (test):  allow one test request; success → close; fail → reopen

Key parameters:
  failure_threshold:   how many failures to open (e.g., 5 in 10 seconds)
  timeout_duration:    how long to stay open before trying half-open (e.g., 30s)
  success_threshold:   how many successes to close from half-open (e.g., 2)

When to use: any synchronous call to external service, database, or downstream API.
Libraries: Hystrix (Java), gobreaker (Go), resilience4j (Java), polly (.NET)

2. RETRY WITH EXPONENTIAL BACKOFF AND JITTER
---------------------------------------------
Retry transient failures; use backoff + jitter to avoid thundering herd.

Formula: wait = base_delay × 2^attempt + random(0, jitter_max)
Example: 1s, 2s+rand, 4s+rand, 8s+rand, 16s+rand (max 5 retries)

Rules:
  - Only retry idempotent operations (GET, PUT, DELETE — not POST)
  - Set a max retry count
  - Never retry on non-transient errors (404, 400, auth failures)
  - Add jitter (± 0-3s) to spread retry storms

3. TIMEOUT
-----------
Every external call must have a deadline.

Without timeout: slow dependency holds connection/thread until exhaustion.
With timeout: fast failure, controlled degradation.

Hierarchy rule: child timeout < parent timeout
  Browser → API (10s) → DB query (2s) → external API (1s)

Types:
  connect timeout:  time to establish TCP connection (usually 2-5s)
  read timeout:     time to receive first byte after connect (1-30s)
  deadline:         total time for entire operation

4. BULKHEAD
-----------
Isolate failure domains to prevent one failing component from consuming all resources.

Thread pool bulkhead:
  Each downstream service gets its own thread pool.
  Pool for payments: 50 threads max
  Pool for recommendations: 10 threads max
  Slow recommendations don't starve payments threads.

Deployment bulkhead:
  Critical services deployed separately from non-critical.
  Checkout service has no shared resources with analytics service.

5. RATE LIMITING
-----------------
Protect services from being overwhelmed by too many requests.

Token bucket algorithm:
  - Bucket holds max N tokens
  - Each request consumes 1 token
  - Tokens refill at rate R per second
  - Burst up to N allowed; sustained rate capped at R

Leaky bucket algorithm:
  - Requests enter queue at any rate
  - Queue drains at a fixed constant rate
  - Smooths bursts; excess requests are queued or dropped

Where to rate limit:
  - API gateway (per client IP, per API key)
  - Individual services (protect DB from too many connections)
  - Inter-service calls (prevent one service from flooding another)

6. GRACEFUL DEGRADATION
------------------------
Return partial results or cached data when dependencies fail.
Better to return something useful than fail completely.

Examples:
  - Recommendations service down → show top sellers (static fallback)
  - DB slow → return cached result (TTL: 60s)
  - Search service down → hide search bar (feature hide)
  - Payment gateway slow → show "processing" and handle async

Always:
  - Increment a counter when falling back (alert on sustained fallback)
  - Log degraded mode so engineers know it's happening
EOF
```

## Task 2 — Apply Patterns to a Scenario

```bash
cat >> ~/practice/reliability_patterns.txt << 'EOF'

Applied Example: OrdersAPI calling PaymentsService
----------------------------------------------------
Problem: PaymentsService occasionally becomes slow (> 2s response time).
         During an incident it went down for 5 minutes.

Solution (applying all patterns):

Timeout:        Set payment call timeout to 3s (95th percentile is 500ms)
Retry:          Retry once on timeout/5xx with 1s jitter (payment is idempotent with txn-id)
Circuit breaker: Open after 3 failures in 10s; test with 1 req every 30s
Bulkhead:       Payment calls use dedicated thread pool (20 threads) separate from order pool
Rate limit:     OrdersAPI limits to 500 payment requests/s to avoid overwhelming payments
Degrade:        If circuit open: return "payment processing delayed" + queue for async retry
EOF
```

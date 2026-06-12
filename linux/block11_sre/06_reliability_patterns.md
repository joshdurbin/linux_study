# Reliability Patterns

## Why Reliability Patterns?

Distributed systems fail in complex ways. A single slow dependency can cascade into a full outage. Reliability patterns are proven techniques for making systems tolerant of partial failures, preventing cascades, and degrading gracefully instead of failing catastrophically.

## Circuit Breaker

Inspired by electrical circuit breakers: when a dependency is failing, stop calling it temporarily rather than accumulating failed requests.

**States:**
- **Closed** (normal): requests pass through to the dependency
- **Open** (failing): requests fail immediately without calling the dependency
- **Half-Open** (recovery): allow a test request through; if it succeeds, close again

```go
// Conceptual circuit breaker state machine:
// closed: failures < threshold → stay closed
// closed: failures >= threshold → open (start timer)
// open:   timer expires → half-open
// half-open: success → close; failure → open again
```

**When to use**: calls to external services, databases, or any dependency that can become slow/unavailable.

## Retry with Exponential Backoff and Jitter

Retrying immediately after a failure often makes things worse — all callers retry simultaneously, creating a thundering herd that overwhelms a recovering service.

**Exponential backoff**: each retry waits twice as long as the previous one.  
**Jitter**: add random spread to prevent synchronized retries.

```bash
# Retry pattern (shell example with exponential backoff + jitter):
max_retries=5
base_delay=1

for attempt in $(seq 1 $max_retries); do
  if curl -sf https://api.example.com/orders; then
    break
  fi
  sleep_time=$((base_delay * 2 ** (attempt - 1) + RANDOM % 3))
  echo "Attempt $attempt failed, retrying in ${sleep_time}s"
  sleep $sleep_time
done
```

**When to use**: transient errors (network glitches, rate limiting, temporary unavailability). Never retry non-idempotent operations without deduplication.

## Timeout

Every call to an external service must have a timeout. Without timeouts, a slow dependency holds threads/goroutines/connections until the caller's resources are exhausted.

```bash
# curl with timeout
curl --connect-timeout 2 --max-time 5 https://api.example.com/

# HTTP timeout in most languages:
# request timeout = network + server processing + network return
# Typical: 30ms for internal, 500ms for external, 5s maximum
```

**Rule**: set timeouts at every call boundary. The timeout should be less than the caller's own timeout.

## Bulkhead

Named after watertight compartments in ships: isolate parts of the system so that a failure in one part doesn't flood everything else.

**Thread pool bulkhead**: give each dependency its own thread pool. When one dependency is slow, only that pool fills up — other dependencies still have threads available.

**Deployment bulkhead**: separate critical services into isolated deployment units. A memory leak in a non-critical service doesn't crash the critical checkout service.

```
Service mesh bulkhead example:
  Each upstream gets its own connection pool limit
  Max connections to payments-service: 100
  Max connections to recommendations-service: 20
  Slow recommendations don't consume connections needed for payments
```

## Rate Limiting

Protect services from being overwhelmed by too many requests.

**Token bucket**: a bucket holds up to N tokens. Each request consumes one token. Tokens refill at a fixed rate. Burst traffic is handled by accumulated tokens.

**Leaky bucket**: requests enter a queue at any rate; they exit at a constant rate. Smooths bursts.

```bash
# nginx rate limiting:
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
server {
  location /api/ {
    limit_req zone=api burst=20 nodelay;
  }
}
```

## Graceful Degradation

Return partial results or fallback responses when dependencies fail, rather than returning an error or nothing.

Examples:
- Product page loads without recommendations if the recommendations service is down
- Return cached results from 5 minutes ago if the database is slow
- Show a "try again later" message instead of a 500 error

```go
// Pseudocode for graceful degradation:
recs, err := recommendationsService.Get(userID)
if err != nil {
    recs = defaultRecommendations  // fallback
    metrics.IncCounter("recommendations.fallback")
}
```

## Key Takeaways

- **Circuit breaker**: open on repeated failures; prevents hammering a failing dependency.
- **Retry + backoff + jitter**: retry transient failures; random jitter prevents thundering herd.
- **Timeout**: every external call needs one; prevents resource exhaustion from slow deps.
- **Bulkhead**: isolate failure domains; a pool per dependency, separate deployments for critical paths.
- **Rate limiting**: protect your service from overload using token bucket or leaky bucket.
- **Graceful degradation**: return partial results > returning nothing; cached > failed.

# jq and yq — JSON and YAML Processing

`jq` is the standard tool for processing JSON from the command line. `yq` extends similar ideas to YAML (and can convert between the two).

## jq — JSON Query and Transform

```bash
# Basic invocation
echo '{"name":"Alice","age":30}' | jq '.'      # pretty-print
cat data.json | jq '.'                          # pretty-print from file
jq '.' data.json                                # same
jq -c '.' data.json                             # compact (one line)
jq -r '.' data.json                             # raw output (no JSON quoting)
```

### Field Access

```bash
echo '{"name":"Alice","age":30}' | jq '.name'         # "Alice"
echo '{"user":{"id":42,"role":"admin"}}' | jq '.user.role'  # "admin"
jq -r '.name' data.json    # raw: Alice (no quotes)
```

### Array Access

```bash
echo '[1,2,3]' | jq '.[0]'          # 1 (first element)
echo '[1,2,3]' | jq '.[-1]'         # 3 (last element)
echo '[1,2,3]' | jq '.[1:3]'        # [2,3] (slice)
echo '[1,2,3]' | jq '.[]'           # iterate: outputs 1, 2, 3 separately
```

### Pipe in jq

```bash
# The | inside jq chains filters
echo '{"users":[{"name":"Alice"},{"name":"Bob"}]}' \
  | jq '.users[] | .name'       # Alice\nBob

echo '{"a":1,"b":2}' | jq '. | keys'   # ["a","b"]
```

### select — Filter by Condition

```bash
# Array of objects, filter by field value
echo '[{"name":"Alice","age":30},{"name":"Bob","age":25}]' \
  | jq '.[] | select(.age > 27)'    # only Alice's object

# Filter and extract field
jq '.items[] | select(.status == "active") | .name' data.json
```

### map — Transform Arrays

```bash
echo '[1,2,3,4]' | jq 'map(. * 2)'          # [2,4,6,8]
echo '[{"n":1},{"n":2}]' | jq 'map(.n)'     # [1,2]
jq '[.users[] | .name]' data.json           # array of names
jq 'map(select(.age >= 18))' users.json     # filter to adults
```

### Constructing Objects and Arrays

```bash
echo '{"first":"John","last":"Doe"}' \
  | jq '{fullname: (.first + " " + .last)}'

jq '{name: .name, count: (.items | length)}' data.json

# Build array from object fields
jq '[.[] | {key: .id, val: .name}]' data.json
```

### Built-in Functions

```bash
jq 'length'              # length of string/array/object
jq 'keys'                # object keys as array
jq 'values'              # object values as array
jq 'has("field")'        # true if key exists
jq 'to_entries'          # [{key:k, value:v}] pairs
jq 'from_entries'        # inverse
jq 'with_entries(.value |= . + 1)'  # transform each value

jq 'type'                # "string", "number", "array", etc.
jq 'ascii_downcase'      # lowercase string
jq 'split(",")'          # split string
jq 'join(",")'           # join array

jq '@base64'             # base64-encode
jq '@base64d'            # base64-decode
jq '@csv'                # format as CSV
jq '@tsv'                # format as TSV
```

### Practical jq One-liners

```bash
# Pretty-print any JSON file
jq '.' file.json

# Extract all unique values of a field
jq -r '.[].status' data.json | sort -u

# Count items in an array
jq '.items | length' data.json

# Get keys of first object in array
jq '.[0] | keys' data.json

# Filter and transform kubectl output
kubectl get pods -o json | jq '.items[] | {name: .metadata.name, status: .status.phase}'

# Merge two JSON objects
jq -s '.[0] * .[1]' base.json override.json

# Check if a field is null
jq '.field // "default_value"' data.json   # // is alternative operator
```

## yq — YAML Processing

```bash
yq eval '.' file.yaml               # pretty-print YAML
yq eval '.key' file.yaml            # extract field
yq eval '.key = "newval"' file.yaml # set a field (in place with -i)
yq eval -i '.version = "2.0"' app.yaml   # edit in place

# Convert YAML to JSON
yq eval -o json file.yaml

# Convert JSON to YAML
yq eval -P file.json    # prettyprint as YAML

# Multiple files
yq eval '.' *.yaml
yq eval-all 'select(.kind == "Service")' *.yaml
```

### yq Kubernetes examples

```bash
# Get image from k8s deployment
yq eval '.spec.template.spec.containers[0].image' deployment.yaml

# Update image tag in place
yq eval -i '.spec.template.spec.containers[0].image = "app:v2.0"' deploy.yaml

# Extract all container names
yq eval '.spec.template.spec.containers[].name' deployment.yaml
```

## Further Reading

- [jq manual](https://jqlang.github.io/jq/manual/) — the complete jq language reference: every filter, built-in function (`to_entries`, `from_entries`, `@base64`, `env`), type system, and advanced features like `reduce`, `label-break`, and `$__loc__`.
- [jq Cookbook](https://github.com/stedolan/jq/wiki/Cookbook) — community-maintained collection of real-world jq recipes: flattening nested arrays, merging objects, grouping by field, and transforming Kubernetes/AWS/Terraform JSON output.
- [yq documentation](https://mikefarah.gitbook.io/yq/) — official yq v4 reference covering YAML/JSON/TOML/XML processing, in-place editing, multi-document files, and Kubernetes manifest manipulation.
- [Julia Evans — jq](https://jvns.ca/blog/2016/04/19/a-few-things-i-learned-about-jq/) — practical introduction explaining `select`, `map`, `to_entries`, and the pipe model with real-world examples from JSON APIs and log parsing.

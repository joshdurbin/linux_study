# Exercise: jq and yq

## Setup — Create sample data

Create `~/jqlab/` and the following files:

**`~/jqlab/users.json`:**
```json
[
  {"id": 1, "name": "Alice", "role": "admin", "active": true, "score": 95},
  {"id": 2, "name": "Bob", "role": "user", "active": false, "score": 72},
  {"id": 3, "name": "Carol", "role": "user", "active": true, "score": 88},
  {"id": 4, "name": "Dave", "role": "admin", "active": true, "score": 61}
]
```

**`~/jqlab/config.yaml`:**
```yaml
app:
  name: myapp
  version: "1.0"
  port: 8080
database:
  host: localhost
  port: 5432
  name: mydb
```

## Task 1 — Basic jq queries

Run each query and save results to `~/jqlab/`:

1. Pretty-print `users.json` → `pretty.json`
2. Extract all names as raw strings (one per line) → `names.txt`
3. Get the user with id=3 → `user3.json`
4. Count the total number of users → `user_count.txt`

```bash
jq '.' ~/jqlab/users.json > ~/jqlab/pretty.json
jq -r '.[].name' ~/jqlab/users.json > ~/jqlab/names.txt
jq '.[] | select(.id == 3)' ~/jqlab/users.json > ~/jqlab/user3.json
jq 'length' ~/jqlab/users.json > ~/jqlab/user_count.txt
```

## Task 2 — Filtering and transforming

1. Get all active users (where `active == true`) → `active_users.json`
2. Extract just the names of admin-role users → `admin_names.txt`
3. Get average score: `jq '[.[].score] | add/length' users.json` → `avg_score.txt`
4. Create a new array with only `{id, name}` for each user → `id_name.json`

## Task 3 — yq YAML queries

(If `yq` is not installed: `sudo apt install yq` or `snap install yq`)

1. Pretty-print `config.yaml` → `config_pretty.yaml`
2. Extract `app.name` → `app_name.txt`
3. Extract `database.port` as a raw value → `db_port.txt`
4. Convert `config.yaml` to JSON with `yq eval -o json config.yaml` → `config.json`

## Task 4 — Practical pipeline

Combine jq filters in a pipeline:

```bash
# Get names of users with score above 80, sorted
jq -r '.[] | select(.score > 80) | .name' ~/jqlab/users.json | sort > ~/jqlab/high_scorers.txt
```

Save to `~/jqlab/high_scorers.txt`. The file should contain Alice and Carol (scores 95 and 88).

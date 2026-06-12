# Exercise: systemd Services

## Task 1 — List and inspect services

Create `~/servicelab/`. Run the following and save outputs:

1. List all service units with their status: `systemctl list-unit-files --type=service` → save to `~/servicelab/all_services.txt`
2. Check the status of `cron` (or `cron.service`): `systemctl status cron` → save to `~/servicelab/cron_status.txt`
3. Check if cron is enabled: `systemctl is-enabled cron` → save to `~/servicelab/cron_enabled.txt`

## Task 2 — Journal queries

1. View the last 20 lines of the system journal: `journalctl -n 20` → save to `~/servicelab/journal_recent.txt`
2. View only error-level log entries: `journalctl -p err -n 20` → save to `~/servicelab/journal_errors.txt`
3. View kernel messages: `journalctl -k -n 20` → save to `~/servicelab/kernel_messages.txt`

## Task 3 — Create a simple service unit

Create a custom service unit file at `/etc/systemd/system/hello.service` with this content:

```ini
[Unit]
Description=Hello World Service

[Service]
Type=oneshot
ExecStart=/bin/echo "Hello from systemd"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Then run:
```bash
sudo systemctl daemon-reload
sudo systemctl start hello.service
systemctl status hello.service
```

Save the status output to `~/servicelab/hello_status.txt`.

## Task 4 — Analyze boot

Run `systemd-analyze` and save to `~/servicelab/boot_time.txt`. Then run `systemd-analyze blame | head -10` and save to `~/servicelab/boot_blame.txt`.

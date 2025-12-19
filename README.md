# Comet Jiggler Scheduler

Automated mouse jiggler scheduling for GL-iNet Comet (GL-RM1) KVM devices.

Schedule the built-in PiKVM mouse jiggler to activate during configurable hours. Runs entirely on the Comet device — no software required on the connected computer.

## Features

- **Device-based** — Runs on the Comet itself, not the connected PC
- **Transparent** — Appears as normal USB HID input to the host
- **Scheduled** — Cron-based automation with configurable work hours
- **Persistent** — Survives device reboots
- **Simple** — One-command installation with interactive prompts
- **Stealth** — No detectable processes, tasks, or network traffic on the host

## Requirements

- GL-iNet Comet (GL-RM1) with SSH access enabled
- Admin password from initial device setup
- SSH client (PuTTY, Terminal, etc.)

## Quick Install

SSH into your Comet and run:

\`\`\`bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/comet-jiggler-scheduler/main/install.sh | sh
\`\`\`

Or with curl:

\`\`\`bash
curl -sL https://raw.githubusercontent.com/YOUR_USERNAME/comet-jiggler-scheduler/main/install.sh | sh
\`\`\`

## Manual Install

1. SSH into your Comet:
\`\`\`bash
ssh root@glkvm.local
# Or: ssh root@<device_ip>
\`\`\`

2. Download and run installer:
\`\`\`bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/comet-jiggler-scheduler/main/install.sh
chmod +x install.sh
./install.sh
\`\`\`

## Configuration

The installer prompts for the following options:

| Option | Default | Description |
|--------|---------|-------------|
| Admin password | (required) | Your Comet web UI password |
| Start time | \`07:30\` | When jiggler activates (24-hour format) |
| End time | \`17:00\` | When jiggler deactivates (24-hour format) |
| Days | \`1-5\` | Cron day format (1-5 = Mon-Fri) |

### Day Format Examples

| Value | Days |
|-------|------|
| \`1-5\` | Monday through Friday |
| \`1-6\` | Monday through Saturday |
| \`0-6\` | Every day |
| \`1,3,5\` | Monday, Wednesday, Friday |
| \`0\` or \`7\` | Sunday only |

## Usage

After installation, the jiggler runs automatically on schedule. Manual control:

### Enable Jiggler
\`\`\`bash
/usr/local/bin/toggle_jiggler.sh enable
\`\`\`

### Disable Jiggler
\`\`\`bash
/usr/local/bin/toggle_jiggler.sh disable
\`\`\`

### Check Status
\`\`\`bash
/usr/local/bin/toggle_jiggler.sh status
\`\`\`

### View Logs
\`\`\`bash
cat /var/log/mousejiggler.log
\`\`\`

### View Cron Schedule
\`\`\`bash
crontab -l
\`\`\`

## How It Works

1. **Cron scheduler** runs on the Comet at configured times
2. **API call** to PiKVM enables/disables the built-in mouse jiggler
3. **HID events** sent to connected PC via USB (tiny mouse movements every 60 seconds)
4. **Applications** (Teams, Slack, etc.) detect activity and maintain "Available" status

### Why It's Undetectable

- No software installed on the host PC
- No running processes on Windows/Mac/Linux
- No scheduled tasks on the host
- No network traffic from the host
- Mouse movements appear as genuine USB HID input
- Task Manager shows nothing unusual

## Troubleshooting

### Check if cron is running
\`\`\`bash
ps aux | grep crond
\`\`\`

### Manually start cron
\`\`\`bash
/usr/sbin/crond
\`\`\`

### Verify script permissions
\`\`\`bash
ls -l /usr/local/bin/toggle_jiggler.sh
# Should show: -rwx------ (700)
\`\`\`

### Test API directly
\`\`\`bash
# Check jiggler state
curl -sk -u admin:YOUR_PASSWORD https://localhost/api/hid/jiggler | grep jiggler

# Enable manually
curl -sk -X POST -u admin:YOUR_PASSWORD "https://localhost/api/hid/jiggler?enabled=true"

# Disable manually
curl -sk -X POST -u admin:YOUR_PASSWORD "https://localhost/api/hid/jiggler?enabled=false"
\`\`\`

### Common Issues

| Problem | Solution |
|---------|----------|
| 403 Forbidden | Check admin password in script |
| Connection refused | Verify Comet is responsive, restart if needed |
| Jiggler not working | Ensure USB HID connection is active in web UI |
| Teams still shows Away | Check if org policy enforces stricter timeout |

## Uninstall

SSH into your Comet and run:

\`\`\`bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/comet-jiggler-scheduler/main/uninstall.sh | sh
\`\`\`

Or manually:

\`\`\`bash
# Disable jiggler
/usr/local/bin/toggle_jiggler.sh disable

# Remove cron jobs
crontab -l | grep -v toggle_jiggler | crontab -

# Remove script and logs
rm -f /usr/local/bin/toggle_jiggler.sh
rm -f /var/log/mousejiggler.log
\`\`\`

## After Firmware Updates

Custom configurations may be lost during Comet firmware updates. Simply re-run the installer:

\`\`\`bash
./install.sh
\`\`\`

## Security Notes

- Password stored in \`/usr/local/bin/toggle_jiggler.sh\` with \`700\` permissions (root only)
- All API calls use localhost — no external network exposure
- Script runs as root via cron

## License

MIT

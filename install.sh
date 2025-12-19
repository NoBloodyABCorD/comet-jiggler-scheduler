#!/bin/sh
# Comet Jiggler Scheduler Installer

set -e

echo "========================================"
echo "  Comet Jiggler Scheduler Installer"
echo "========================================"
echo ""

# Check if running interactively or via pipe
if [ -t 0 ]; then
    printf "Enter admin password: "
    stty -echo
    read ADMIN_PASS
    stty echo
    echo ""
else
    echo "ERROR: This script must be run interactively (not piped)."
    echo "Download and run it directly instead:"
    echo "  wget https://raw.githubusercontent.com/NoBloodyABCorD/comet-jiggler-scheduler/main/install.sh"
    echo "  chmod +x install.sh"
    echo "  ./install.sh"
    exit 1
fi

printf "Start time (HH:MM, default 07:30): "
read START_TIME
START_TIME=${START_TIME:-07:30}

printf "End time (HH:MM, default 17:00): "
read END_TIME
END_TIME=${END_TIME:-17:00}

printf "Days (cron format, default 1-5 for Mon-Fri): "
read DAYS
DAYS=${DAYS:-1-5}

START_HOUR=$(echo $START_TIME | cut -d: -f1)
START_MIN=$(echo $START_TIME | cut -d: -f2)
END_HOUR=$(echo $END_TIME | cut -d: -f1)
END_MIN=$(echo $END_TIME | cut -d: -f2)

echo ""
echo "Configuration:"
echo "  Start: $START_TIME on days $DAYS"
echo "  End:   $END_TIME on days $DAYS"
echo ""

echo "[1/4] Setting up cron infrastructure..."
mkdir -p /etc/crontabs /var/spool/cron/ 2>/dev/null || true
ln -sf /etc/crontabs /var/spool/cron/crontabs 2>/dev/null || true

cat > /etc/init.d/S99cron_setup << 'INITEOF'
#!/bin/sh
mkdir -p /etc/crontabs /var/spool/cron/
ln -sf /etc/crontabs /var/spool/cron/crontabs
/usr/sbin/crond -f &
INITEOF
chmod +x /etc/init.d/S99cron_setup

if ! pgrep -x crond > /dev/null; then
    /usr/sbin/crond
fi
echo "    Done."

echo "[2/4] Creating control script..."
mkdir -p /usr/local/bin

cat > /usr/local/bin/toggle_jiggler.sh << SCRIPTEOF
#!/bin/sh
PASSWORD="$ADMIN_PASS"
LOGFILE="/var/log/mousejiggler.log"
API_BASE="https://localhost/api"

log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOGFILE"
}

enable_jiggler() {
    RESPONSE=\$(curl -sk -X POST "\$API_BASE/hid/set_params?jiggler=true" \
        -H "X-KVMD-User: admin" \
        -H "X-KVMD-Passwd: \$PASSWORD" 2>&1)
    if echo "\$RESPONSE" | grep -q '"ok".*true'; then
        log "Mouse jiggler enabled"
    else
        log "ERROR enabling jiggler: \$RESPONSE"
    fi
}

disable_jiggler() {
    RESPONSE=\$(curl -sk -X POST "\$API_BASE/hid/set_params?jiggler=false" \
        -H "X-KVMD-User: admin" \
        -H "X-KVMD-Passwd: \$PASSWORD" 2>&1)
    if echo "\$RESPONSE" | grep -q '"ok".*true'; then
        log "Mouse jiggler disabled"
    else
        log "ERROR disabling jiggler: \$RESPONSE"
    fi
}

status_jiggler() {
    curl -sk "\$API_BASE/hid" \
        -H "X-KVMD-User: admin" \
        -H "X-KVMD-Passwd: \$PASSWORD"
}

case "\$1" in
    enable|on|start) enable_jiggler ;;
    disable|off|stop) disable_jiggler ;;
    status) status_jiggler ;;
    *) echo "Usage: \$0 {enable|disable|status}"; exit 1 ;;
esac
SCRIPTEOF

chmod 700 /usr/local/bin/toggle_jiggler.sh
echo "    Done."

echo "[3/4] Configuring cron schedule..."
crontab -l 2>/dev/null | grep -v toggle_jiggler | grep -v "Comet Jiggler" > /tmp/crontab_clean 2>/dev/null || true
cat >> /tmp/crontab_clean << CRONEOF
$START_MIN $START_HOUR * * $DAYS /usr/local/bin/toggle_jiggler.sh enable
$END_MIN $END_HOUR * * $DAYS /usr/local/bin/toggle_jiggler.sh disable
CRONEOF
crontab /tmp/crontab_clean
rm -f /tmp/crontab_clean
echo "    Done."

echo "[4/4] Verifying installation..."
pgrep -x crond > /dev/null && echo "    ✓ Cron running" || echo "    ✗ Cron not running"
[ -x /usr/local/bin/toggle_jiggler.sh ] && echo "    ✓ Script installed" || echo "    ✗ Script missing"
crontab -l 2>/dev/null | grep -q toggle_jiggler && echo "    ✓ Cron configured" || echo "    ✗ Cron not set"

echo ""
echo "Installation complete!"
echo ""
echo "Commands:"
echo "  /usr/local/bin/toggle_jiggler.sh enable"
echo "  /usr/local/bin/toggle_jiggler.sh disable"
echo "  /usr/local/bin/toggle_jiggler.sh status"

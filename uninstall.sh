#!/bin/sh
# Comet Jiggler Scheduler Uninstaller

echo "========================================"
echo "  Comet Jiggler Scheduler Uninstaller"
echo "========================================"
echo ""

echo "[1/3] Disabling jiggler..."
[ -x /usr/local/bin/toggle_jiggler.sh ] && /usr/local/bin/toggle_jiggler.sh disable 2>/dev/null || true
echo "    Done."

echo "[2/3] Removing cron jobs..."
crontab -l 2>/dev/null | grep -v toggle_jiggler | grep -v "Comet Jiggler" > /tmp/crontab_clean
crontab /tmp/crontab_clean
rm -f /tmp/crontab_clean
echo "    Done."

echo "[3/3] Removing script..."
rm -f /usr/local/bin/toggle_jiggler.sh
rm -f /var/log/mousejiggler.log
echo "    Done."

echo ""
echo "Uninstall complete!"

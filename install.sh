#!/usr/bin/env bash
# Script de instalação do Dynamic Workspaces e configuração de atalhos Hyprland-style no KDE Plasma 6.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
APPLET_ID="com.github.enthony.dynamicworkspaces"

echo "=========================================="
echo "  Instalação do Dynamic Workspaces (Plasma 6)"
echo "=========================================="

# 1. Instalação / Atualização do Plasmoid
echo ""
echo "[1/3] Instalando widget no perfil do usuário..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null | grep -q "$APPLET_ID"; then
    echo "  -> Plasmoid já detectado. Atualizando (--upgrade)..."
    kpackagetool6 -t Plasma/Applet --upgrade "$PACKAGE_DIR"
else
    echo "  -> Instalando novo plasmoid (--install)..."
    kpackagetool6 -t Plasma/Applet --install "$PACKAGE_DIR"
fi
echo "  -> Widget instalado com sucesso!"

# 2. Garantir Desktops Virtuais no KWin
echo ""
echo "[2/4] Verificando desktops virtuais no KWin..."
python3 - <<'EOF'
import subprocess
try:
    cmd = ['qdbus-qt6', 'org.kde.KWin', '/VirtualDesktopManager', 'org.kde.KWin.VirtualDesktopManager.count']
    count = int(subprocess.check_output(cmd).decode().strip())
    if count < 5:
        print(f"  -> Apenas {count} desktop(s) detectado(s). Criando até 5 desktops para navegação estilo Hyprland...")
        for i in range(count, 5):
            subprocess.run(['qdbus-qt6', 'org.kde.KWin', '/VirtualDesktopManager', 'org.kde.KWin.VirtualDesktopManager.createDesktop', str(i), f'Desktop {i+1}'])
    else:
        print(f"  -> {count} desktops virtuais detectados.")
except Exception as e:
    print("  -> Aviso ao verificar desktops virtuais:", e)
EOF

# 3. Configuração de Atalhos (Estilo Hyprland)
echo ""
echo "[3/4] Configurando atalhos de teclado (Win+1..9)..."

# 2.1 Desativa os atalhos Win+1..9 da barra de tarefas (plasmashell)
echo "  -> Liberando atalhos Win+1..9 da barra de tarefas..."
for i in {1..9}; do
    kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry $i" "none,none,Activate Task Manager Entry $i"
done

# 2.2 Associa Win+1..9 para alternar diretamente entre os Desktops Virtuais no KWin
echo "  -> Mapeando Win+1..9 para trocar de workspace no KWin..."
for i in {1..9}; do
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop $i" "Meta+$i,none,Switch to Desktop $i"
done

# 4. Aplicar / Recarregar configurações imediatamente na sessão ativa
echo ""
echo "[4/4] Aplicando atalhos em tempo real no KWin/Plasma..."
python3 - <<'EOF'
import gi
from gi.repository import Gio, GLib

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
META = 0x10000000
KEY_0 = 0x30

for i in range(1, 10):
    # Desativa atalho do task manager
    action_plasma = ['plasmashell', f'activate task manager entry {i}', 'plasmashell', f'Activate Task Manager Entry {i}']
    bus.call_sync(
        'org.kde.kglobalaccel',
        '/kglobalaccel',
        'org.kde.KGlobalAccel',
        'setShortcutKeys',
        GLib.Variant('(asa(ai)u)', (action_plasma, [], 4)),
        GLib.VariantType('(a(ai))'),
        Gio.DBusCallFlags.NONE,
        -1,
        None
    )

    # Atribui Win+i para trocar de desktop no KWin
    key_code = META | (KEY_0 + i)
    action_kwin = ['kwin', f'Switch to Desktop {i}', 'KWin', f'Switch to Desktop {i}']
    bus.call_sync(
        'org.kde.kglobalaccel',
        '/kglobalaccel',
        'org.kde.KGlobalAccel',
        'setShortcutKeys',
        GLib.Variant('(asa(ai)u)', (action_kwin, [([key_code],)], 4)),
        GLib.VariantType('(a(ai))'),
        Gio.DBusCallFlags.NONE,
        -1,
        None
    )
EOF

echo ""
echo "=========================================="
echo "  Instalação concluída com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Adicione o widget ao seu painel: clique com o botão direito no painel -> 'Adicionar Widgets' -> 'Workspaces Dinâmicas'."
echo "2. Pressione Win+1, Win+2, Win+3... para testar a troca de workspaces!"

#!/usr/bin/env bash
# Script de instalação do Dynamic Workspaces e configuração de atalhos no KDE Plasma 6.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$SCRIPT_DIR/package"
KWIN_SCRIPT_DIR="$SCRIPT_DIR/kwin-script"
APPLET_ID="com.github.enthony.dynamicworkspaces"
KWIN_SCRIPT_ID="com.github.enthony.followwindow"

echo "=========================================="
echo "  Instalação do Dynamic Workspaces (Plasma 6)"
echo "=========================================="

# 1. Instalação / Atualização do Plasmoid
echo ""
echo "[1/6] Instalando widget no perfil do usuário..."
if kpackagetool6 -t Plasma/Applet --list 2>/dev/null | grep -q "$APPLET_ID"; then
    echo "  -> Plasmoid já detectado. Atualizando (--upgrade)..."
    kpackagetool6 -t Plasma/Applet --upgrade "$PACKAGE_DIR"
else
    echo "  -> Instalando novo plasmoid (--install)..."
    kpackagetool6 -t Plasma/Applet --install "$PACKAGE_DIR"
fi
echo "  -> Widget instalado com sucesso!"

# 2. Instalação / Atualização do Script KWin (Follow Window ao mover workspace)
echo ""
echo "[2/6] Instalando script KWin (acompanhar janela ao mover de workspace)..."
if kpackagetool6 -t KWin/Script --list 2>/dev/null | grep -q "$KWIN_SCRIPT_ID"; then
    echo "  -> Script KWin já detectado. Atualizando (--upgrade)..."
    kpackagetool6 -t KWin/Script --upgrade "$KWIN_SCRIPT_DIR"
else
    echo "  -> Instalando novo script KWin (--install)..."
    kpackagetool6 -t KWin/Script --install "$KWIN_SCRIPT_DIR"
fi
kwriteconfig6 --file kwinrc --group Plugins --key "${KWIN_SCRIPT_ID}Enabled" "true"
echo "  -> Script KWin instalado e ativado com sucesso!"

# 3. Garantir Desktops Virtuais no KWin
echo ""
echo "[3/6] Verificando desktops virtuais no KWin..."
python3 - <<'EOF'
import subprocess
try:
    cmd = ['qdbus-qt6', 'org.kde.KWin', '/VirtualDesktopManager', 'org.kde.KWin.VirtualDesktopManager.count']
    count = int(subprocess.check_output(cmd).decode().strip())
    if count < 10:
        print(f"  -> Apenas {count} desktop(s) detectado(s). Criando até 10 desktops para navegação estilo Hyprland...")
        for i in range(count, 10):
            subprocess.run(['qdbus-qt6', 'org.kde.KWin', '/VirtualDesktopManager', 'org.kde.KWin.VirtualDesktopManager.createDesktop', str(i), f'Desktop {i+1}'])
    else:
        print(f"  -> {count} desktops virtuais detectados.")
except Exception as e:
    print("  -> Aviso ao verificar desktops virtuais:", e)
EOF

# 4. Configuração de Atalhos (Estilo Hyprland)
echo ""
echo "[4/6] Configurando atalhos de teclado (Win+1..0 e Win+Shift+1..0)..."

# 4.1 Desativa os atalhos Win+1..0 da barra de tarefas (plasmashell)
echo "  -> Liberando atalhos Win+1..0 da barra de tarefas..."
for i in {1..10}; do
    kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "activate task manager entry $i" "none,none,Activate Task Manager Entry $i"
done

# 4.2 Associa Win+1..0 para alternar workspaces no KWin
echo "  -> Mapeando Win+1..0 para alternar workspaces no KWin..."
for i in {1..10}; do
    num=$(( i == 10 ? 0 : i ))
    kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Switch to Desktop $i" "Meta+$num,none,Switch to Desktop $i"
done

# 5. Aplicar / Recarregar configurações imediatamente na sessão ativa
echo ""
echo "[5/6] Aplicando atalhos em tempo real no KWin/Plasma..."
python3 - <<'EOF'
import subprocess
import gi
from gi.repository import Gio, GLib

bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
META = 0x10000000
SHIFT = 0x02000000
KEY_0 = 0x30

# Mapeamento de símbolos quando Shift é pressionado com números no Wayland (layout US e ABNT2):
# No Wayland/XKB, caracteres não-alfabéticos consomem o Shift e o KWin despacha o evento
# como Meta + Símbolo (ex: Meta+! ao invés de Meta+Shift+1). Mapeamos ambos os formatos para total compatibilidade.
symbols_data = {
    1: {"num": 1, "syms": [(0x21, "!")]},
    2: {"num": 2, "syms": [(0x40, "@")]},
    3: {"num": 3, "syms": [(0x23, "#")]},
    4: {"num": 4, "syms": [(0x24, "$")]},
    5: {"num": 5, "syms": [(0x25, "%")]},
    6: {"num": 6, "syms": [(0x5e, "^"), (0xa8, "¨")]},
    7: {"num": 7, "syms": [(0x26, "&")]},
    8: {"num": 8, "syms": [(0x2a, "*")]},
    9: {"num": 9, "syms": [(0x28, "(")]},
    10: {"num": 0, "syms": [(0x29, ")")]},
}

for i in range(1, 11):
    num = symbols_data[i]["num"]

    # Desativa atalho do task manager
    action_plasma = ['plasmashell', f'activate task manager entry {i}', 'plasmashell', f'Activate Task Entry {i}']
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

    # Atribui Win+num para trocar de desktop no KWin
    key_code_switch = META | (KEY_0 + num)
    action_switch = ['kwin', f'Switch to Desktop {i}', 'KWin', f'Switch to Desktop {i}']
    bus.call_sync(
        'org.kde.kglobalaccel',
        '/kglobalaccel',
        'org.kde.KGlobalAccel',
        'setShortcutKeys',
        GLib.Variant('(asa(ai)u)', (action_switch, [([key_code_switch],)], 4)),
        GLib.VariantType('(a(ai))'),
        Gio.DBusCallFlags.NONE,
        -1,
        None
    )

    # Prepara todas as combinações possíveis para mover janelas (Win+Shift+num e Win+símbolo)
    codes = [META | SHIFT | (KEY_0 + num)]
    strings = [f'Meta+Shift+{num}']
    for code, char in symbols_data[i]["syms"]:
        codes.append(META | code)
        codes.append(META | SHIFT | code)
        strings.append(f'Meta+{char}')
        strings.append(f'Meta+Shift+{char}')

    # Deduplica mantendo a ordem
    seen_c = set()
    uniq_codes = [c for c in codes if not (c in seen_c or seen_c.add(c))]
    seen_s = set()
    uniq_strings = [s for s in strings if not (s in seen_s or seen_s.add(s))]

    # Registra no KWin em tempo real via D-Bus
    dbus_keys = [([c],) for c in uniq_codes]
    action_move = ['kwin', f'Window to Desktop {i}', 'KWin', f'Window to Desktop {i}']
    bus.call_sync(
        'org.kde.kglobalaccel',
        '/kglobalaccel',
        'org.kde.KGlobalAccel',
        'setShortcutKeys',
        GLib.Variant('(asa(ai)u)', (action_move, dbus_keys, 4)),
        GLib.VariantType('(a(ai))'),
        Gio.DBusCallFlags.NONE,
        -1,
        None
    )

    # Persiste no kglobalshortcutsrc com suporte a múltiplas variantes separadas por tab
    shortcut_str = '\t'.join(uniq_strings) + f',none,Window to Desktop {i}'
    subprocess.run(['kwriteconfig6', '--file', 'kglobalshortcutsrc', '--group', 'kwin', '--key', f'Window to Desktop {i}', shortcut_str])
EOF

# 6. Reiniciar o Plasmashell para recarregar o widget atualizado na barra e recarregar o KWin
echo ""
echo "[6/6] Reiniciando painéis do Plasma e recarregando o KWin..."
if systemctl --user is-active --quiet plasma-plasmashell.service; then
    systemctl --user restart plasma-plasmashell.service
    echo "  -> Plasmashell reiniciado com sucesso via systemd."
else
    kquitapp6 plasmashell 2>/dev/null || killall plasmashell 2>/dev/null || true
    kstart plasmashell 2>/dev/null || true
    echo "  -> Plasmashell reiniciado."
fi

# Reconfigurar KWin para assegurar que scripts, atalhos e regras sejam aplicados
if command -v qdbus-qt6 >/dev/null 2>&1; then
    qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
    echo "  -> KWin reconfigurado com sucesso."
fi

echo ""
echo "=========================================="
echo "  Instalação concluída com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Se o widget já estava no painel superior, ele foi recarregado e agora se ajusta perfeitamente à barra (sem cortes)."
echo "2. Pressione Win+1..9 e Win+0 para alternar entre as 10 workspaces."
echo "3. Pressione Win+Shift+1..9 e Win+Shift+0 com uma janela ativa para movê-la e segui-la automaticamente para a nova workspace!"

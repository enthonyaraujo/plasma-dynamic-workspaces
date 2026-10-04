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

# 2. Configuração de Atalhos (Estilo Hyprland)
echo ""
echo "[2/3] Configurando atalhos de teclado (Win+1..9)..."

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

# 3. Aplicar / Recarregar configurações
echo ""
echo "[3/3] Recarregando atalhos no Plasma e KWin..."
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
if command -v qdbus-qt6 >/dev/null 2>&1; then
    qdbus-qt6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
elif command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin reconfigure 2>/dev/null || true
fi

echo ""
echo "=========================================="
echo "  Instalação concluída com sucesso!"
echo "=========================================="
echo ""
echo "Próximos passos:"
echo "1. Adicione o widget ao seu painel: clique com o botão direito no painel -> 'Adicionar Widgets' -> 'Workspaces Dinâmicas'."
echo "2. Pressione Win+1, Win+2, Win+3... para testar a troca de workspaces!"

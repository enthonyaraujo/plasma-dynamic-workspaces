# Dynamic Workspaces (Plasmoid para KDE Plasma 6)

Widget (plasmoid) para o KDE Plasma 6 que replica o comportamento de workspaces dinâmicas do **Hyprland**: exibe apenas as workspaces que estão ativas ou que contêm janelas abertas, recolhendo e expandindo a lista automaticamente conforme o uso.

---

## Comportamento e Recursos

1. **Workspaces Dinâmicas**:
   - Inicialmente, exibe apenas a workspace persistente configurada (padrão: `[1]`).
   - Ao navegar para outra workspace (ex.: Meta+2), a nova workspace aparece em destaque (`[1] [2]`).
   - Ao trocar para uma workspace vazia seguinte (ex.: `[3]`), a workspace intermediária vazia (`[2]`) desaparece automaticamente (`[1] [3]`).
   - Se a workspace intermediária contiver ao menos uma janela aberta, ela permanece visível com opacidade reduzida (`[1] [2] [3]`).
2. **Estilo e Tematização Plasma**:
   - Workspace ativa: cor de destaque do tema (`Kirigami.Theme.highlightColor`) e texto de alto contraste (`highlightedTextColor`).
   - Workspaces inativas com janelas: opacidade intermediária (`0.6`) e cor de texto do tema.
   - Workspaces vazias persistentes: opacidade reduzida (`0.35`).
   - Efeito hover suave.
   - Transições de opacidade e animação discreta de reposicionamento (`Flow.move Transition`), sem saltos visuais bruscos.
3. **Interação**:
   - Clique em qualquer workspace para alternar para ela imediatamente (via D-Bus do KWin).
   - Tooltips com o nome real de cada desktop virtual configurado no Plasma.
   - **Acompanhar janela ao mover (Estilo Hyprland `movetoworkspace`)**: ao usar `Win+Shift+1..0`, a janela ativa é movida para a workspace escolhida e a visualização do desktop segue imediatamente junto com ela.
4. **Desempenho Reativo (Zero Polling)**:
   - Não utiliza timers nem loops de verificação.
   - Usa diretamente os modelos reativos `org.kde.taskmanager` (`VirtualDesktopInfo`, `ActivityInfo`, `TasksModel`) e `org.kde.kitemmodels` (`KSortFilterProxyModel`).
   - Filtra automaticamente janelas fixadas em todas as telas ("pinned on all desktops"), evitando falsos positivos de ocupação.

---

## Multi-Monitor: Análise Técnica e Limitações

### Situação no KDE Plasma
Na arquitetura tradicional do KDE Plasma (incluindo o Plasma 6.0 a 6.6), os **Desktops Virtuais são globais** e compartilhados entre todos os monitores conectados. Ou seja, ao trocar de workspace, todos os monitores alternam juntos.

O suporte nativo a workspaces totalmente independentes por monitor (*per-output virtual desktops*, como no Hyprland) foi desenhado e implementado no KWin para o **Plasma 6.7+** (disponível apenas sob Wayland via opção em *Configurações do Sistema > Gerenciamento de Janelas > Desktops Virtuais > Alternar desktop independentemente para cada tela*).

### Como o widget lida com Multi-Monitor
- **Modo Padrão (Global)**: O widget rastreia a workspace ativa global e janelas abertas em qualquer tela para cada desktop.
- **Opção por Monitor (Filtro de Tela)**: Nas configurações do widget (*Configurar Workspaces Dinâmicas > Multi-monitor*), é possível marcar **"Apenas contar janelas nesta tela"** (`filterByScreen`). Quando ativado, a instância do widget em cada painel considerará ocupada apenas a workspace que contém janelas na tela onde aquele painel específico reside (`screenGeometry`).

---

## Estrutura do Código

```text
kde-workspace/
├── package/                          # Plasmoid (Widget para o Painel do Plasma 6)
│   ├── metadata.json                 # Metadados do Plasmoid (Plasma 6, Applet)
│   └── contents/
│       ├── config/
│       │   ├── config.qml            # Registro de páginas de configuração
│       │   └── main.xml              # Schema KConfig (persistentWorkspaces, filterByScreen)
│       └── ui/
│           ├── main.qml              # Entrada principal, Flow e D-Bus KWin
│           ├── DesktopOccupancy.qml  # Modelo reativo de ocupação por workspace (TasksModel)
│           ├── WorkspaceButton.qml   # Componente visual da pílula / botão de workspace
│           └── configGeneral.qml     # Interface de preferências gerais
├── kwin-script/                      # Script do KWin 6 (movetoworkspace & follow)
│   ├── metadata.json                 # Metadados do KWin Script
│   └── contents/
│       └── code/
│           └── main.js               # Handler que segue a janela ativa ao mudar de desktop
└── README.md
```

---

## Instalação

### Instalação Rápida (Script Automatizado)

Você pode instalar o widget e configurar automaticamente os atalhos `Win+1..0` (alternar workspace) e `Win+Shift+1..0` (mover janela ativa e acompanhá-la) para até 10 workspaces executando o script incluído:

```bash
./install.sh
```

O script:
1. Instala (ou atualiza) o widget no perfil do usuário (`~/.local/share/plasma/plasmoids/`).
2. Instala e ativa o script KWin que acompanha a janela ativa para o desktop de destino (`~/.local/share/kwin/scripts/`).
3. Garante a criação de até 10 desktops virtuais no KWin.
4. Libera os atalhos `Win+1..0` da barra de tarefas do Plasma.
5. Atribui `Win+1..9` e `Win+0` para alternar diretamente entre as 10 workspaces.
6. Atribui `Win+Shift+1..9` e `Win+Shift+0` para mover a janela ativa para qualquer uma das 10 workspaces (com suporte completo a Wayland e layouts US/ABNT2).
7. Aplica as configurações em tempo real na sessão ativa via D-Bus e reinicia o Plasmashell.

---

### Instalação Manual via `kpackagetool6`

Caso prefira fazer manualmente a partir da raiz do repositório:

```bash
# Instalação inicial
kpackagetool6 -t Plasma/Applet --install package

# Se já estiver instalado e você quiser atualizar após alterações:
kpackagetool6 -t Plasma/Applet --upgrade package
```

Os arquivos serão instalados em `~/.local/share/plasma/plasmoids/com.github.enthony.dynamicworkspaces/`.

### Adicionar ao painel
1. Clique com o botão direito no painel do Plasma e selecione **"Entrar no Modo de Edição"** (ou **"Adicionar Widgets..."**).
2. Procure por **"Workspaces Dinâmicas"** (ou "Dynamic Workspaces").
3. Arraste o widget para a posição desejada no painel.

### Desinstalar

#### Desinstalação Automática
Para remover o widget, o script KWin e restaurar os atalhos originais da barra de tarefas:

```bash
./uninstall.sh
```

#### Desinstalação Manual
```bash
# Remover widget
kpackagetool6 -t Plasma/Applet --remove com.github.enthony.dynamicworkspaces

# Remover script KWin
kpackagetool6 -t KWin/Script --remove com.github.enthony.followwindow
```

---

## Como Testar

### 1. Teste rápido em janela isolada (`plasmawindowed`)
No Plasma 6, a ferramenta padrão instalada pelo pacote `plasma-workspace` é o `plasmawindowed`:

```bash
plasmawindowed com.github.enthony.dynamicworkspaces
```

*(Nota: se o pacote de desenvolvimento `plasma-sdk` estiver instalado no seu sistema, o comando `plasmoidviewer -a com.github.enthony.dynamicworkspaces` também pode ser utilizado).*

### 2. Testar troca dinâmica de workspaces e movimentação de janelas
1. Abra o widget (ou adicione-o ao seu painel).
2. Com apenas a workspace 1 em uso, somente o botão `[1]` estará visível.
3. Pressione `Meta+2` (ou use os atalhos `Win+1..0`): o botão `[2]` aparecerá em destaque e o `[1]` ficará esmaecido.
4. Pressione `Meta+3`: o botão `[2]` desaparecerá automaticamente e o `[3]` estará ativo.
5. Abra uma janela no Desktop 2 (ex.: terminal ou editor de texto) e volte para o Desktop 1 ou 3: o botão `[2]` permanecerá visível indicando que há janelas ativas naquele desktop.
6. Pressione `Win+Shift+n` (onde `n` é de 1 a 0, correspondendo aos desktops 1 a 10) com uma janela focada para movê-la para a workspace desejada e segui-la automaticamente.
7. Clique diretamente em qualquer botão do widget com o mouse para trocar de desktop.

---

## O que ficou de fora ou com limitações

1. **Independência total de desktops por tela antes do Plasma 6.7**:
   - No Plasma 6.6 e anteriores, o KWin não desacopla o índice do desktop virtual ativo por saída (output). Portanto, ao alternar de desktop, a tela toda alterna. O widget oferece o filtro de contagem de janelas por tela (`filterByScreen`), mas a workspace ativa continua sendo compartilhada entre os monitores no KWin < 6.7.
2. **Criação dinâmica sob demanda no compositor**:
   - O widget exibe dinamicamente as workspaces que já existem no KWin (criadas pelo usuário ou padrão do sistema). Ele não deleta nem recria desktops virtuais no arquivo de configuração do sistema a cada fechamento de janela para evitar poluição no `kwinrc` e perda de atalhos globais de teclado (Meta+1, Meta+2, etc.).
3. **Janelas presentes em todos os desktops**:
   - Janelas marcadas como "Visível em todos os desktops virtuais" são filtradas intencionalmente para não forçar todas as workspaces a ficarem visíveis o tempo todo.

---

## Licença

Distribuído sob a licença **GNU General Public License v2.0 ou posterior**. Consulte o arquivo [LICENSE](LICENSE) para obter o texto completo da licença.

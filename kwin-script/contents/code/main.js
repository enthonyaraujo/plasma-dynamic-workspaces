/*
    SPDX-FileCopyrightText: 2026 Enthony Araujo de Oliveira <enthonyaraujo01@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

function hookWindow(w) {
    if (!w || w.specialWindow) {
        return;
    }

    w.desktopsChanged.connect(function() {
        if (w.onAllDesktops) {
            return;
        }
        if (!w.desktops || w.desktops.length === 0) {
            return;
        }

        var targetDesktop = w.desktops[0];
        // Se a janela que mudou de desktop era a janela ativa, acompanha a visualização
        if (workspace.currentDesktop !== targetDesktop && workspace.activeWindow === w) {
            workspace.currentDesktop = targetDesktop;
            workspace.activeWindow = w;
        }
    });
}

// Conecta janelas existentes
var windows = workspace.windowList();
for (var i = 0; i < windows.length; i++) {
    hookWindow(windows[i]);
}

// Conecta janelas abertas futuramente
workspace.windowAdded.connect(hookWindow);

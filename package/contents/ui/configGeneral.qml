/*
    SPDX-FileCopyrightText: 2026 Enthony Araujo de Oliveira <enthonyaraujo01@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kcmutils as KCM
import org.kde.kirigami as Kirigami

KCM.SimpleKCM {
    property alias cfg_persistentWorkspaces: persistentSpin.value
    property alias cfg_filterByScreen: filterByScreenCheck.checked

    // Injected by Plasma for "Defaults" handling; declared to avoid warnings.
    property int cfg_persistentWorkspacesDefault
    property bool cfg_filterByScreenDefault

    Kirigami.FormLayout {
        QQC2.SpinBox {
            id: persistentSpin
            Kirigami.FormData.label: i18n("Always visible workspaces:")
            from: 0
            to: 20
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("The first N workspaces stay visible even when empty. The active workspace is always shown.")
            wrapMode: Text.WordWrap
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        QQC2.CheckBox {
            id: filterByScreenCheck
            Kirigami.FormData.label: i18n("Multi-monitor:")
            text: i18n("Only count windows on this widget's screen")
        }
    }
}

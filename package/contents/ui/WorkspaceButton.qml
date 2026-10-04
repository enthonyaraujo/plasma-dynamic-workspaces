/*
    SPDX-FileCopyrightText: 2026 Enthony Araujo de Oliveira <enthonyaraujo01@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.core as PlasmaCore

/*
 * One workspace "pill". Pure presentation: it receives its state and emits
 * activated() on click; it knows nothing about desktops or windows.
 */
Item {
    id: button

    property string label
    property string desktopName
    property bool active: false
    property bool occupied: false
    property bool shown: true
    property bool vertical: false
    property real panelThickness: 24

    signal activated()

    // Opacity levels: active > inactive with windows > persistent but empty.
    readonly property real targetOpacity: active ? 1.0 : (occupied ? 0.7 : 0.4)

    // Calculate pill thickness from the panel thickness with safety margins.
    // For a 24px panel, pillThickness is 20px, leaving 2px top/bottom margin.
    readonly property real effectivePanelThickness: panelThickness > 0 ? panelThickness : (vertical ? width : height)
    readonly property real safePanelThickness: effectivePanelThickness > 0 ? effectivePanelThickness : Kirigami.Units.gridUnit * 1.5
    readonly property real pillThickness: Math.max(16, Math.min(safePanelThickness - 4, Kirigami.Units.gridUnit * 1.5))
    readonly property real pillLength: Math.max(pillThickness, labelItem.implicitWidth + 2 * Kirigami.Units.smallSpacing)

    visible: shown
    opacity: shown ? (mouseArea.containsMouse && !active ? Math.min(1.0, targetOpacity + 0.25) : targetOpacity) : 0

    width: shown ? (vertical ? pillThickness : pillLength) : 0
    height: shown ? (vertical ? pillLength : pillThickness) : 0
    implicitWidth: width
    implicitHeight: height

    Behavior on opacity {
        NumberAnimation {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: button.desktopName
    Accessible.description: button.active ? i18n("Current workspace") : i18n("Switch to this workspace")
    Accessible.onPressAction: button.activated()

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: button.vertical ? button.pillThickness : button.pillLength
        height: button.vertical ? button.pillLength : button.pillThickness
        radius: Math.min(width, height) / 2

        color: button.active ? Kirigami.Theme.highlightColor
             : mouseArea.containsMouse ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                                 Kirigami.Theme.textColor.b, 0.15)
             : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }

        PlasmaComponents.Label {
            id: labelItem
            anchors.centerIn: parent
            text: button.label
            font.bold: button.active
            font.pixelSize: Math.max(9, Math.round(button.pillThickness * 0.55))
            color: button.active ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
        }
    }

    PlasmaCore.ToolTipArea {
        anchors.fill: parent
        mainText: button.desktopName
        subText: button.active ? i18n("Current workspace") : ""

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onClicked: button.activated()
        }
    }
}

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

    signal activated()

    // Opacity levels: active > inactive with windows > persistent but empty.
    readonly property real targetOpacity: active ? 1.0 : (occupied ? 0.6 : 0.35)

    readonly property real thickness: vertical ? width : height
    readonly property real pillThickness: Math.max(0, Math.min(thickness - 2 * Kirigami.Units.smallSpacing,
                                                                Kirigami.Units.iconSizes.medium))
    readonly property real pillLength: Math.max(pillThickness,
                                                labelItem.implicitWidth + 3 * Kirigami.Units.smallSpacing)

    visible: shown
    // While hidden the opacity rests at 0, so showing the item fades it in.
    opacity: shown ? (mouseArea.containsMouse && !active ? Math.min(1, targetOpacity + 0.2) : targetOpacity) : 0

    width: shown ? (vertical ? Kirigami.Units.gridUnit * 2 : pillLength) : 0
    height: shown ? (vertical ? pillLength : Kirigami.Units.gridUnit * 2) : 0
    implicitWidth: width
    implicitHeight: height

    Layout.fillWidth: vertical && shown
    Layout.fillHeight: !vertical && shown
    Layout.preferredWidth: width
    Layout.preferredHeight: height

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

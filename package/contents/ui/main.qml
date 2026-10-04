/*
    SPDX-FileCopyrightText: 2026 Enthony Araujo de Oliveira <enthonyaraujo01@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.workspace.dbus as DBus
import org.kde.taskmanager as TaskManager

PlasmoidItem {
    id: root

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property rect screenGeometry: Plasmoid.containment ? Plasmoid.containment.screenGeometry
                                                                 : Qt.rect(0, 0, 0, 0)

    preferredRepresentation: fullRepresentation

    // Thickness of the containing panel (height for horizontal, width for vertical)
    readonly property real panelThickness: vertical ? width : height

    // Forward size and constraints to the panel containment layout
    Layout.fillWidth: vertical
    Layout.fillHeight: !vertical
    Layout.minimumWidth: vertical ? -1 : implicitWidth
    Layout.preferredWidth: vertical ? -1 : implicitWidth
    Layout.maximumWidth: vertical ? -1 : implicitWidth
    Layout.minimumHeight: vertical ? implicitHeight : -1
    Layout.preferredHeight: vertical ? implicitHeight : -1
    Layout.maximumHeight: vertical ? implicitHeight : -1

    implicitWidth: fullRepresentationItem ? fullRepresentationItem.implicitWidth : 0
    implicitHeight: fullRepresentationItem ? fullRepresentationItem.implicitHeight : 0

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // Positions are 1-based and the call works on both Wayland and X11.
    function activateDesktop(position: int) {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin",
            "path": "/KWin",
            "interface": "org.kde.KWin",
            "member": "setCurrentDesktop",
            "arguments": [new DBus.int32(position)],
            "signature": "i"
        });
    }

    function nextDesktop() {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin",
            "path": "/KWin",
            "interface": "org.kde.KWin",
            "member": "nextDesktop"
        });
    }

    function previousDesktop() {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin",
            "path": "/KWin",
            "interface": "org.kde.KWin",
            "member": "previousDesktop"
        });
    }

    fullRepresentation: Item {
        id: barContainer

        implicitWidth: barGrid.implicitWidth
        implicitHeight: barGrid.implicitHeight
        width: implicitWidth
        height: implicitHeight

        WheelHandler {
            orientation: Qt.Vertical
            onWheel: (event) => {
                if (event.angleDelta.y < 0) {
                    root.nextDesktop();
                } else if (event.angleDelta.y > 0) {
                    root.previousDesktop();
                }
            }
        }

        // Grid with 1 row (horizontal) or 1 column (vertical) ensures items never wrap
        // onto a clipped second row, and items with visible: false are automatically ignored.
        Grid {
            id: barGrid

            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            spacing: Kirigami.Units.smallSpacing

            anchors.centerIn: parent

            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: Kirigami.Units.shortDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Repeater {
                model: desktopInfo.desktopIds

                WorkspaceButton {
                    id: workspace

                    required property var modelData
                    required property int index

                    readonly property bool persistent: index < Plasmoid.configuration.persistentWorkspaces

                    vertical: root.vertical
                    panelThickness: root.panelThickness
                    label: String(index + 1)
                    desktopName: desktopInfo.desktopNames[index] ?? label
                    active: String(modelData) === String(desktopInfo.currentDesktop)
                    occupied: occupancy.occupied
                    shown: active || occupied || persistent

                    onActivated: {
                        if (!active) {
                            root.activateDesktop(index + 1);
                        }
                    }

                    DesktopOccupancy {
                        id: occupancy
                        desktopId: workspace.modelData
                        activity: activityInfo.currentActivity
                        filterByScreen: Plasmoid.configuration.filterByScreen && root.screenGeometry.width > 0
                        screenGeometry: root.screenGeometry
                    }
                }
            }
        }
    }
}

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

    TaskManager.VirtualDesktopInfo {
        id: desktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    // VirtualDesktopInfo::requestActivate() is not invokable from QML and the
    // pager's private module is not importable by third-party applets, so the
    // switch goes through KWin's D-Bus API. Positions are 1-based and the call
    // works on both Wayland and X11.
    function activateDesktop(position: int) {
        DBus.SessionBus.asyncCall({
            "service": "org.kde.KWin",
            "path": "/KWin",
            "interface": "org.kde.KWin",
            "member": "setCurrentDesktop",
            "arguments": [new DBus.int32(position)],
            "signature": "(i)"
        });
    }

    fullRepresentation: Flow {
        id: bar

        flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
        spacing: Kirigami.Units.smallSpacing

        // Size to content along the panel so the widget grows/shrinks with the list.
        Layout.minimumWidth: root.vertical ? -1 : implicitWidth
        Layout.preferredWidth: root.vertical ? -1 : implicitWidth
        Layout.maximumWidth: root.vertical ? Infinity : implicitWidth
        Layout.minimumHeight: root.vertical ? implicitHeight : -1
        Layout.preferredHeight: root.vertical ? implicitHeight : -1
        Layout.maximumHeight: root.vertical ? implicitHeight : Infinity

        move: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: Kirigami.Units.shortDuration
                easing.type: Easing.InOutQuad
            }
        }

        // One delegate per desktop. Hidden delegates take no space in the layout,
        // and each one only re-evaluates when its own state changes.
        Repeater {
            model: desktopInfo.desktopIds

            WorkspaceButton {
                id: workspace

                required property var modelData
                required property int index

                readonly property bool persistent: index < Plasmoid.configuration.persistentWorkspaces

                vertical: root.vertical
                label: String(index + 1)
                desktopName: desktopInfo.desktopNames[index] ?? label
                active: modelData === desktopInfo.currentDesktop
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

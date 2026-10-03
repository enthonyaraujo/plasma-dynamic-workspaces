/*
    SPDX-FileCopyrightText: 2026 Enthony Araujo de Oliveira <enthonyaraujo01@gmail.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kitemmodels as KItemModels
import org.kde.taskmanager as TaskManager

/*
 * Reactive answer to "does this virtual desktop contain at least one window?".
 *
 * TasksModel narrows the shared window list down to one desktop (plus the current
 * activity and, optionally, one screen). The proxy on top drops windows pinned to
 * all desktops: they pass every desktop filter and would otherwise keep every
 * workspace visible, which is not how Hyprland treats pinned windows.
 *
 * Everything updates through model signals; nothing is polled.
 */
QtObject {
    id: occupancy

    required property var desktopId
    property string activity
    property bool filterByScreen: false
    property rect screenGeometry

    readonly property bool occupied: windows.count > 0

    readonly property TaskManager.TasksModel tasks: TaskManager.TasksModel {
        groupMode: TaskManager.TasksModel.GroupDisabled
        sortMode: TaskManager.TasksModel.SortDisabled

        filterByVirtualDesktop: true
        virtualDesktop: occupancy.desktopId

        filterByActivity: true
        activity: occupancy.activity

        filterByScreen: occupancy.filterByScreen
        screenGeometry: occupancy.screenGeometry
    }

    readonly property KItemModels.KSortFilterProxyModel windows: KItemModels.KSortFilterProxyModel {
        sourceModel: occupancy.tasks
        // Re-filter rows whenever this role changes (window pinned/unpinned).
        filterRoleName: "IsOnAllVirtualDesktops"
        filterRowCallback: (sourceRow, sourceParent) => {
            const index = occupancy.tasks.index(sourceRow, 0, sourceParent);
            return occupancy.tasks.data(index, TaskManager.AbstractTasksModel.IsWindow) === true
                && occupancy.tasks.data(index, TaskManager.AbstractTasksModel.IsOnAllVirtualDesktops) !== true;
        }
    }
}

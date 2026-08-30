# TaskOS

A native SwiftUI to-do list app for iPad: multiple lists, due dates, priorities,
and a two-column `NavigationSplitView` layout suited to the iPad's wider screen.

## Features

- Multiple task lists, each with a custom color and SF Symbol icon
- Smart views: **Tutte** (all), **Oggi** (due today), **Completate** (completed)
- Tasks with title, notes, optional due date, and priority (low/medium/high)
- Local persistence via SwiftData — no account, no network, no backend

## Requirements

- Xcode 15.2 or newer
- iOS/iPadOS 17.0+ (SwiftData)

## Build & run

Open `TaskOS.xcodeproj` in Xcode, pick an iPad simulator (or a connected iPad),
and hit Run. There is no external dependency to fetch — the project only uses
first-party frameworks (SwiftUI, SwiftData).

## Layout

```
TaskOS/
  TaskOSApp.swift          # entry point, SwiftData model container
  Models/
    TaskList.swift         # a list of tasks (name, icon, color)
    TaskItem.swift          # a single task (title, notes, due date, priority)
  Views/
    ContentView.swift       # NavigationSplitView root
    SidebarView.swift       # lists + smart views, add/rename/delete a list
    ListEditSheet.swift     # create/rename a list (name, color, icon)
    TaskListView.swift      # tasks for the current sidebar selection
    TaskRowView.swift       # one task row, tap to complete
    TaskEditSheet.swift     # create/edit a task
    SidebarItem.swift       # sidebar selection model
    ListColor.swift         # named list colors + SF Symbol choices
```

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.InternalControls.RobotAction 1.0
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

Item {
  id: root
  property var style
  property var actions: []
  property var structure: ({uuid: "root", type: "directory", content: []})
  property real minimumCellWidth: Units.pt(96)
  property real cellHeight: Units.pt(40)
  property bool editable: true
  property Item dragParent: root
  signal structureUpdated
  signal editActionRequested(string uuid)

  onActionsChanged: d.robotActions.reset()


  StackView {
    id: stackView
    anchors.fill: parent

    initialItem: behaviorView
  }

  Component {
    id: behaviorView

    ColumnLayout {
      id: behaviorLayout
      property var modelData: root.structure
      StackView.onRemoved: d.freeStackViewItems()

      Connections {
        target: root
        onStructureChanged: behaviorLayout.modelData = d.getStructureEntry(behaviorLayout.modelData.uuid)
      }

      ToolBar {
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(32)
        visible: !!modelData && modelData.type === "directory" && modelData.uuid !== "root"
        RowLayout {
          anchors.fill: parent

          Item {
            Layout.fillHeight: true
            Layout.preferredWidth: Units.pt(32)
            ToolButton {
              id: backButton
              anchors.fill: parent
              font { family: Style.iconFontFamily }
              text: Style.icons.goBack
              onClicked: d.closeDirectory()
            }
            DropArea {
              id: dropArea
              anchors.fill: backButton
              keys: ["RobotAction"]
              onEntered: leaveDirectoryTimer.restart()
              onExited: leaveDirectoryTimer.stop()
              onDropped: leaveDirectoryTimer.stop()

              Timer {
                id: leaveDirectoryTimer
                interval: 1000
                onTriggered: d.closeDirectory()
              }
            }
          }

          Label {
            Layout.fillWidth: true
            text: modelData && modelData.name || ""
            font: Style.fonts.label
          }
        }
      }

      AutoSizeGridView {
        id: behaviorGrid
        Layout.fillWidth: true
        Layout.fillHeight: true
        cellMinimumWidth: root.minimumCellWidth

        keys: ["RobotAction"]
        onItemMoved: {
          d.handleItemMoved(modelData, from, to)
        }
        onItemDropped: {
          drop.accept()
          if (!!drop.source.model)
            d.moveItemToDirectory(modelData, drop.source.model, index)
          else
            Ros.error("Dropped RobotAction had no model set!")
        }

        previewComponent: Component {
          Item {
            Rectangle { x: Units.pt(4); y: Units.pt(4); width: parent.width - Units.pt(8); height: parent.height - Units.pt(8); color: "gray" }
          }
        }
        model: modelData.content || []
        delegate: Component {
          Item {
            id: delegateRoot
            property var model: modelData
            width: d.tileWidth
            height: root.cellHeight
            // Approach used because of https://stackoverflow.com/questions/24532317/new-drag-and-drop-mechanism-does-not-work-as-expected-in-qt-quick-qt-5-3
            // Does NOT fire dragStarted or dragFinished use dragArea.active instead!
            Drag.dragType: Drag.None
            Drag.keys: ["RobotAction"]

            Menu {
              id: contextMenu
              MenuItem {
                text: "Edit"
                onTriggered: {
                  if (modelData.type !== "directory") root.editActionRequested(modelData.key)
                  else renameDirectoryDialog.show(modelData.uuid)
                }
              }
              MenuItem {
                text: "Delete"
                onTriggered: d.removeStructureEntry(modelData.uuid)
              }
            }

            MouseArea {
              anchors.fill: parent
              anchors.margins: Units.pt(4)
              acceptedButtons: Qt.LeftButton | Qt.RightButton
              propagateComposedEvents: true

              onClicked: {
                if (mouse.button === Qt.RightButton) 
                  contextMenu.popup()
              }

              onPressAndHold: {
                if (mouse.source === Qt.MouseEventNotSynthesized)
                  contextMenu.popup()
              }
            }

            MouseArea {
              id: dragArea
              anchors.fill: parent
              anchors.margins: Units.pt(4)
              drag.target: parent
              drag.filterChildren: true
              propagateComposedEvents: true
              
              DropArea {
                id: dropArea
                anchors.fill: parent
                keys: ["RobotAction"]
                property real lastX
                property real lastY
                onEntered: {
                  if (drag.source == delegateRoot) return
                  actionButton.highlighted = true
                  drag.accept()
                  enterDirectoryTimer.restart()
                  lastX = drag.x
                  lastY = drag.y
                }
                onExited: {
                  actionButton.highlighted = false
                  enterDirectoryTimer.stop()
                }
                onPositionChanged: {
                  if (Math.abs(drag.x - lastX) < Units.pt(4) && Math.abs(drag.y - lastY) < Units.pt(4)) return
                  lastX = drag.x
                  lastY = drag.y
                  enterDirectoryTimer.restart()
                }
                onDropped: {
                  enterDirectoryTimer.stop()
                  if (drop.source == delegateRoot) return
                  actionButton.highlighted = false
                  drop.accept()
                  if (delegateRoot.model.type !== "directory") {
                    d.createDirectory(delegateRoot.model, drop.source.model)
                  } else {
                    d.moveItemToDirectory(delegateRoot.model, drop.source.model)
                  }
                }

                ActionButton {
                  id: actionButton
                  robotAction: delegateRoot.model.type === "directory" ? d.createOpenDirectoryAction(actionButton, delegateRoot.model) : d.robotActions.get(delegateRoot.model.key)
                  anchors.fill: parent
                }

                Timer {
                  id: enterDirectoryTimer
                  interval: 1000
                  onTriggered: {
                    if (delegateRoot.model.type !== "directory") return
                    d.openDirectory(delegateRoot.model)
                  }
                }
              }
            }
            Connections {
              target: dragArea.drag
              property var gridWorkaround: null // For some reason behaviorGrid can't be found after reparenting
              onActiveChanged: {
                if (!gridWorkaround) gridWorkaround = behaviorGrid
                if (dragArea.drag.active) {
                  dropArea.keys = ["IGNORE_GD23"]
                  d.startDrag(dragArea)
                } else {
                  if (d.drop(dragArea) === Qt.IgnoreAction) {
                    // gridWorkaround.relayout()
                  }
                  dropArea.keys = ["RobotAction"]
                }
              }
            }
          }
        }
      }
    }
  }

  Component {
    id: directoryAction
    RobotAction {
      property var model
      name: model.name 
      icon: Style.icons.folder
      type: "javascript"
      evaluateParams: true
      anonymous: true
      params: function () {
        d.openDirectory(model)
      }
    }
  }

  Dialog {
    id: renameDirectoryDialog
    title: "Rename directory"
    parent: ApplicationWindow.overlay
    // Center dialog
    x: parent.x + (parent.width - width) / 2
    y: parent.y + (parent.height - height) / 2
    standardButtons: Dialog.Ok | Dialog.Cancel
    closePolicy: Popup.NoAutoClose
    focus: true
    property var item: null

    TextField {
      id: directoryName
      cursorVisible: focus
      selectByMouse: true
      onTextChanged: renameDirectoryDialog.standardButton(Dialog.Ok).enabled = text !== ''
    }

    function show(uuid) {
      item = d.getStructureEntry(uuid)
      directoryName.text = item.name
      open()
    }

    onAccepted: {
      if (directoryName.text === "") {
        directoryName.focus = true
        renameDirectoryDialog.visible = true
        return
      }
      d.renameDirectory(item.uuid, directoryName.text)
    }
  }

  QtObject {
    id: d
    property var toRemove: []
    property bool dragActive: false
    property Item oldParent: null

    function createOpenDirectoryAction(parent, model) {
      return directoryAction.createObject(parent, {model: model})
    }

    function openDirectory(model) {
      var item = null
      // Try reusing the item if possible during drag navigation
      for (var i = 0; i < toRemove.length; ++i) {
        if (!toRemove[i].modelData || toRemove[i].modelData.uuid !== model.uuid) continue
        item = toRemove[i]
        toRemove.splice(i, 1)
        break
      }
      if (!item) item = behaviorView.createObject(stackView, {modelData: model})
      stackView.push(item)
    }

    function closeDirectory() {
      var item = stackView.pop()
      if (!item) return
      toRemove.push(item)
    }

    function freeStackViewItems() {
      if (dragActive) return
      for (var i = 0; i < toRemove.length; ++i) {
        toRemove[i].destroy()
      }
      toRemove.length = 0 // Clear toRemove list
    }

    function startDrag(dragArea) {
      var item = dragArea.drag.target
      dragActive = true
      var pos = item.mapFromItem(dragArea, dragArea.mouseX, dragArea.mouseY)
      oldParent = item.parent
      item.parent = root.dragParent
      item.Drag.active = true
      item.Drag.hotSpot = pos
      item.Drag.start()
    }

    function drop(dragArea) {
      var item = dragArea.drag.target
      var dropResult = item.Drag.drop()
      item.parent = oldParent
      dragActive = false
      freeStackViewItems()
      return dropResult
    }

    // Properties for dynamic sizing
    property real tilesPerRow: Math.floor(root.width / root.minimumCellWidth)
    property real tileWidth: root.width / tilesPerRow
    property var robotActions: ({
      items: [],
      reset: function () {
        robotActions.items.length = 0
        d.robotActionsChanged()
      },
      get: function (key) {
        for (var i = 0; i < robotActions.items.length; ++i) {
          if (robotActions.items[i].uuid === key) return robotActions.items[i].action
        }
        for (var i = 0; i < root.actions.length; ++i) {
          if (root.actions[i].uuid !== key) continue
          var action = RobotActionManager.cloneAction(root.actions[i])
          robotActions.items.push({uuid: key, action: root.actions[i]})
          return action
        }
        Ros.error("Tried to obtain robotAction with key that does not exist!")
      }
    })

    function getAction(key) {
      for (var i = 0; i < root.actions.length; ++i) {
        if (root.actions[i].uuid === key) return root.actions[i]
      }
      Ros.error("Tried to obtain an action using a key that does not exist. Your config seems to be broken!")
    }

    function getStructureEntry(uuid) {
      return _getStructureEntry(root.structure, uuid)
    }

    function handleItemMoved(model, from, to) {
      root.structure = _moveItemInStructure(root.structure, model, model.content[from], to)
      root.structureUpdated()
    }

    function moveItemToDirectory(parent, item, index) {
      if (!root.structure.content) {
        initActionStructure()
        var structure = root.structure
        structure.content.push(toStructureEntry(item))
        root.structure = structure
        root.structureUpdated()
        return
      }
      if (isStructureEntry(item)) {
        root.structure = _moveItemInStructure(root.structure, parent, item, index)
      } else {
        root.structure = _insertItemIntoStructure(root.structure, parent, toStructureEntry(item), index)
      }
      root.structureUpdated()
    }

    function initActionStructure() {
      root.structure = {uuid: "root", type: "directory", content: []}
    }

    function isStructureEntry(item) {
      return !!item.type && !!item.key
    }

    function toStructureEntry(item) {
      if (item.type && (item.type == "directory" || item.type == "robotAction")) return item
      if (item.uuid) {
        return {type: "robotAction", key: item.uuid, uuid: Uuid.generate()}
      }
      Ros.error("Failed to create structure entry for: " + JSON.stringify(item))
    }

    function removeStructureEntry(uuid) {
      root.structure = _removeStructureEntry(root.structure, uuid)
      root.structureUpdated()
    }

    function createDirectory(dropTarget, dropItem) {
      root.structure = _createDirectory(root.structure, dropTarget, dropItem)
      root.structureUpdated()
    }

    function renameDirectory(uuid, newName) {
      root.structure = _renameDirectory(root.structure, uuid, newName)
      root.structureUpdated()
    }

    function _getStructureEntry(structure, uuid) {
      if (structure.uuid === uuid) return structure
      if (structure.type !== "directory") return undefined
      for (var i = 0; i < structure.content.length; ++i) {
        var entry = _getStructureEntry(structure.content[i], uuid)
        if (entry) return entry
      }
      return undefined
    }

    function _filterStructureContent(content) {
      if (!Array.isArray(content)) return []
      return content.filter(Boolean)
    }

    function _insertItemIntoStructure(structure, parent, item, index) {
      if (structure.type != "directory") return structure
      if (structure.uuid === parent.uuid) {
        if (index >= structure.content.length) structure.content.push(item)
        else structure.content.splice(index, 0, item)
        return structure
      }
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = _insertItemIntoStructure(structure.content[i], parent, item, index)
      }
      return structure
    }

    function _moveItemInStructure(structure, newParent, item, index) {
      if (structure.uuid === item.uuid) return undefined
      if (structure.type !== "directory") return structure
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = _moveItemInStructure(structure.content[i], newParent, item, index)
      }
      structure.content = _filterStructureContent(structure.content)
      if (structure.uuid === newParent.uuid) {
        if (index !== null && index < structure.content.length)
          structure.content.splice(index, 0, item)
        else
          structure.content.push(item)
      }
      return structure
    }

    function _removeStructureEntry(structure, uuid) {
      if (structure.uuid === uuid) return undefined
      if (structure.type && structure.type != "directory") return structure
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = _removeStructureEntry(structure.content[i], uuid)
      }
      structure.content = _filterStructureContent(structure.content)
      return structure
    }

    function _createDirectory(structure, dropTarget, dropItem) {
      if (structure.uuid === dropItem.uuid) return undefined
      if (structure.type && structure.type != "directory") {
        if (structure.uuid !== dropTarget.uuid) return structure
        return {
          uuid: Uuid.generate(),
          type: "directory",
          name: "Unnamed",
          content: [dropTarget, toStructureEntry(dropItem)]
        }
      }
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = _createDirectory(structure.content[i], dropTarget, dropItem)
      }
      structure.content = _filterStructureContent(structure.content)
      return structure
    }

    function _renameDirectory(structure, uuid, newName) {
      if (structure.type && structure.type != "directory") return structure
      if (structure.uuid === uuid) {
        structure.name = newName
      }
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = _renameDirectory(structure.content[i], uuid, newName)
      }
      return structure
    }

    // For debugging
    function _dumpStructure(structure, indentation) {
      if (!indentation) indentation = ""
      if (structure.type !== "directory") {
        console.log(indentation + "- " + structure.key)
        return
      }
      console.log(indentation + "- " + (structure.uuid === "root" ? "Root" : structure.name) + ":")
      for (var i = 0; i < structure.content.length; ++i) {
        _dumpStructure(structure.content[i], indentation + " ")
      }
    }
  }
}

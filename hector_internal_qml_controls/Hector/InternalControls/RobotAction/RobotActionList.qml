import QtQuick 2.12
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0

ListView {
  id: root
  property Item dragParent: root
  property bool editable: true
  property bool dragActive: false
  
  signal editActionRequested(string uuid)
  signal removeActionRequested(string uuid)

  delegate: Item {
    property int index
    width: root.width
    height: Units.pt(24)
    RowLayout {
      anchors.fill: parent
      Text {
        Layout.preferredWidth: Units.pt(8)
        Layout.margins: Units.pt(4)
        font: Style.iconFontFamily
        text: modelData.icon || ''
      }
      Text {
        Layout.fillWidth: true
        text: modelData.name
      }
      Text { Layout.rightMargin: Units.pt(4); text: modelData.type }
    }
    Rectangle {
      anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
      height: Units.pt(1)
      color: Style.base.primary.color
    }

    Menu {
      id: contextMenu
      MenuItem {
        text: "Edit"
        onTriggered: root.editActionRequested(modelData.uuid)
      }
      MenuItem {
        text: "Delete"
        onTriggered: root.removeActionRequested(modelData.uuid)
      }
    }

    RobotActionExecutor {
      id: robotActionExecutor
      action: RobotAction {
        uuid: modelData.uuid
        name: modelData.name
        icon: modelData.icon
        type: modelData.type
        topic: modelData.topic
        messageType: modelData.messageType
        evaluateParams: Conversions.toBoolean(modelData.evaluateParams)
        params: modelData.params
        subactions: modelData.subactions
        parallel: Conversions.toBoolean(modelData.parallel)
        anonymous: Conversions.toBoolean(modelData.anonymous)
      }
    }

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.RightButton
      onClicked: contextMenu.popup()
    }

    MouseArea {
      id: dragArea
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton
      drag.target: previewButton
      // Drag and drop is somewhat weird, see: https://stackoverflow.com/questions/24532317/new-drag-and-drop-mechanism-does-not-work-as-expected-in-qt-quick-qt-5-3
      drag.onActiveChanged: {
        root.dragActive = drag.active
        if (drag.active) drag.target.Drag.start()
        else drag.target.Drag.drop()
      }

      onClicked: robotActionExecutor.execute()
    }

    // Drag preview
    ActionButton {
      id: previewButton
      property var model: modelData
      visible: false
      robotAction: robotActionExecutor.action
      width: Units.pt(100)
      height: Units.pt(32)
      z: 1000
      Drag.dragType: Drag.None
      Drag.keys: ["RobotAction"]
      Drag.hotSpot.x: width / 2
      Drag.hotSpot.y: height / 2
      states: [
        State {
          when: dragArea.drag.active
          ParentChange {
            target: previewButton
            parent: root.dragParent
          }
          PropertyChanges {
            target: previewButton
            visible: true
            x: previewButton.parent.mapFromItem(dragArea, dragArea.mouseX, 0).x - previewButton.width / 2
            y: previewButton.parent.mapFromItem(dragArea, 0, dragArea.mouseY).y - previewButton.height / 2
          }
        }
      ]
    }
  }
}
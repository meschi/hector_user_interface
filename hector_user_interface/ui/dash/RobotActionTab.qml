import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.InternalControls.RobotAction 1.0
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

Rectangle {
  id: root
  property var style
  property var actions: []
  property var actionStructure: ({uuid: "root", type: "directory", content: []})
  property bool editable: true
  signal actionsUpdated
  signal actionStructureUpdated

  QtObject {
    id: config
    property real animationDuration: 300
    readonly property var serviceBlacklist: [/\/get_loggers$/, /\/set_loggers$/, /\/set_logger_level$/, /^\/rosapi\//]

    function isBlacklistedService(topic) {
      for (var k = 0; k < serviceBlacklist.length; ++k) {
        if (serviceBlacklist[k].test(topic)) return true
      }
      return false
    }
  }

  Item {
    anchors.fill: parent
    RobotActionStructureView {
      id: structureView
      anchors.fill: parent
      anchors.bottomMargin: openDrawerButton.height
      clip: true
      actions: root.actions
      dragParent: appWindow
      minimumCellWidth: Units.pt(96)
      structure: root.actionStructure
      onStructureUpdated: {
        root.actionStructure = structure
        root.actionStructureUpdated()
      }
      onEditActionRequested: {
        addActionDialog.edit(d.getAction(uuid))
      }
    }

    Rectangle {
      id: allBehaviorsDrawer
      property bool open: false
      anchors {
        left: parent.left
        top: parent.top
        right: parent.right
        topMargin: open && !allBehaviorsListView.dragActive ? 0 : root.height - openDrawerButton.height 
        Behavior on topMargin {
          enabled: !allBehaviorsListView.dragActive
          NumberAnimation { duration: config.animationDuration }
        }
      }
      // Workaround for bug where if anchors.fill is used dragged items from the lower part of the list just disappear
      height: parent.height
      color: Style.background.content
      clip: true

      ColumnLayout {
        anchors.fill: parent
        spacing: 0
        Rectangle {
          id: openDrawerButton
          Layout.fillWidth: true
          height: Style.button.defaultHeight
          color: root.style.primary.color
          Text {
            id: openDrawerButtonText
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.leftMargin: Units.pt(8)
            text: "All Behaviors"
            color: Style.getTextColor(parent.color)
            font: Style.button.font
          }
          // Add action button
          Button {
            id: addRobotActionButton
            anchors.right: parent.right
            anchors.rightMargin: allBehaviorsDrawer.open ? 0 : -width
            Behavior on anchors.rightMargin {
              PropertyAnimation { duration: config.animationDuration * 2 }
            }
            width: height
            height: parent.height
            flat: true
            text: Style.icons.plus
            font { family: Style.iconFontFamily; bold: true; pointSize: Units.pt(6) }
            onClicked: addActionDialog.open()
          }
          // Divider
          Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.bottomMargin: -Units.pt(1)
            width: Units.pt(80)
            height: Units.pt(1)
            color: "black"
          }
          states: [
            State {
              when: allBehaviorsDrawer.open
              AnchorChanges {
                target: openDrawerButtonText
                anchors.horizontalCenter: undefined
                anchors.left: parent.left
              }
              PropertyChanges {
                target: openDrawerButton
                color: Style.background.content
              }
            }
          ]

          transitions: Transition {
            AnchorAnimation { duration: config.animationDuration }
            ColorAnimation { duration: config.animationDuration }
          }

          MouseArea {
            anchors.fill: parent
            enabled: !allBehaviorsDrawer.open
            onClicked: allBehaviorsDrawer.open = true
          }
        }
        
        RobotActionList {
          id: allBehaviorsListView
          Layout.fillWidth: true
          Layout.fillHeight: true
          dragParent: appWindow
          model: root.actions
          clip: true

          onEditActionRequested: {
            addActionDialog.edit(d.getAction(uuid))
          }
          onRemoveActionRequested: {
            // TODO Ask sure
            d.removeAction(uuid)
          }
        }

        StyledButton {
          Layout.fillWidth: true
          style: root.style
          text: "Close"
          onClicked: allBehaviorsDrawer.open = false
        }
      }
    }
    
    EditRobotActionDialog {
      id: addActionDialog
      actions: root.actions
      onEditFinished: function (action) {
        if (!action) {
          editItem = null
          return
        }
        var actions = root.actions
        if (editItem) {
          for (let prop in action) editItem[prop] = action[prop]
          RobotActionManager.updateAction(editItem)
        } else {
          action.uuid = Uuid.generate()
          actions.push(action)
        }
        root.actions = actions
        root.actionsUpdated()
        editItem = null
      }
    }
  }

  QtObject {
    id: d

    function getAction(key) {
      for (var i = 0; i < root.actions.length; ++i) {
        if (root.actions[i].uuid === key) return root.actions[i]
      }
      Ros.error("Tried to obtain an action using a key that does not exist. Your config seems to be broken!")
    }

    function removeAction(uuid) {
      var actions = root.actions
      for (var i = 0; i < actions.length; ++i) {
        if (actions[i].uuid !== uuid) continue
        actions.splice(i, 1)
        break
      }
      root.actions = actions
      root.actionStructure = removeActionFromStructure(root.actionStructure, uuid)
      structureView.structure = root.actionStructure
      root.actionsUpdated()
      root.actionStructureUpdated()
    }

    function removeActionFromStructure(structure, uuid) {
      if (structure.type !== "directory") return structure.key !== uuid ? structure : undefined
      for (var i = 0; i < structure.content.length; ++i) {
        structure.content[i] = removeActionFromStructure(structure.content[i], uuid)
      }
      structure.content = structure.content.filter(Boolean)
      return structure
    }
  }
}
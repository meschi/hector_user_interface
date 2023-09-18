import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0

Rectangle {
  id: root
  property var execution
  property alias iconColor: actionIcon.backgroundColor
  implicitHeight: Units.pt(48)
  implicitWidth: actionIcon.implicitWidth * 1.5 + actionText.implicitWidth

  color: Style.background.content
  Behavior on color {
    ColorAnimation { duration: 400 }
  }
  states: [
    State {
      name: "success"
      when: execution.state === RobotActionExecution.ExecutionState.Succeeded
      PropertyChanges {
        target: root
        color: Qt.lighter(Style.colors.status.success, 1.2)
      }
      PropertyChanges {
        target: actionIcon
        backgroundColor: Style.colors.status.success
        text: Style.icons.check
      }
    },
    State {
      name: "failed"
      when: execution.state === RobotActionExecution.ExecutionState.Failed
      PropertyChanges {
        target: root
        color: Qt.lighter(Style.colors.status.error, 1.2)
      }
      PropertyChanges {
        target: actionIcon
        backgroundColor: Style.colors.status.error
        text: Style.icons.exclamation
      }
    },
    State {
      name: "canceled"
      when: execution.state === RobotActionExecution.ExecutionState.Canceled
      PropertyChanges {
        target: root
        color: Qt.lighter(Style.colors.status.warn, 1.2)
      }
      PropertyChanges {
        target: actionIcon
        backgroundColor: Style.colors.status.warn
        text: Style.icons.canceled
      }
    }
  ]

  Progress {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: Units.pt(2)
    indefiniteColor: Qt.lighter(Style.teleoperation.primary.color, 1.5)
    backgroundColor: "transparent"
    foregroundColor: Style.teleoperation.primary.color
    value: root.execution.progress
    visible: root.execution.active
  }

  QtObject {
    id: d
    property real scale: Math.max(0.1, root.height / Units.pt(48))
  }

  Icon {
    id: actionIcon
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: parent.left
    anchors.leftMargin: Units.pt(8) * d.scale
    height: Units.pt(32) * d.scale
    width: height
    backgroundColor: Style.teleoperation.primary.color
    Behavior on backgroundColor { ColorAnimation { duration: 400 } }
    color: Style.getTextColor(backgroundColor)
    padding: Units.pt(6) * d.scale
    font.family: Style.iconFontFamily
    text: execution.action.icon || Style.icons.robotAction
  }
  Rectangle {
    id: actionText
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: actionIcon.right
    anchors.right: parent.right
    anchors.leftMargin: Units.pt(8) * d.scale
    anchors.rightMargin: Units.pt(12) * d.scale
    implicitHeight: actionStatusLayout.implicitHeight
    implicitWidth: actionStatusLayout.implicitWidth
    color: "transparent"
    ColumnLayout {
      id: actionStatusLayout
      anchors.fill: parent
      spacing: 0
      Text {
        Layout.fillWidth: true
        id: mainActionText
        font.weight: Style.fonts.header.weight
        font.pointSize: Style.fonts.header.pointSize * d.scale
        text: execution.action.name
        color: Style.getTextColor(root.color)
        elide: Text.ElideRight
      }
      Text {
        id: subActionText
        Layout.fillWidth: true
        visible: !!execution.statusText
        text: execution.statusText
        font.weight: Style.fonts.small.weight
        font.pointSize: Style.fonts.small.pointSize * d.scale
        color: Style.getTextColor(root.color)
        elide: Text.ElideRight
      }
    }
    ToolTip {
      delay: 500
      text: mainActionText.text
      visible: mouseArea.containsMouse && mainActionText.truncated
    }
  }
}
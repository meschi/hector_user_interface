import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0

Rectangle {
  id: root
  implicitHeight: robotActionStatus.implicitHeight + robotActionDetails.implicitHeight
  implicitWidth: robotActionStatus.implicitWidth

  QtObject {
    id: d
    property var activeExecutions: RobotActionExecutionManager.activeExecutions || []

    property bool canceling: {
      if (!d.activeExecutions) return false
      return d.activeExecutions.every(x => !x.active || x.state == RobotActionExecution.ExecutionState.Canceling)
    }

    property int countExecutions: {
      if (!d.activeExecutions) return 0
      return d.activeExecutions.length
    }

    onCountExecutionsChanged: {
      if (countExecutions > 1) return
      robotActionDetails.showDetails = false
    }

    property int countDone: {
      if (!activeExecutions) return 0
      var count = 0
      for (let execution of d.activeExecutions) {
        if (execution.active === true) continue
        count++
      }
      return count
    }

    property RobotActionExecution summaryExecution: RobotActionExecution {
      action: RobotAction {
        type: "composite"
        name: {
          if (d.countExecutions > 1) return d.countExecutions + " actions running"
          return d.countExecutions === 1 ? d.activeExecutions[0].action.name : ""
        }
        icon: {
          if (d.activeExecutions && d.activeExecutions.length == 1 && d.activeExecutions[0].action.icon) return d.activeExecutions[0].action.icon
          return Style.icons.robotAction
        }
      }

      active: d.countExecutions !== d.countDone

      progress: {
        if (!d.activeExecutions) return false
        if (d.countExecutions === 0) return 0
        if (d.countExecutions === 1) return d.activeExecutions[0].progress
        // Compute progress bounds of all active executions
        let minProgress = d.countDone
        let maxProgress = minProgress
        for (let execution of d.activeExecutions) {
          if (!execution.active) continue // Already counted by done
          if (!execution.progress) {
            maxProgress += 1
            continue
          }
          if (execution.progress.length == 2) {
            minProgress += execution.progress[0]
            maxProgress += execution.progress[1]
            continue
          }
          minProgress += execution.progress
          maxProgress += execution.progress
        }
        return [minProgress / d.countExecutions, maxProgress / d.countExecutions]
      }

      property int lastState: RobotActionExecution.ExecutionState.Succeeded
      state: {
        // Keep last state if no active executions for slide out animation
        if (d.activeExecutions.length === 0) return lastState
        // Check if any are running and if all finished if one failed
        let state = RobotActionExecution.ExecutionState.Succeeded
        for (let execution of d.activeExecutions) {
          if (execution.state === RobotActionExecution.ExecutionState.Running) {
            return execution.state
          }
          if (execution.state === RobotActionExecution.ExecutionState.Failed) {
            state = execution.state
          } else if (state === RobotActionExecution.ExecutionState.Succeeded &&
                     execution.state === RobotActionExecution.ExecutionState.Canceled) {
            state = execution.state
          }
        }
        return state
      }

      statusText: {
        if (d.countExecutions === 0) return ""
        if (d.countExecutions > 1) return d.countDone + " out of " + d.countExecutions + " completed"
        let execution = d.activeExecutions[0]
        return execution.statusText
      }
    }
  }

  Rectangle {
    id: robotActionStatus
    width: parent.width
    clip: true
    implicitHeight: summaryLayout.implicitHeight
    implicitWidth: summaryLayout.implicitWidth

    RowLayout {
      id: summaryLayout
      width: parent.width
      RobotActionExecutionStatus {
        Layout.fillWidth: true
        Layout.fillHeight: true
        id: actionSummary
        execution: d.activeExecutions.length == 1 ? d.activeExecutions[0] : d.summaryExecution
        width: parent.width

        MouseArea {
          id: mouseArea
          anchors.fill: parent
          hoverEnabled: true
          onClicked: {
            if (d.activeExecutions.length <= 1) return
            robotActionDetails.showDetails = !robotActionDetails.showDetails
          }
        }
      }
      // Cancel all
      StyledButton {
        id: cancelAllButton
        Layout.fillHeight: true
        style: Style.teleoperation
        visible: d.summaryExecution.active
        ColumnLayout {
          anchors.centerIn: parent
          spacing: 0
          Text {
            visible: !d.canceling
            Layout.alignment: Qt.AlignHCenter
            color: Style.getTextColor(cancelAllButton.style.primary.color)
            text: Style.icons.cancel
            font { family: Style.iconFontFamily; pointSize: 24 }
          }
          Text {
            visible: !d.canceling
            Layout.alignment: Qt.AlignHCenter
            color: Style.getTextColor(cancelAllButton.style.primary.color)
            text: d.countExecutions > 1 ? "Cancel All" : "Cancel"
            font.pointSize: 9
            font.weight: Font.Bold
          }
        }
          Text {
            visible: d.canceling
            anchors.fill: parent
            color: Style.getTextColor(cancelAllButton.style.primary.color)
            text: "Hold to force cancel"
            font.pointSize: 11
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
          }

        onClicked: {
          for (let execution of d.activeExecutions) {
            RobotActionExecutionManager.cancel(execution.action)
          }
        }

        onPressAndHold: {
          for (let execution of d.activeExecutions) {
            RobotActionExecutionManager.cancel(execution.action, true)
          }
        }
      }
    }

    Text {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: Units.pt(8) + cancelAllButton.width
      anchors.bottomMargin: Units.pt(2)
      color: Style.getTextColor(Style.background.content)
      font: Style.fonts.tiny
      text: robotActionDetails.showDetails ? "Hide" : "Show Details"
      visible: d.activeExecutions.length > 1
    }
  }

  Rectangle {
    id: robotActionDetails
    anchors.top: robotActionStatus.bottom
    width: parent.width
    property bool showDetails: false
    height: showDetails ? Math.min(d.activeExecutions.length * Units.pt(36), Units.pt(320)) : 0
    Behavior on height { NumberAnimation {} }
    color: Style.background.content
    ListView {
      id: robotActionListView
      anchors.fill: parent
      clip: true

      model: d.activeExecutions
      delegate: RobotActionExecutionStatus {
        height: Units.pt(36)
        width: root.width
        execution: modelData
      }
    }
  }
}

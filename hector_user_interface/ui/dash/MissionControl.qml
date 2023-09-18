
import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Ros 1.0
import Hector.Utils 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0

Item {
  id: missionControl
  
  property bool enabled: true
  property var mission: null
  property var missionStatus: null

  implicitHeight: missionControlLayout.implicitHeight
  implicitWidth: missionControlLayout.implicitWidth

  RowLayout {
    id: missionControlLayout
    spacing: Units.pt(4)

    StyledRoundButton {
      font.family: Style.iconFontFamily
      text: Style.icons.previous
      onClicked: function() {
        enabled = false
        var result = Service.callAsync("mission_execution_manager/go_back", "std_srvs/Empty", {}, function (result) {
          if(!result) {
            Ros.warn("Going back to the previous task failed: " + missionControl.mission.name)
          }
          enabled = true
        })
      }
    }

    StyledRoundButton {
      enabled: missionControl.missionStatus && missionControl.missionStatus.is_mission_running
      font.family: Style.iconFontFamily
      text: Style.icons.pauseSnooze
      onClicked: function() {
        enabled = false
        var result = Service.callAsync("mission_execution_manager/stop", "mission_msgs/StopMission", {complete_current_task: true}, function (result) {
          if(!result) {
            Ros.warn("Paussing current mission failed: " + missionControl.mission.name)
          }
          enabled = true
        })
      }
    }

    StyledRoundButton {
      Layout.margins: Units.pt(2)
      Layout.preferredWidth: Units.pt(24)
      Layout.preferredHeight: Units.pt(24)
      checkable: true
      font.family: Style.iconFontFamily
      buttonStyle: ({color: Style.autonomous.primary.color, uncheckedColor: Style.base.primary.color, checkedColor: Style.autonomous.primary.color})
      checked: missionControl.missionStatus.is_mission_running
      text: !checked ? Style.icons.play : Style.icons.pause 
      onClicked: {
        if (!enabled) return
        enabled = false
        if(!missionControl.missionStatus.is_mission_running) {
          Service.callAsync("mission_execution_manager/start", "std_srvs/Empty", {}, function (result) {
            if(!result) {
              Ros.warn("Starting mission failed: " + missionControl.mission.name)
            }
            enabled = true
          })
        } else {
          Service.callAsync("mission_execution_manager/stop", "mission_msgs/StopMission", {complete_current_task: false}, function (result) {
            if(!result) {
              Ros.warn("Pausing current mission failed: " + missionControl.mission.name)
            }
            enabled = true
          })
        }
      }
    }

    StyledRoundButton {
      font.family: Style.iconFontFamily
      text: Style.icons.stop
      onClicked: function() {
        enabled = false
        Service.callAsync("mission_execution_manager/reset", "std_srvs/Empty", {}, function (result) {
          if(!result) {
            Ros.warn("Resetting the current task failed: " + missionControl.mission.name)
          }
          enabled = true
        })
      }
    }

    StyledRoundButton {
      font.family: Style.iconFontFamily
      text: Style.icons.next
      onClicked: function() {
        enabled = false
        Service.callAsync("mission_execution_manager/skip_current_task", "std_srvs/Empty", {}, function (result) {
          if(!result) {
            Ros.warn("Skipping the current task failed: " + missionControl.mission.name)
          }
          enabled = true
        })
      }
    }	
  }
 }


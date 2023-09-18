import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.InternalControls.RobotAction 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0


RowLayout {
  id: control
  property var style
  property var waypointTool
  property alias active: driveToButton.active

  height: driveToButton.implicitHeight

  RowLayout {
    spacing: 0
    Rectangle {
      color: Style.getTextColor(control.style.primary.color)
      Layout.fillHeight: true
      implicitWidth: waypointsCount.implicitWidth
      Text {
        id: waypointsCount
        anchors.centerIn: parent
        color: control.style.primary.color
        font { pointSize: 12; weight: Font.Bold }
        text: (control.waypointTool && control.waypointTool.tool.waypoints.length || 0) + " Waypoints"
        leftPadding: Units.pt(8)
        rightPadding: Units.pt(4)
      }
    }
    StyledButton {
      Layout.fillHeight: true
      Layout.preferredWidth: height
      style: control.style
      contentItem: AutoSizeText {
        anchors.fill: parent
        text: parent.hovered ? Style.icons.trashOpen : Style.icons.trash
        font { family: Style.iconFontFamily }
      }
      onClicked: control.waypointTool.tool.clearWaypoints()
    }
  }

  ActionButton {
    id: driveToButton
    Layout.minimumWidth: Units.pt(104)
    style: control.style
    robotAction: RobotAction {
      name: 'Drive to waypoints'
      type: 'action'
      messageType: 'flexbe_msgs/BehaviorExecutionAction'
      topic: '/flexbe/execute_behavior'
      evaluateParams: true
      params: function () {
        var poses = []
        for (var pose of waypointTool.tool.waypoints) {
          var q = pose.orientation
          poses.push({
            header: {frame_id: waypointTool.tool.frame},
            pose: {
              position: pose.position,
              orientation: {w: q.scalar, x: q.x, y: q.y, z: q.z}
            }
          })
        }
        return ({
          behavior_name: 'Drive to waypoints',
          arg_keys: ['path'],
          arg_values: [JSON.stringify({header: {stamp: Time.now(), frame_id: waypointTool.tool.frame}, poses: poses})]
        })
      }
    }
  }
}

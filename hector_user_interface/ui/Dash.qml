import QtQuick 2.3
import QtQuick.Layouts 1.1
import Ros 1.0
import Hector.Controls 1.0
import Hector.Utils 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import "dash"

Rectangle {
  id: root
  property var style

  property alias batteryTopic: robotStatus.batteryTopic

  signal configurationUpdated
  property var configuration

  color: Style.background.container
  border {color: style.primary.color; width: Units.pt(1)}

  Component.onCompleted: {
    if (!rviz) console.error("No rviz context property. Can't register properties!")
  }

  // Catches all mouse events that weren't handled by dash components to prevent them from going to rviz
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onWheel: wheel.accepted = true
  }
  ResizeHandle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    resizeBorder: ResizeHandle.Border.Top
    resizeMode: ResizeHandle.SizeOnly
    height: Units.pt(4)
    target: root
    z: 2
    minimumHeight: Units.pt(100)
  }

  RowLayout {
    anchors.fill: parent
    anchors.topMargin: Units.pt(1)

    ColumnLayout {
      Layout.fillHeight: true
      Layout.preferredWidth: Units.pt(90)
      Layout.minimumWidth: Units.pt(72)
      Layout.maximumWidth: Units.pt(90)
      spacing: 0

      ViewControllerControl {
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(64)
        Layout.margins: Units.pt(2)
        style: root.style
        robotFrame: "base_link"
        viewControllerNamespace: Ros.getName() + "/hector_view_controller"
      }
      
      RobotStatus {
        id: robotStatus
        Layout.fillWidth: true
        Layout.margins: Units.pt(4)
      }
      
      // Spacer
      Item { Layout.fillHeight: true }

      // ============ E-STOP ============
      StyledButton {
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(24)
        Layout.margins: Units.pt(4)
        id: control
        property bool active: false
        property bool sending: false
        checkable: true
        buttonStyle: Style.emergencyStop
        font.pointSize: 14
        text: sending ? "Sending..." : checked ? "Stopped" : "E-Stop"
        onClicked: {
          sending = true
          checked = active
          active = !active
          Service.callAsync("/e_stop_manager/set_e_stop", "e_stop_manager_msgs/SetEStop", {name: "ui_e_stop", value: active},
            function (response) {
              sending = false
              if (response.result == 0) {
                checked = active
                return
              }
              Ros.error("Failed to set e-stop! Result: " + JSON.stringify(response.result))
            }
          )
        }
      }
    }

    ColumnLayout {
      Layout.fillHeight: true
      Layout.maximumWidth: Units.pt(124)
      Layout.preferredWidth: Units.pt(124)
      Layout.minimumWidth: Units.pt(124)
      spacing: 0


      RobotOrientationView {
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(64)
        Layout.margins: Units.pt(2)
        useRvizProperties: true
      }

      JoyMode {
        Layout.fillWidth: true
        Layout.margins: Units.pt(2)
      }

      CameraLayouts {
        Layout.fillHeight: true
        Layout.fillWidth: true
        configuration: root.configuration && root.configuration.cameraLayouts ? root.configuration.cameraLayouts : []
        onConfigurationUpdated: {
          root.configuration.cameraLayouts = configuration
          root.configurationUpdated()
        }
      }
    }

    MultiCameraGridView {
      id: leftCameraView
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      Layout.minimumWidth: Units.pt(120)
      configuration: root.configuration && root.configuration.cameraView ? root.configuration.cameraView : {}
      onConfigurationUpdated: {
        root.configuration.cameraView = configuration
        root.configurationUpdated()
      }
    }
    
    MultiCameraGridView {
      id: rightCameraView
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      Layout.minimumWidth: Units.pt(120)
      configuration: root.configuration && root.configuration.cameraView ? root.configuration.cameraView : {}
      onConfigurationUpdated: {
        root.configuration.cameraView = configuration
        root.configurationUpdated()
      }
    }

    RobotControlTabView {
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.preferredWidth: 1
      Layout.minimumWidth: Units.pt(80)
      style: root.style
      configuration: root.configuration.robotActions
      onConfigurationUpdated: {
        root.configuration.robotActions = configuration
        root.configurationUpdated()
      }
    }
  }
}

import QtQuick 2.8
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Ros 1.0
import Hector.Controls 1.0
import Hector.Icons 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import "status"

Item {
  id: appWindow
  anchors.fill: parent

  property var style: Style.activeStyle
  property var batteryTopicProperty: rviz && rviz.registerRosTopicProperty("Battery Topic", "/battery", "sensor_msgs/BatteryState")

  Component.onCompleted: {
    // Init if not initialized
    if (!Ros.isInitialized()) {
      console.log("Ros was not initialized. Initializing.")
      Ros.init("hector_user_interface")
    }
    //! Disable warnings due to compressed image transport advertising a dynamic reconfigure server
    Ros.console.setLoggerLevel("ros.roscpp", RosConsoleLevels.Fatal)
    for (let action of rviz.config.robotActions.actions) {
      RobotActionManager.registerAction(action)
    }
  }

  Connections {
    target: OperationModeManager
    onActiveModeChanged: {
      let style = Style.activeStyle
      if (OperationModeManager.activeMode == OperationModeManager.Safe) style = Style.safe
      else if (OperationModeManager.activeMode == OperationModeManager.Teleoperation) style = Style.teleoperation
      else if (OperationModeManager.activeMode == OperationModeManager.Manipulation) style = Style.manipulation
      Style.setActiveStyle(style)
    }
  }


  // Time
  Rectangle {
    id: timeRectangle
    x: 0
    y: Units.pt(24)
    z: 10
    color: Style.background.container
    width: Units.pt(48)
    height: Units.pt(24)

    AutoSizeText {
      function getTime() {
        var date = new Date()
        var hours = date.getHours()
        var minutes = date.getMinutes()
        // padStart is available from Qt 5.12 on https://bugreports.qt.io/browse/QTBUG-55223
        return (hours < 10 ? "0" + hours : hours) + ":" + (minutes < 10 ? "0" + minutes : minutes)
      }

      id: clockText
      color: Style.getTextColor(timeRectangle.color)
      text: getTime()

      Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: clockText.text = clockText.getTime()
      }
    }
  }

  // Fullscreen toggle
  RoundButton {
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Units.pt(8)
    padding: 0
    width: Units.pt(24)
    height: Units.pt(24)
      
    Text {
      anchors.centerIn: parent
      font.family: HectorIcons.fontFamily
      font.pointSize: 16
      text: rviz.isFullscreen ? HectorIcons.exitFullscreen : HectorIcons.fullscreen
      color: "#ffffff"
    }

    background: Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: "#444444"
      opacity: parent.down ? 1 : parent.hovered ? 0.8 : 0.6
    }

    onClicked: rviz.isFullscreen = !rviz.isFullscreen
  }

  // Shows status of currently running robot action(s) and emergency stops
  EStopStatus {
    id: estopStatus
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: dash.top
    width: Units.pt(200)
    visible: activeEstopCount > 0
  }

  ActiveRobotActionStatus {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    width: Units.pt(240)
    anchors.topMargin: RobotActionExecutionManager.activeExecutions.length > 0 ? 0 : -height - 2
    Behavior on anchors.topMargin { NumberAnimation {} }
  }

  RvizToolbar
  {
    id: toolBar
    anchors.bottom: dash.top
    anchors.left: parent.left
    anchors.margins: Units.pt(4)
    height: Units.pt(24)
    iconMargin: Units.pt(5)
    buttonRadius: Units.pt(2)
    shortcutFont: Qt.font({pointSize: 8})
    editable: false
    selectedColor: appWindow.style.primary.color
  }

  Image {
    anchors.left: parent.left
    anchors.bottom: hectorLogo.visible ? hectorLogo.top : toolBar.top
    anchors.bottomMargin: Units.pt(16)
    source: "../media/tuda_logo.png"
    height: sourceSize.height * scale
    width: sourceSize.width * scale
    visible: logoProperty && logoProperty.value || false
    property real scale: Math.max(toolBar.width + Units.pt(96), Units.pt(240)) / sourceSize.width
    property var logoProperty: rviz.registerBoolProperty("TUDa Branding", false, "Activate to display the TU Darmstadt logo prominently in the UI.")
  }

  Image {
    id: hectorLogo
    anchors.left: parent.left
    anchors.leftMargin: Units.pt(8)
    anchors.bottom: toolBar.bottom
    source: "../media/logo.png"
    height: sourceSize.height * scale
    width: sourceSize.width * scale
    visible: logoProperty && logoProperty.value || false
    property real scale: Math.max(toolBar.width + Units.pt(96), Units.pt(240)) / sourceSize.width
    property var logoProperty: rviz.registerBoolProperty("Branding", false, "Activate to display the team hector logo prominently in the UI.")
  }

  // Tool controls
  QtObject {
    id: dTool
    property var current: (rviz && rviz.toolManager && rviz.toolManager.currentTool && rviz.toolManager.currentTool) || {classId: ''} 
    property var waypointTool: {
      if (!rviz || !rviz.toolManager) return
      for (var tool of rviz.toolManager.tools) {
        if (tool.classId  == "hector_user_interface/WaypointTool") return tool
      }
      return null
    }
  }
  
  WaypointToolControls {
    anchors.bottom: dash.top
    anchors.right: parent.right
    anchors.margins: Units.pt(4)
    visible: active || (dTool.waypointTool && dTool.waypointTool.tool.waypoints.length > 0)
    style: appWindow.style
    waypointTool: dTool.waypointTool
  }

  SensorValues {
    anchors.top: parent.top
    anchors.topMargin: Units.pt(4)
    anchors.left: timeRectangle.right
    anchors.leftMargin: Units.pt(32)
  }

  Dash {
    id: dash
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom 
    anchors.margins: -2
    style: appWindow.style
    property var dashHeightProperty: rviz && rviz.registerFloatProperty("Dash Height")
    height: Units.pt(dashHeightProperty.value || 160)
    onHeightChanged: if (Math.abs(Units.toPt(height) - dashHeightProperty.value) > 0.1) dashHeightProperty.value = Units.toPt(height)
    batteryTopic: appWindow.batteryTopicProperty.value || "/battery"
    configuration: rviz && rviz.config ? rviz.config : {}
    // Workaround until QTBUG-19892 is implemented (Target is Qt 6.0) https://bugreports.qt.io/browse/QTBUG-19892
    onConfigurationUpdated: rviz.config = configuration
  }
}

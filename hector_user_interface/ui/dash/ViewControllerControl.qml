import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

Item {
  id: root
  property var style
  property string robotFrame
  property string viewControllerNamespace

  QtObject {
    id: d
    property real scale: Math.min(root.width / 66, root.height / 72)
    property real horizontalMargin: root.width / 2 - 25 * scale
    property real verticalMargin: root.height / 2 - 30 * scale
    property bool in3DMode: !(viewModeSubscriber.message && viewModeSubscriber.message.mode == 1 || false)
    onScaleChanged: robotCanvas.requestPaint()
    onHorizontalMarginChanged: robotCanvas.requestPaint()
    onVerticalMarginChanged: robotCanvas.requestPaint()

    function moveCamera(x, y) {
      Service.callAsync(root.viewControllerNamespace + "/move_eye_and_focus", "hector_rviz_plugins_msgs/MoveEyeAndFocus", {header: {frame_id: root.robotFrame}, eye: {x: x, y: y, z: 3}},
        function (result) {
          if (result) return
          Ros.warn("Failed to move camera! Perhaps you are not using the HectorViewController ViewController.")
        }
      )
    }

    function moveCamera2D(x, y) {
      Service.callAsync(root.viewControllerNamespace + "/move_eye", "hector_rviz_plugins_msgs/MoveEye", {header: {frame_id: root.robotFrame}, eye: {x: x, y: y, z: 4}},
        function (result) {
          if (result) return
          Ros.warn("Failed to move camera! Perhaps you are not using the HectorViewController ViewController.")
        }
      )
    }
  }
  
  Canvas {
    id: robotCanvas
    anchors.fill: parent
    contextType: "2d"
    onPaint: {
      if (!context) return // Wait for context to be valid
      context.save()
      var scale = d.scale
      // Center and scale to fill
      context.translate(d.horizontalMargin, d.verticalMargin)
      context.scale(scale, scale)
      
      // Draw robot
      context.fillStyle = Qt.rgba(0.69, 0.69, 0.69, 1)
      context.fillRect(10, 3, 30, 54)
      // Tracks
      context.fillStyle = Qt.rgba(0, 0, 0, 1)
      context.path = "m 2,0 h 11 c 1.108,0 2,0.892 2,2 v 56 c 0,1.108 -0.892,2 -2,2 H 2 C 0.892,60 0,59.108 0,58 V 2 C 0,0.892 0.892,0 2,0 Z"
      context.fill()
      context.translate(35, 0)
      context.path = "m 2,0 h 11 c 1.108,0 2,0.892 2,2 v 56 c 0,1.108 -0.892,2 -2,2 H 2 C 0.892,60 0,59.108 0,58 V 2 C 0,0.892 0.892,0 2,0 Z"
      context.fill()
      context.restore()
    }
  }

  Text {
    anchors.centerIn: parent
    width: 20 * d.scale
    height: 20 * d.scale
    fontSizeMode: Text.Fit
    font { pointSize: 100; family: Style.iconFontFamily }
    minimumPointSize: 6
    horizontalAlignment: Text.AlignHCenter
    text: Style.icons.viewController
  }
  
  Subscriber {
    id: viewModeSubscriber
    topic: root.viewControllerNamespace + "/view_mode"
  }
  Subscriber {
    id: trackedFrameSubscriber
    topic: root.viewControllerNamespace + "/tracked_frame"
  }

  // Lock
  StyledRoundButton {
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.rightMargin: Math.max(d.horizontalMargin - 24 * d.scale, 0)
    anchors.bottomMargin: d.verticalMargin - 8 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    flat: true
    checkable: true
    checked: trackedFrameSubscriber.message && trackedFrameSubscriber.message.data == root.robotFrame || false
    text: checked ? Style.icons.lockClosed : Style.icons.lockOpen
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: Service.callAsync(root.viewControllerNamespace + "/set_tracked_frame", "hector_rviz_plugins_msgs/TrackFrame", {frame: checked ? root.robotFrame : ''})
  }

  // 2D / 3D Mode
  StyledRoundButton {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.leftMargin: Math.max(d.horizontalMargin - 28 * d.scale, 0)
    anchors.bottomMargin: d.verticalMargin - 8 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    flat: true
    checkable: true
    checked: d.in3DMode
    text: checked ? "3D" : "2D"
    font { weight: Font.Bold; letterSpacing: -2 * d.scale; pixelSize: 18 * d.scale }
    onClicked: Service.callAsync(root.viewControllerNamespace + "/set_view_mode", "hector_rviz_plugins_msgs/SetViewMode", {mode: {mode: checked ? 0 : 1}})
  }

  // View Left
  StyledRoundButton {
    visible: d.in3DMode
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: d.horizontalMargin - 8 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    text: Style.icons.viewControllerLeft
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: d.moveCamera(0, 3)
  }

  // View Right
  StyledRoundButton {
    visible: d.in3DMode
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: d.horizontalMargin - 8 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    text: Style.icons.viewControllerRight
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: d.moveCamera(0, -3)
  }

  // View Front
  StyledRoundButton {
    visible: d.in3DMode
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: d.verticalMargin - 6 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    text: Style.icons.viewControllerFront
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: d.moveCamera(3, 0)
  }

  // View Back
  StyledRoundButton {
    visible: d.in3DMode
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: d.verticalMargin - 6 * d.scale
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    text: Style.icons.viewControllerBack
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: d.moveCamera(-3, 0)
  }

  // View from top
  StyledRoundButton {
    visible: !d.in3DMode
    anchors.centerIn: parent
    width: 24 * d.scale
    height: 24 * d.scale
    padding: 0
    style: root.style
    text: Style.icons.location
    font { family: Style.iconFontFamily; pixelSize: 18 * d.scale }
    onClicked: d.moveCamera2D(0, 0)
  }
}
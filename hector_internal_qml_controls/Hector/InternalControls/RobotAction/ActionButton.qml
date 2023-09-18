import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

StyledButton {
  id: control
  property var robotAction: null
  readonly property bool active: d.executor.execution && d.executor.execution.active
  text: active ? "Cancel" :  (robotAction && robotAction.name || "")

  background: Rectangle {
    implicitWidth: Units.pt(50)
    implicitHeight: Units.pt(20)
    visible: !control.flat
    opacity: enabled ? 1 : 0.3
    //color: Style.handleMouseStates(control, control.checkable ? control.buttonStyle.uncheckedColor : control.buttonStyle.color, control.buttonStyle.checkedColor)
    color: control.active ? Style.handleMouseStates(control, Style.activeStyle.primary.color) : Style.handleMouseStates(control, Style.base.primary.color)
    clip: true

    Text {
      x: -width / 4
      y: parent.height / 6
      height: parent.height * 1.5
      width: height
      font { pointSize: 100; family: Style.iconFontFamily }
      text: control.robotAction && control.robotAction.icon || ''
      color: '#44888888'
      fontSizeMode: Text.Fit
      minimumPointSize: 6
      horizontalAlignment: Text.AlignHCenter
    }
    // Status text for toggle actions
    Text {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.bottomMargin: Units.pt(2)
      anchors.rightMargin: Units.pt(4)
      color: Style.getTextColor(parent.color)
      height: parent.height * 0.25
      width: parent.width
      horizontalAlignment: Text.AlignRight
      font { pointSize: 100 }
      text: d.executor.state
      fontSizeMode: Text.Fit
      minimumPointSize: 6
      opacity: 0.6
    }
  }

  QtObject {
    id: d
    property RobotActionExecutor executor: RobotActionExecutor {
      action: control.robotAction
    }
  }

  onClicked: {
    if (!robotAction) return
    if (d.executor.active) d.executor.cancel()
    else d.executor.execute()
  }

  ToolTip.text: text
  ToolTip.delay: 500
  ToolTip.visible: contentItem.truncated && control.hovered
}

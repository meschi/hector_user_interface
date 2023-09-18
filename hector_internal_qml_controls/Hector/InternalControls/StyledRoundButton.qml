import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Utils 1.0
import Hector.Style 1.0

RoundButton {
  id: control
  property var style: Style.base
  property var buttonStyle: Style.buttonStyle(style)

  hoverEnabled: true
  font: Style.button.font

  contentItem: Text {
    text: control.text
    font: control.font
    opacity: enabled ? 1 : 0.3
    color: control.flat ? Style.handleMouseStates(control, control.checkable ? (control.checked ? control.buttonStyle.checkedColor : control.buttonStyle.uncheckedColor) : control.buttonStyle.color)
                        : Style.getTextColor(control.background.color)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }

  background: Rectangle {
    implicitWidth: Units.pt(20)
    implicitHeight: Units.pt(20)
    radius: control.radius
    visible: !control.flat
    opacity: enabled ? 1 : 0.3
    color: Style.handleMouseStates(control, control.checkable ? control.buttonStyle.uncheckedColor : control.buttonStyle.color, control.buttonStyle.checkedColor)
  }
}
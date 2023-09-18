import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Utils 1.0
import Hector.Style 1.0

TabButton {
  id: control
  property var style: Style.base
  property var buttonStyle: Style.buttonStyle(style)

  font: Style.button.font
  hoverEnabled: true

  contentItem: Text {
    text: control.text
    font: control.font
    opacity: enabled ? 1 : 0.3
    color: control.flat ? (control.checkable ? (control.checked ? control.buttonStyle.checkedColor : control.buttonStyle.uncheckedColor) : control.buttonStyle.color)
                        : (control.checked ? Style.getTextColor(Style.background.content) : Style.getTextColor(control.background.color))
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }

  background: Rectangle {
    implicitWidth: Units.pt(50)
    implicitHeight: Style.button.defaultHeight
    visible: !control.flat && !control.checked
    opacity: enabled ? 1 : 0.3
    color: Style.handleMouseStates(control, control.buttonStyle.color, Style.background.content)
  }
}
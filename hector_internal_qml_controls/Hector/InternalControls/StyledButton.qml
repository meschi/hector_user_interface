import QtQuick 2.6
import QtQuick.Controls 2.2
import Hector.Utils 1.0
import Hector.Style 1.0

Button {
  id: control
  property var style: Style.base
  property var buttonStyle: Style.buttonStyle(style)
  
  padding: Units.pt(2)
  font: Style.button.font
  hoverEnabled: true

  contentItem: Text {
    text: control.text
    font: control.font
    leftPadding: control.leftPadding
    rightPadding: control.rightPadding
    topPadding: control.topPadding
    bottomPadding: control.bottomPadding
    opacity: enabled ? 1 : 0.3
    color: control.flat ? (control.checkable ? (control.checked ? control.buttonStyle.checkedColor : control.buttonStyle.uncheckedColor) : control.buttonStyle.color)
                        : Style.getTextColor(control.background.color)
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }

  background: Rectangle {
    implicitWidth: Units.pt(50)
    implicitHeight: Style.button.defaultHeight
    visible: !control.flat
    opacity: enabled ? 1 : 0.3
    color: Style.handleMouseStates(control, control.checkable ? control.buttonStyle.uncheckedColor : control.buttonStyle.color, control.buttonStyle.checkedColor)
  }
}
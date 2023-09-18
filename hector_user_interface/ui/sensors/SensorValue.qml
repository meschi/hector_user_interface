import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0

Rectangle {
  id: control
  property alias value: valueText.text
  property alias unit: unitText.text
  property alias icon: iconText.text
  property bool warn: false
  property bool dangerous: false

  implicitWidth: mainLayout.implicitWidth + 2 * horizontalPadding
  implicitHeight: mainLayout.implicitHeight + 2 * verticalPadding
  property real horizontalPadding: Units.pt(8)
  property real verticalPadding: Units.pt(6)
  clip: true
  radius: 0.25 * height
  color: Style.background.content
  border { color: iconBackground.color; width: dangerous || warn ? Units.pt(2) : 0 }

  RowLayout {
    id: mainLayout
    anchors.fill: parent
    spacing: 0
    Rectangle {
      id: iconBackground
      Layout.fillHeight: true
      color: dangerous ? Style.colors.status.error
                       : warn ? Style.colors.status.warn
                              : Style.colors.status.ok
      width: Units.pt(20)
      radius: control.radius
      Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        color: parent.color
        width: control.radius
      }
      Text {
        id: iconText
        anchors.centerIn: parent
        font.family: Style.iconFontFamily
        font.pointSize: 20
        color: Style.getTextColor(iconBackground.color)
      }
    }
    Text {
      id: valueText
    }
    Text {
      id: unitText
      font.pointSize: 8
      visible: text.length > 0
    }
  }
}

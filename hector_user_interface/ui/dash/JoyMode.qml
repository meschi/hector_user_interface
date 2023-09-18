import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0


Rectangle {
  id: root
  color: Style.activeStyle.primary.color
  implicitHeight: Units.pt(16)

  Subscriber {
    id: profileSubscriber
    topic: "/joy_teleop_profile"
  }

  Subscriber {
    id: driveDirectionSubscriber
    topic: "/joy_teleop_direction"
  }

  QtObject {
    id: d
    property string driveMode: profileSubscriber.message && profileSubscriber.message.data || "Loading..."
    property bool reverse: driveDirectionSubscriber.message && driveDirectionSubscriber.message.data < 0 || false
  }

  RowLayout {
    anchors.fill: parent
    Rectangle {
      Layout.fillHeight: true
      Layout.preferredWidth: height
      color: Style.getTextColor(root.color)
      AutoSizeText {
        margins: Units.pt(2)
        color: root.color
        font.family: Style.iconFontFamily
        text: Style.icons.gamepad
      }
    }
    Text {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.margins: Units.pt(2)
      color: Style.getTextColor(root.color)
      fontSizeMode: Text.Fit
      minimumPointSize: 6
      font.pointSize: 100
      horizontalAlignment: Text.AlignHCenter
      text: d.driveMode
    }
    Rectangle {
      Layout.fillHeight: true
      Layout.preferredWidth: height
      color: Style.getTextColor(root.color)
      opacity: d.driveMode === "drive" && d.reverse ? 1 : 0
      AutoSizeText {
        margins: Units.pt(2)
        color: root.color
        font.weight: Font.Bold
        text: "R"
      }
    }
  }
}
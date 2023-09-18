import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

Item {
  id: root
  implicitWidth: Math.max(estopDetails.implicitWidth, estopStatus.implicitWidth)
  implicitHeight: estopDetails.implicitHeight + estopStatus.implicitHeight
  onVisibleChanged: {
    if (!visible) estopDetails.showDetails = false
  }

  property var estopStates: {
    if (!estopSubscriber.message) return []
    var result = []
    for (var i = 0; i < estopSubscriber.message.names.length; ++i) {
      result.push({name: estopSubscriber.message.names.at(i), value: estopSubscriber.message.values.at(i)})
    }
    return result
  }
  property int activeEstopCount: {
    if (!estopStates) return 0
    var count = 0
    for (let estop of estopStates) {
      if (estop.value) ++count
    }
    return count
  }

  Subscriber {
    id: estopSubscriber
    topic: "/e_stop_manager/e_stop_list"
  }

  Rectangle {
    id: estopStatus
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    implicitHeight: eStopLayout.implicitHeight
    implicitWidth: eStopLayout.implicitWidth
    color: Style.emergencyStop.checkedColor

    RowLayout {
      id: eStopLayout
      anchors.fill: parent
      Icon {
        Layout.preferredWidth: Units.pt(36)
        Layout.preferredHeight: Units.pt(36)
        Layout.margins: Units.pt(8)
        backgroundColor: Style.getTextColor(Style.emergencyStop.checkedColor)
        color: Style.emergencyStop.checkedColor
        text: Style.icons.stop
      }

      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        Layout.rightMargin: Units.pt(12)
        Text {
          Layout.fillWidth: true
          font: Style.fonts.header
          text: "Stopped!"
          color: Style.getTextColor(Style.emergencyStop.checkedColor)
        }

        Text {
          Layout.fillWidth: true
          font: Style.fonts.subHeader
          text: activeEstopCount + " E-Stop" + (activeEstopCount == 1 ? "" : "s") + " active"
          color: Style.getTextColor(Style.emergencyStop.checkedColor)
        }
      }
    }

    Text {
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      anchors.rightMargin: Units.pt(8)
      anchors.bottomMargin: Units.pt(4)
      color: Style.getTextColor(Style.emergencyStop.checkedColor)
      font: Style.fonts.tiny
      text: estopDetails.showDetails ? "Hide" : "Show Details"
    }

    MouseArea {
      anchors.fill: parent
      onClicked: estopDetails.showDetails = !estopDetails.showDetails
    }
  }

  Rectangle {
    id: estopDetails
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: estopStatus.top
    property var showDetails: false
    height: showDetails ? Math.min(root.estopStates.length * Units.pt(24) + Units.pt(16), Units.pt(320)) : 0
    Behavior on height { NumberAnimation {} }
    color: Style.background.content
    ListView {
      id: estopListView
      anchors.fill: parent
      anchors.leftMargin: Units.pt(8)
      anchors.rightMargin: Units.pt(8)
      topMargin: Units.pt(8)
      bottomMargin: Units.pt(8)
      clip: true

      model: root.estopStates
      delegate: EStopStatusItem {
        height: Units.pt(24)
        width: parent.width
        name: modelData.name
        value: modelData.value
      }
    }
  }
}

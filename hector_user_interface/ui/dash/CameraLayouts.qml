import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0

Rectangle {
  id: root
  property bool locked: true
  property var configuration
  signal configurationUpdated

  color: Style.background.container
  
  ColumnLayout {
    anchors.fill: root

    RowLayout  {
      Layout.fillWidth: true
      Text {
        text: "Camera Layouts"
        font: Style.fonts.subHeader
        Layout.fillWidth: true
      }
      Button {
        Layout.preferredWidth: Units.pt(32)
        text: root.locked ? Style.icons.lockClosed : Style.icons.lockOpen
        onClicked: root.locked = !root.locked
      }
    }
    QtObject {
      id: d
      function removeLayout(layout) {
        for (let i = 0; i < root.configuration.length; ++i) {
          if (root.configuration[i].layout_name !== layout.layout_name) continue
          root.configuration.splice(i, 1)
          root.configuration = root.configuration // updates displayed list
          root.configurationUpdated()
          break
        }
      }
    }

    ListView {
      id: cameraLayoutsListView
      Layout.fillHeight: true
      Layout.fillWidth: true
      spacing: Units.pt(2)
      clip: true
      model: configuration

      delegate: Rectangle {
        color: Style.background.content
        width: root.width 
        height: Units.pt(24)
        Text {
          anchors.centerIn: parent
          text: modelData.layout_name
        }
        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton
          hoverEnabled: true
          onClicked: {
            leftCameraView.transitionsEnabled = false
            rightCameraView.transitionsEnabled = false

            leftCameraView.selectCameraByName(modelData.left_cam)
            rightCameraView.selectCameraByName(modelData.right_cam)

            leftCameraView.transitionsEnabled = true
            rightCameraView.transitionsEnabled = true
          }
        }
        Button {
          height: parent.height
          width: height
          anchors.right: parent.right
          anchors.verticalCenter: parent.verticalCenter
          visible: !locked
          flat: true
          Icon {
            anchors.fill: parent
            flat: true
            text: parent.hovered ? Style.icons.trashOpen : Style.icons.trash
          }
          onClicked: d.removeLayout(modelData)
        }
      }

      footer: RowLayout {
        width: parent.width
        visible: !locked
        spacing: 0
        TextField {
          id: layoutNameTextField
          Layout.fillWidth: true
          Layout.topMargin: cameraLayoutsListView.spacing
          placeholderText: qsTr("Name")
          hoverEnabled: true
        }
        StyledButton {
          Layout.preferredHeight: layoutNameTextField.height
          Layout.topMargin: cameraLayoutsListView.spacing
          style: Style.activeStyle
          text: qsTr("Add")
          onClicked: {
            if (!layoutNameTextField.text) return
            if(!configuration) configuration = []
            var layout = {}
            layout.layout_name = layoutNameTextField.text
            layout.left_cam = leftCameraView.selectedCamera ? leftCameraView.selectedCamera.name : ""
            layout.right_cam = rightCameraView.selectedCamera ? rightCameraView.selectedCamera.name : ""
            configuration.push(layout)
            configuration = configuration
            
            layoutNameTextField.clear()
            root.configurationUpdated()
          }
        }
      }
    }
  }
}
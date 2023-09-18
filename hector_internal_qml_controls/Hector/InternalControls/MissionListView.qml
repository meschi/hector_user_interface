import QtQuick 2.3
import QtQuick.Controls 2.1
import Hector.Utils 1.0
import Hector.Style 1.0

ListView {
  id: control
  property int lastCount: 0
  property var style
  property bool disableMouseSelection: true
  spacing: 0
  currentIndex: -1

  header: Button {
    id: headerButton
    height: Units.pt(24)
    width: parent.width

    MissionTask {
      anchors.fill: parent
      current: control.currentIndex == -1
      style: control.style
      task: ({name: "Start of Mission"})
    }
    background: Rectangle {
      opacity: enabled ? 1.0 : 0.3
      color: Style.handleMouseStates(headerButton, control.currentIndex == -1 ? control.style.primary.color : Style.background.content)
    }

    onClicked: control.currentIndex = -1
  }

  delegate: StyledButton {
    id: item
    property bool isCurrent: ListView.isCurrentItem
    height: Units.pt(24)
    width: parent.width
    flat: !ListView.isCurrentItem
    style: control.style
    
    MissionTask {
      anchors.fill: parent
      current: item.isCurrent
      style: control.style
      task: modelData
    }

    onClicked: function()  {
      if(!disableMouseSelection) {
        control.currentIndex = index
      } 
    }
  }
}
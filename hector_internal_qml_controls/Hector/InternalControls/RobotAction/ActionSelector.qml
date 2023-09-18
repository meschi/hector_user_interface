import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.Controls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0

Item {
  id: root
  property var type
  property var actions
  property var selectedActions: []

  function reset() {
    selectedActions = []
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: Units.pt(2)
    
    RowLayout {
      id: addAction
      Layout.margins: Units.pt(5)
      spacing: Units.pt(2)
      ComboBox {
        id: actionComboBox
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(24)
        textRole: "name"
        model: {
          // Sort actions by name
          let tmp = Array.from(root.actions)
          tmp.sort(function(action1, action2) {
            try {
              if (action1.name.toLowerCase() < action2.name.toLowerCase()) return -1
              if (action1.name.toLowerCase() > action2.name.toLowerCase()) return 1
              return 0
            } catch(e) {
              Ros.error("ActionSelector: Ordering list failed" + e + "\nStack: \n---\n" + e.stack)
              return 0
            }
          })
          return tmp
        }
      }

      Button {
        Layout.preferredHeight: Units.pt(24)
        text: "Add"
        
        onClicked: {
          // .push() doesn't update the list
          selectedActions = [...selectedActions,
                              {"name": actionComboBox.model[actionComboBox.currentIndex].name,
                              "action": actionComboBox.model[actionComboBox.currentIndex].uuid}]
          checkValid()
        }
      }
      Button {
        Layout.preferredHeight: Units.pt(24)
        text: "Clear"

        onClicked: {
          actionSelector.reset()
          checkValid()
        }
      }
    }

    Rectangle {
      color: Style.background.container
      Layout.fillHeight: true
      Layout.margins: Units.pt(5)
      Layout.fillWidth: true
      implicitHeight: subactionsListView.implicitHeight
      ListView {
        id: subactionsListView
        anchors.fill: parent
        anchors.margins: Units.pt(4)
        clip: true
        model: selectedActions
        delegate: ColumnLayout {
          width: parent.width
          height: Units.pt(30)
          property var action: RobotActionManager.getAction(modelData.action)
          spacing: 0
          RowLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Text {
              id: fixedText
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              font: Style.fonts.subHeader
              text: {
                return modelData.name || (action && action.name) || ""
              }
            }
            TextField {
              id: editableText
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              visible: false
              text: fixedText.text
            }
            Text {
              text: action && action.name || ""
              font: Style.fonts.small
              Layout.alignment: Qt.AlignRight
              visible: type === "toggle"
            }
            Button {
              Layout.preferredWidth: Units.pt(30)
              text: fixedText.visible ? Style.icons.edit : Style.icons.check
              font { pointSize: Units.pt(8); family: Style.iconFontFamily }
              
              onClicked: {
                if (editableText.visible) {
                  selectedActions[index].name = editableText.text
                  selectedActions = selectedActions
                }
                editableText.visible = !editableText.visible
                fixedText.visible = !fixedText.visible
              }
              visible: type === "toggle"
            }
            Button {
              Layout.preferredWidth: Units.pt(20)
              text: "↑"
              onClicked: subactionsListView.moveActionOnList(index, "up")
            }
            Button {
              Layout.preferredWidth: Units.pt(20)
              text: "↓"
              onClicked: subactionsListView.moveActionOnList(index, "down")
            }
          }
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Units.pt(1)
            color: "#1E000000"
            visible: (index !== subactionsListView.count - 1)
          }
        }

        function moveActionOnList(i, direction)
        {
          if (i == null) return
          switch (direction) {
          case 'up':
            if (i > 0) {
              var aux = selectedActions.splice(i, 1)
              selectedActions.splice(i-1,0,aux[0])
              selectedActions = selectedActions
            }
            break
          case 'down':
            if (i < selectedActions.length-1) {
              var aux = selectedActions.splice(i, 1)
              selectedActions.splice(i+1,0,aux[0])
              selectedActions = selectedActions
            }
          }
        }
      }
    }
  }
}

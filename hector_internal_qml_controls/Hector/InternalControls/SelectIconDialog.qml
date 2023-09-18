import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.Controls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0

Dialog {
  id: root
  property string icon
  standardButtons: Dialog.Ok | Dialog.Cancel
  closePolicy: Popup.NoAutoClose
  focus: true
  width: Units.pt(240)
  height: Units.pt(360)

  GridLayout {
    anchors.fill: parent
    columns: 2
    AutoSizeText {
      Layout.preferredHeight: Units.pt(16)
      Layout.preferredWidth: Units.pt(16)
      font.family: Style.iconFontFamily
      text: root.icon
    }
    ColumnLayout {
      Layout.preferredHeight: implicitHeight
      Layout.fillWidth: true
      TextField {
        Layout.fillWidth: true
        text: root.icon && Style.iconToCharCode(root.icon).toString(16) || ''
        onTextChanged: {
          if (text.length > 5) return
          var number = 0
          try {
            number = parseInt(text, 16)
          } catch (e) { return }
          root.icon = Style.iconFromCharCode(number)
        }
      }
      Text {
        text: 'For codes <a href="https://cdn.materialdesignicons.com/5.1.45/">check here</a>'
        onLinkActivated: Qt.openUrlExternally(link)
      }
    }

    ListView {
      Layout.columnSpan: 2
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      model: {
        var result = []
        for (var prop in Style.icons) {
          if (prop === 'objectName' || typeof Style.icons[prop] !== 'string') continue
          result.push({name: prop, icon: Style.icons[prop]})
        }
        return result
      }
      delegate: StyledButton {
        flat: true
        RowLayout {
          Text {
            font.family: Style.iconFontFamily
            text: modelData.icon
          }
          Text {
            text: modelData.name
          }
        }
        onClicked: {
          console.log(modelData.icon.length)
        root.icon = modelData.icon
        }
      }
    }
  }
}
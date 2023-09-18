import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0
import Ros 1.0


Rectangle {
  id: root
  property var style
  property var parameters: []

  signal parametersUpdated

  ColumnLayout {
    anchors.fill: parent

    ListView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(2)
      clip: true

      model: parameters

      delegate: Rectangle {
        color: Style.background.content
        implicitHeight: itemLayout.implicitHeight + Units.pt(8)
        width: parent.width

        RowLayout {
          id: itemLayout
          anchors { fill: parent; topMargin: Units.pt(4); bottomMargin: Units.pt(4); leftMargin: Units.pt(8); rightMargin: Units.pt(8) }
          Text {
            id: paramNameText
            Layout.preferredWidth: Units.pt(96)
            Layout.alignment: Qt.AlignVCenter
            text: modelData.name
            elide: Text.ElideRight
            SimpleToolTip { text: modelData.name; visible: parent.truncated }
          }

        
          Loader {
            id: loader
            Layout.fillWidth: parameter.type != DynamicReconfigureParameter.Bool && parameter.type != DynamicReconfigureParameter.Uninitialized
            Layout.alignment: parameter.type == DynamicReconfigureParameter.Bool ? Qt.AlignRight : Qt.AlignVCenter

            property DynamicReconfigureParameter parameter: DynamicReconfigureParameter {
              namespace: modelData.namespace
              name: modelData.parameter
            }

            sourceComponent: {
              switch(parameter.type) {
                case DynamicReconfigureParameter.Double:
                  return sliderComponent
                case DynamicReconfigureParameter.Bool:
                  return checkboxComponent
                case DynamicReconfigureParameter.Int:
                  return sliderComponent
                case DynamicReconfigureParameter.String:
                  return textfieldComponent
                case DynamicReconfigureParameter.Enum:
                  return comboBoxComponent
                case DynamicReconfigureParameter.Uninitialized:
                  return uninitializedComponent
                default:
                  Ros.error("SettingsTab: unsupported param type " + modelData.type)
                  return
              }
            }
          }
        }

        Rectangle {
          anchors { bottom: parent.bottom; left: parent.left; right: parent.right; bottomMargin: Units.pt(-0.5) }
          height: Units.pt(1)
          color: Style.base.primary.color
          visible: index != (parameters.length - 1)
        }
      }
    }

    StyledButton {
      id: editButton
      Layout.fillWidth: true
      Layout.preferredHeight: Units.pt(24)
      style: root.style
      text: "Edit Quick Settings"
      onClicked: dynamicReconfigureDialog.edit(root.parameters)
    }
  }

  DynamicReconfigureDialog {
    id: dynamicReconfigureDialog
    onSelectionFinished: function (result) {
      parameters = result
      root.parametersUpdated()
    }
  }

  Component {
    id: sliderComponent
    RowLayout {
      Text {
        Layout.preferredWidth: Units.pt(36)
        text: parameter.min || 0
        elide: Text.ElideRight
        
      }
      Slider {
        id: slider
        Layout.fillWidth: true
        from: parameter.min || 0
        value: parameter.value || 0.5
        to: parameter.max || 1
        stepSize: parameter.type == DynamicReconfigureParameter.Int ? 1 : 0
        onMoved: parameter.value = value

        background: Rectangle {
          x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2
          width: slider.availableWidth; height: Units.pt(4)
          radius: height / 2
          color: Style.background.container

          // Colored background until slider position
          Rectangle {
            width: slider.visualPosition * parent.width
            height: parent.height
            color: style.primary.color
            radius: height / 2
          }
        }
        handle: Rectangle {
          x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
          y: slider.topPadding + slider.availableHeight / 2 - height / 2
          implicitWidth: Units.pt(12)
          implicitHeight: Units.pt(8)
          radius: Units.pt(4)
          color: slider.pressed ? Style.background.container : Style.background.content
          border.color: style.primary.color
        }
      }

      Text {
        Layout.preferredWidth: Units.pt(36)
        text: parameter.max || 1
        elide: Text.ElideRight
      }

      TextField {
        Layout.preferredWidth: Units.pt(40)
        Layout.alignment: Qt.AlignVCenter
        maximumLength: 5
        selectByMouse: true
        text: parameter.value || 0.5
        DoubleValidator { id: doubleValidator }
        IntValidator { id: intValidator }
        validator: parameter.type == DynamicReconfigureParameter.Int ? intValidator : doubleValidator
        onAccepted: parameter.value = parseFloat(text)
      }
    }
  }

  Component {
    id: checkboxComponent
    CheckBox {
      Layout.alignment: Qt.AlignRight
      checked: parameter.value || false
      icon.color: style.primary.color
      onToggled: parameter.value = checked
    }
  }

  Component {
    id: textfieldComponent
    TextField {
      text: parameter.value || ""
      onAccepted: parameter.value = text
    }
  }

  Component {
    id: comboBoxComponent
    ComboBox {
      model: parameter.enumOptions
      textRole: "name"
      currentIndex: parameter.enumOptions.findIndex(opt => opt.value === parameter.value)
      onActivated: parameter.value = parameter.enumOptions[index].value
    }
  }

  Component {
    id: uninitializedComponent
    Text {
      text: "Loading parameter..."
    }
  }
}
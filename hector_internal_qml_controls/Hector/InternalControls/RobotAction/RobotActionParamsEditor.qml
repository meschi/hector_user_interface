import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Utils 1.0
import Hector.Style 1.0
import Ros 1.0

Item {
  id: control
  property string type
  property string label
  property string messageType
  property alias evaluateParams: evaluateParamsCheckBox.checked
  property alias params: paramTextArea.text
  onTypeChanged: reset()
  onMessageTypeChanged: reset()
  implicitHeight: gridLayout.implicitHeight
  implicitWidth: gridLayout.implicitWidth

  QtObject {
    id: d
    property string type: control.type && control.type.toLowerCase() || ""
    property bool hasEvaluateParams: ["action", "behavior", "service", "topic"].includes(d.type)
  }

  function initFromTopic(topic) {
    if (d.type == "service") {
      Service.callAsync("/rosapi/service_type", "rosapi/ServiceType", {"service": topic}, function (result) {
        if (!result || !result.type) {
          messageType = ""
          paramErrorText.showError("Failed to obtain service type!\nCheck the topic name and make sure rosapi_node is running!")
          return
        }
        messageType = result.type || ""
      })
    } else if (d.type == "behavior") {
      messageType = "flexbe_msgs/BehaviorExecutionGoal"
      root.checkValid()
    } else if (d.type == "topic" || d.type == "action") {
      if (d.type == "action") topic += "/goal"
      Service.callAsync("/rosapi/topic_type", "rosapi/TopicType", {"topic": topic}, function (result) {
        if (!result || !result.type) {
          messageType = ""
          paramErrorText.showError("Failed to obtain message type!\nCheck the topic name and make sure rosapi_node is running!")
          return
        }
        if (d.type == "action") {
          if (!result.type.endsWith("ActionGoal")) {
            messageType = ""
            paramErrorText.showError("Invalid action topic! Message type was not ActionGoal but: " + result.type)
            return
          }
          messageType = result.type.substr(0, result.type.length - 10) + "Goal"
          return
        }
        messageType = result.type || ""
      })
    } else if (d.type == "javascript" || d.type == "toggle") {
      messageType = ""
    }
  }

  function reset() {
    if (d.type == "javascript") {
      params = "// Enter javascript code to execute on button press here\n"
      return
    }
    if (d.type == "toggle") {
      params = "// Mapping from 'msg' variable to index\nreturn null // simple switching"
      return 
    }
    if (!messageType) {
      params = ""
      return
    }
    let emptyMessage = "";
    if (d.type == "service") {
      emptyMessage = JSON.stringify(Ros.createEmptyServiceRequest(messageType), null, 2) || ""
    } else {
      var msg = Ros.createEmptyMessage(messageType)
      emptyMessage = JSON.stringify(msg, null, 2) || ""
    }
    if (evaluateParamsCheckBox.checked) params = "return (" + emptyMessage + ")"
    else params = emptyMessage
  }

  function validate() {
    paramErrorText.visible = false
    if (d.type == "javascript" || evaluateParams || d.type == "toggle") return true
    
    try {
      JSON.parse(params)
    } catch (e) {
      paramErrorText.showError("Value is not valid JSON!")
      return false
    }
    return true
  }

  GridLayout {
    id: gridLayout
    anchors.fill: parent
    columns: 2


    Text {
      text: label ? label : "Value"
      font: Style.fonts.label
    }

    Button {
      Layout.alignment: Qt.AlignRight
      Layout.preferredHeight: Units.pt(24)
      leftPadding: Units.pt(8); rightPadding: Units.pt(8)
      text: "Reset"
      onClicked: control.reset()
    }

    Text {
      id: paramErrorText
      Layout.columnSpan: 2
      visible: false
      color: "red"
      font: Style.fonts.small

      function showError(msg) {
        text = msg
        visible = true
      }
    }

    CheckBox {
      id: evaluateParamsCheckBox
      Layout.columnSpan: 2
      Layout.fillWidth: true
      visible: d.hasEvaluateParams
      text: "Evaluate params"
    }

    Rectangle {
      Layout.columnSpan: 2
      Layout.fillWidth: true
      Layout.fillHeight: true
      border { color: "black"; width: 1}
      ScrollView {
        anchors.fill: parent
        TextArea {
          id: paramTextArea
          cursorVisible: focus
          selectByMouse: true
          height: Units.pt(40)
          text: ""
          property bool evaluateParams: d.hasEvaluateParams && evaluateParamsCheckBox.checked
          onEvaluateParamsChanged: {
            if (evaluateParams) {
              try { JSON.parse(text) } catch (e) { return } // If valid JSON, replace it with simple return
              text = "return (" + text + ")"
            } else if (text.startsWith("return (")) {
              let removedText = text.substr(8).slice(0, -1)
              try { JSON.parse(removedText) } catch (e) { return } // If return extension can be simply reversed, we do that
              text = removedText
            }
          }
        }
      }
    }
  }
}

import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.InternalControls 1.0
import Hector.Controls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0
import Ros 1.0

Dialog {
  id: root
  property var actions: []
  property var editItem: null
  //! Emitted when editing is finished. Called with false if editing was canceled.
  signal editFinished(var item)

  parent: ApplicationWindow.overlay
  width: Units.pt(320); height: Units.pt(480)
  // Center dialog
  x: parent.x + (parent.width - width) / 2
  y: parent.y + (parent.height - height) / 2
  title: "Add Robot Control Action"
  standardButtons: Dialog.Ok | Dialog.Cancel
  closePolicy: Popup.NoAutoClose
  focus: true

  function edit(item) {
    editItem = item
    nameTextField.text = item && item.name || ""
    iconButton.text = item && item.icon || "Select icon"
    let type = item && item.type || null
    if (type === "action" && item.messageType === "flexbe_msgs/BehaviorExecutionAction") {
      type = "behavior"
    }
    var index = typeComboBox.find(type, Qt.MatchFixedString)
    topicComboBox.currentTopic = item && item.topic || ""
    topicComboBox.editText = item && item.topic || ""
    typeComboBox.currentIndex = Math.max(0, index)
    if (["composite", "toggle"].includes(item.type)) actionSelector.selectedActions = item.subactions
    parallelCheckbox.checked = Conversions.toBoolean(item.parallel)
    if (item.type == "toggle") topicFeedbackCheckBox.checked = !!item.topic
    paramsEditor.messageType = item && item.messageType || ""
    var evaluateParams = false
    if (item && item.evaluateParams) {
      evaluateParams = typeof item.evaluateParams === "string" ? item.evaluateParams.toLowerCase() !== "false"
                                                               : !!item.evaluateParams
    }
    paramsEditor.evaluateParams = evaluateParams
    paramsEditor.params = item && item.params || ""
    open()
  }

  function reset() {
    nameTextField.text = ""
    iconButton.text = "Select icon"
    paramsEditor.params = ""
    paramsEditor.evaluateParams = false
    typeComboBox.currentIndex = 0
    topicComboBox.editText = ""
    parallelCheckbox.checked = false
    actionSelector.reset()
  }

  SelectIconDialog {
    id: selectIconDialog
    onAccepted: {
      iconButton.text = icon
    }
  }

  GridLayout {
    anchors.fill: parent
    columns: 2

    // === NAME ===
    Text {
      text: "Name:"
      font: Style.fonts.label
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: Units.pt(24)
      TextField {
        id: nameTextField
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(24)
        cursorVisible: focus
        selectByMouse: true
        onTextChanged: root.checkValid()
      }

      Button {
        id: iconButton
        Layout.preferredWidth: text.length < 5 ? 2*height : -1
        Layout.preferredHeight: Units.pt(24)
        font: Style.iconFontFamily
        text: 'Select icon'
        onClicked: {
          if (text.length < 5)
            selectIconDialog.icon = text
          selectIconDialog.open()
        }
      }
    }

    Text {
      id: nameErrorText
      Layout.columnSpan: 2
      visible: false
      color: "red"

      function showError(msg) {
        text = msg
        visible = true
      }
    }

    // === TYPE ===
    Text {
      text: "Type:"
      font: Style.fonts.label
    }

    ComboBox {
      id: typeComboBox
      Layout.fillWidth: true
      Layout.preferredHeight: Units.pt(24)
      editable: false
      model: ["Action", "Behavior", "Composite", "JavaScript", "Service", "Toggle", "Topic"]
      property string currentType: currentText.toLowerCase()
      onAccepted: checkValid()
    }

    SectionHeader {
      Layout.topMargin: Units.pt(8)
      Layout.columnSpan: 2
      Layout.fillWidth: true
      text: "Configuration"
      font: Style.fonts.label
    }

    // === COMPOSITE AND TOGGLE ===
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.columnSpan: 2
      visible: ["composite", "toggle"].includes(typeComboBox.currentType)

      ActionSelector {
        id: actionSelector
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Units.pt(40)
        actions: root.actions
        type: typeComboBox.currentType
        onSelectedActionsChanged: root.checkValid()
      }

      CheckBox {
        id: parallelCheckbox
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(24)
        text: "Parallel"
        font: Style.fonts.label
        visible: typeComboBox.currentType === "composite"
      }
      CheckBox {
        id: topicFeedbackCheckBox
        Layout.fillWidth: true
        Layout.preferredHeight: Units.pt(24)
        text: "Topic Feedback"
        font: Style.fonts.label
        Layout.columnSpan: 2
        visible: typeComboBox.currentType === "toggle"
      }
    }

    // === TOPIC ===
    Text {
      visible: topicComboBox.visible
      text: "Topic:"
      font: Style.fonts.label
    }

    TopicComboBox {
      id: topicComboBox
      Layout.fillWidth: true
      autoLoad: true
      editable: true
      type: {
        switch (typeComboBox.currentType) {
          case "behavior":
          case "action":
            return TopicComboBox.Action
          case "service":
            return TopicComboBox.Service
          case "toggle":
          case "topic":
          default:
            return TopicComboBox.Topic
        }
      }
      // For behaviors show only actions that accept BehaviorExecutionAction
      messageType: typeComboBox.currentType == "behavior" ? "flexbe_msgs/BehaviorExecutionAction" : ""
      visible: {
        if (["action", "behavior", "service", "topic"].includes(typeComboBox.currentType)) return true
        if (typeComboBox.currentType == "toggle") return topicFeedbackCheckBox.checked
        return false
      }
      property string currentTopic
      onEditTextChanged: {
        if (currentTopic && currentTopic == editText) return
        currentTopic = editText
        paramsEditor.initFromTopic(editText)
      }

    }

    // === VALUE ===
    RobotActionParamsEditor {
      id: paramsEditor
      Layout.columnSpan: 2
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: Units.pt(40)
      type: typeComboBox.currentType
      onEvaluateParamsChanged: root.checkValid()
      onParamsChanged: root.checkValid()
      visible: {
        if (["action", "behavior", "javascript", "service", "topic"].includes(typeComboBox.currentType)) return true
        if (typeComboBox.currentType == "toggle") return topicFeedbackCheckBox.checked
        return false
      }
    }
  }

  function checkValid() {
    let valid = true
    if (["composite", "toggle"].includes(typeComboBox.currentType)) {
      valid = actionSelector.selectedActions.length > 0
    }
    nameErrorText.visible = false
    if (nameTextField.text == "") { valid = false; nameErrorText.showError("Name is required!") }
    if (typeComboBox.currentIndex < 0) valid = false
    if (!paramsEditor.validate()) valid = false

    let button = addActionDialog.standardButton(Dialog.Ok)
    if (button) button.enabled = valid
    return valid
  }
  onAboutToShow: {
    topicComboBox.reload()
  }
  onRejected: {
    root.editFinished(false)
    reset()
  }
  onAccepted: {
    if (!checkValid()) {
      if (nameTextField.text === "") nameTextField.focus = true
      visible = true
      return
    }
    let type = typeComboBox.currentType
    if (type == "behavior") type = "action"
    let messageType = paramsEditor.messageType
    if (type == "action" && messageType.endsWith("Goal")) {
      messageType = paramsEditor.messageType.substring(0, paramsEditor.messageType.length - 4) + "Action"
    }
    let topic = topicComboBox.currentTopic
    if (type === "toggle" && !topicFeedbackCheckBox.checked) topic = "" 
    root.editFinished({
      name: nameTextField.text,
      icon: iconButton.text.length < 5 ? iconButton.text : '',
      type: type,
      value: "",
      topic: topic,
      messageType: messageType,
      params: paramsEditor.params,
      evaluateParams: paramsEditor.evaluateParams,
      subactions: actionSelector.selectedActions,
      parallel: parallelCheckbox.checked
    })
    reset()
  }
}
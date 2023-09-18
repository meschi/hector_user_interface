import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0
import Ros 1.0


Dialog {
  id: root

  signal selectionFinished(var items)

  parent: ApplicationWindow.overlay
  width: Units.pt(500); height: Units.pt(400)
  x: parent.x + (parent.width - width) / 2
  y: parent.y + (parent.height - height) / 2
  title: "Add Parameters to Quick Settings"
  standardButtons: Dialog.Ok | Dialog.Cancel
  closePolicy: Popup.NoAutoClose
  modal: true
  focus: true


  
  function edit(parameters) {
    reset()
    d.selectedParams = parameters
    d.loadParameters()
    open()
  }

  function reset() {
    filterTextField.text = ""
    paramsListView.visible = true
    filterTextField.visible = true
    editNameList.visible = false
    d.selectedParams = []
    d.parameters = []
  }
  onRejected: reset()
  onAccepted: {
    visible = true // Need to change back to visible, otherwise paramsListView is also not visible
    // First accept switches to rename
    if (paramsListView.visible) {
      paramsListView.visible = false
      filterTextField.visible = false
      editNameList.model = d.parameters.filter(srv => srv.checked)
      editNameList.visible = true
      return
    }
    visible = false
    d.selectedParams = d.parameters.filter(srv => srv.checked).map(srv => srv.data)
    root.selectionFinished(d.selectedParams)
    reset()
  }

  ColumnLayout {
    anchors.fill: parent

    TextField {
      id: filterTextField
      Layout.fillWidth: true
      placeholderText: qsTr("Filter...")
    }

    ListView {
      id: paramsListView
      Layout.fillHeight: true
      Layout.fillWidth: true
      clip: true
      spacing: Units.pt(2)
      model: d.filteredParameters
      delegate: Rectangle {
        color: Style.background.container
        height: itemMainLayout.implicitHeight
        width: parent.width
        RowLayout {
          id: itemMainLayout
          anchors.fill: parent
          CheckBox {
            id: delegateCheckbox
            checked: modelData.checked
            onCheckedChanged: d.updateParameterChecked(modelData.data.namespace, modelData.data.parameter, checked)
          }
          RowLayout {
            Layout.fillWidth: true
            Text {
              Layout.fillWidth: true
              Layout.rightMargin: Units.pt(8)
              text: modelData.data.namespace + "/" + modelData.data.parameter
              elide: Text.ElideMiddle
              SimpleToolTip { text: parent.text; visible: parent.truncated }
            }
            Pill { Layout.preferredWidth: Units.pt(48); Layout.margins: Units.pt(4); text: d.getNameForType(modelData.data.type) }
          }
        }
        MouseArea {
          id: itemMouseArea
          anchors.fill: parent
          onClicked: delegateCheckbox.checked = !delegateCheckbox.checked
        }
      }

      BusyIndicator {
        id: loadingListIndicator
        anchors.centerIn: parent
      }
    }

    ListView {
      id: editNameList
      Layout.fillHeight: true
      Layout.fillWidth: true
      visible: false
      clip: true
      spacing: Units.pt(2)
      header: RowLayout {
        height: Units.pt(24)
        width: parent.width
        Text { Layout.preferredWidth: 1; font.bold: true; text: "Complete Name" }
        Text { Layout.preferredWidth: 1; font.bold: true; text: "Custom Name" }
      }
      delegate: Rectangle {
        color: Style.background.container
        implicitHeight: itemLayout.implicitHeight + Units.pt(8)
        width: parent.width
        RowLayout {
          id: itemLayout
          anchors.fill: parent
          Text {
            Layout.fillWidth: true
            Layout.preferredWidth: 1 // For equal division of available space
            Layout.margins: Units.pt(4)
            text: modelData.data.namespace + "/" + modelData.data.parameter
            elide: Text.ElideMiddle
            SimpleToolTip { text: parent.text; visible: parent.truncated }
          }
          TextField {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.margins: Units.pt(4)
            text: modelData.data.name
            selectByMouse: true
            onTextEdited: d.updateParameterName(modelData.data.namespace, modelData.data.parameter, text)
          }
        }
      }
    }
  }

  QtObject {
    id: d
    property var parameters: []
    property var reconfigureTopicRegex: new RegExp(/parameter_descriptions$/)
    // Blacklist camera settings
    property var blacklist: new RegExp(/\/compressed\/|\/compressedDepth\/|\/theora\//)
    property var selectedParams: []
    property var filteredParameters: {
      if (filterTextField.text.length == 0) return d.parameters

      const searchText = filterTextField.text
      return d.parameters.filter(srv => srv.data.parameter.includes(searchText) || srv.data.namespace.includes(searchText))
    }
    
    function getNameForType(type) {
      if (type == "str") return "string"
      return type
    }

    function loadParameters() {
      let parameters = []
      loadingListIndicator.running = true
      let topics = new Set()
      for (let topic of Ros.queryTopics("dynamic_reconfigure/ConfigDescription")) {
        if (!reconfigureTopicRegex.test(topic)) continue // skip topics that do not follow params structure
        if (blacklist.test(topic)) continue
        topics.add(topic)
      }

      function sortFn(a, b) {
        // First sort by checked, then based on full parameter name
        return (a.checked && !b.checked) || (!b.checked && (a.data.namespace + a.data.parameter) < (b.data.namespace + b.data.parameter))
      }

      let promises = []
      for (var topic of topics) {
        try {
          let namespace = topic.substr(0, topic.length - 23) // Remove /parameter_descriptions suffix
          let promise = new Promise((resolve) => {
            // Try to get parameter descriptions within 10 seconds
            Ros.waitForMessageAsync(topic, 10000, function (result) {
              if (!result) {
                Ros.error("Failed to get parameter descriptions for: " + namespace)
                resolve()
                return
              }
              try {
                for (let group of result.groups.toArray()) {
                  for (let parameter of group.parameters.toArray()) {
                    const config = d.getConfigForParam(namespace, parameter.name)
                    let data = {
                      data: {namespace: namespace, parameter: parameter.name, type: parameter.type, name: config.name},
                      checked: config.checked
                    }
                    HectorAlgorithms.insertSorted(parameters, data, sortFn)
                  }
                }
              } catch (e) {
                Ros.error("Error while getting parameters for " + namespace + ": " + e)
              }
              resolve()
            })
          })
          promises.push(promise)
        } catch(e) {
          Ros.error("DynamicReconfigureDialog: Error getting parameter description for " + namespace + "\nTrace: " + e)
        }
      }
      Promise.all(promises).then(() => {
        d.parameters = parameters
        loadingListIndicator.running = false
      })
    }

    function getConfigForParam(namespace, parameter) {
      for (let p of d.selectedParams) {
        if (p.namespace !== namespace || p.parameter !== parameter) continue
        return {checked: true, name: p.name}
      }
      return {checked: false, name: parameter}
    }

    function updateParameterChecked(namespace, parameter, checked) {
      let item = d.parameters.find(srv => srv.data.parameter === parameter && srv.data.namespace === namespace)
      if (!item) return
      item.checked = checked
    }

    function updateParameterName(namespace, parameter, name) {
      let item = d.parameters.find(srv => srv.data.parameter === parameter && srv.data.namespace === namespace)
      if (!item) return
      item.data.name = name
    }
  }
}
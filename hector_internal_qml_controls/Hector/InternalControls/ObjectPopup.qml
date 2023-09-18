import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Style 1.0
import Ros 1.0

Popup {
  id: root
  property alias backgroundColor: backgroundItem.color
  property var style
  property var objectProvider
  property QtObject objectDisplayInformationProvider: ObjectDisplayInformationProvider { color: style.primary.color } 
  property string objectServiceTopic
  property QtObject actionProvider: QtObject {
    function getActionsForObject(class_id, callback) {
      // Actions are a list of objects with name and value attributes.
      // For each action a button is generated with the name as text and on click the signal
      // actionSelected is emitted with the value of the action.
      // The callback has to be called at some point or the popup will be stuck loading the actions.
      // If there are no actions for this object class, pass an empty array '[]'.
      const actions = []
      callback(actions)
    }
  }
  signal actionSelected(string object_id, var value)
  
  QtObject {
    id: internal
    property var obj: null
    property var displayInformation: null
    property var actions: null
    property bool loading: obj == null || actions == null
  }

  function show( id ) {
    internal.obj = null
    objectProvider.lookupAsync(id, function (obj) {
      internal.obj = obj
      actionProvider.getActionsForObject(obj.class_id, function(result) { internal.actions = result })
      var displayInformation = objectDisplayInformationProvider.lookup(obj.class_id)
      displayInformation.icon.parent = iconRectangle
      displayInformation.icon.margins = 6
      internal.displayInformation = displayInformation
      iconRectangle.children.length = 0
      iconRectangle.children.push(displayInformation.icon)
    })
    open()
  }

  width: Units.pt(128)
  padding: Units.pt(4)
  background: Rectangle {
    id: backgroundItem
    anchors.fill: parent
    color: Style.background.content
    border { color: root.style.primary.color; width: Style.popup.borderWidth }
  }


  ColumnLayout {
    id: rootLayout
    anchors.fill: parent
    RowLayout {
      Layout.fillWidth: true
      SkeletonLoader {
        loading: internal.loading
        control: Rectangle {
          id: iconRectangle
          width: Units.pt(24)
          height: Units.pt(24)
        }
      }


      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 0
        SkeletonText {
          id: objectTypeText
          width: Units.pt(50)
          font.pointSize: 10
          font.weight: Font.Bold
          color: root.style.primary.color
          text: !internal.displayInformation ? "" : internal.displayInformation.name
        }
        SkeletonText {
          id: objectNameText
          width: Units.pt(80)
          font.pointSize: 12
          text: !internal.obj ? "" : internal.obj.name
        }
      }
    }

    ListView {
      Layout.fillWidth: true
      visible: internal.actions == null || internal.actions.length > 0
      implicitHeight: childrenRect.height
      width: parent.width
      spacing: Units.pt(2)
      interactive: height != childrenRect.height
      model: internal.actions || [{}, {}, {}]
      delegate: SkeletonLoader {
        width: parent.width
        loading: internal.loading
        StyledButton {
          style: root.style
          text: modelData.name || ""
          onClicked: root.actionSelected(internal.obj.object_id, modelData.value)
        }
      }
    }

    Text {
      Layout.alignment: Qt.AlignHCenter
      Layout.margins: Units.pt(8)
      visible: internal.actions != null && internal.actions.length == 0
      text: "No actions available."
    }
    
  }
}

import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Hector.Controls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0

Item {
  id: control
  property var task
  property var style
  property bool current: false

  function getTitleForTask(task) {
    if (task.name == "Take Measurement of Poi" || task.name == "Take Photo of Object")
    {
      for (var i in task.params) {
        if (task.params[i].key != "object_id") continue
        return objectProvider.lookup(task.params[i].value).name
      }
      Ros.error("Did not find object_id param for task: " + task.name)
      return "Error"
    }
    return task.name
  }

  function getSubtitleForTask(task) {
    if (task.name == "Take Measurement of Poi" || task.name == "Take Photo of Object")
      return task.name
    return ""
  }

  function getIconForTask(task) {
    if (task.name == "Take Measurement of Poi") return Style.icons.measurement
    if (task.name == "Take Photo of Object") return Style.icons.photo
    if (task.name == "Start of Mission") return Style.icons.missionStart
    return Style.icons.unknown
  }

  RowLayout {
    anchors.fill: parent
    Icon {
      Layout.fillHeight: true
      Layout.alignment: Qt.AlignVCenter
      Layout.margins: Units.pt(4)
      Layout.preferredWidth: height
      padding: Units.pt(2)
      backgroundColor: control.current ? Style.getTextColor(control.style.primary.color) : control.style.primary.color
      color: control.current ? control.style.primary.color : Style.getTextColor(control.style.primary.color)
      font.family: Style.iconFontFamily
      text: getIconForTask(control.task)
    }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 0
      Text {
        Layout.fillWidth: true
        text: getTitleForTask(control.task)
        font: Style.listElement.titleFont
        color: Style.getTextColor(control.current ? control.style.primary.color : Style.background.content)
      }
      Text {
        Layout.fillWidth: true
        visible: text && text != ""
        text: getSubtitleForTask(control.task)
        font: Style.listElement.subtitleFont
        color: Style.getTextColor(control.current ? control.style.primary.color : Style.background.content)
        opacity: 0.8
      }
    }
  }
}
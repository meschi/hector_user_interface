import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import Ros 1.0
import Hector.Utils 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0

Rectangle {
  id: control
  property var style

  Subscriber {
    id: missionSub
    topic: "/mission_execution_manager/current_mission"
    onNewMessage: function(msg) {
      Ros.info("Received new mission: " + msg.name + " with " + msg.tasks.length + " tasks.")
      mission = msg
    } 
  }

  Subscriber {
    id: missionStatusSub
    topic: "/mission_execution_manager/mission_status"
    onNewMessage: function(msg) {
      Ros.info("New Mission status: {index: " + msg.index + ", is_mission_running: "+ msg.is_mission_running + ", status_text: "+ msg.status_text +"}")
      missionStatus = msg
    } 
  }

  property var mission: ({
    id: "test_mission1",
    name: "Milestone Mission",
    tasks: [
      {
        id: "task1",
        name: "Task look at poi",
        params: [{key:"object_id", value:"85726678-7bbb-442c-928f-e28e7f2697fb"}],
      },
      {
        id: "task2",
        name: "Task look at poi",
        params: [{key:"object_id", value:"da9e73a9-1b36-4302-8e8a-a256899ea24c"}],
      },
      {
        id: "task3",
        name: "Task look at poi",
        params: [{key:"object_id", value:"85726678-7bbb-442c-928f-e28e7f2697fb"}],
      },
      {
        id: "task4",
        name: "Task look at poi",
        params: [{key:"object_id", value:"da9e73a9-1b36-4302-8e8a-a256899ea24c"}],
      },
      {
        id: "task4",
        name: "Task look at poi",
        params: [{key:"object_id", value:"da9e73a9-1b36-4302-8e8a-a256899ea24c"}],
      },
    ],
  })

  property var missionStatus : ({ 
    index: 0,
    is_mission_running: false,
    status_text: "",
  })

  Component.onCompleted: function() {
    var result = Service.call("mission_execution_manager/load_mission", "mission_msgs/LoadMission", {mission: control.mission})
    if(result) {
      Ros.info("Successfull set the current mission: " + control.mission.name)
    } else {
      Ros.warn("Loading mission : " + control.mission.name + " failed!")
    }
  }
  

  ColumnLayout {
    anchors.fill: parent
    spacing: 0
    
    MissionListView {
      id: missionListView
      Layout.fillHeight: true
      Layout.fillWidth: true
      Layout.preferredHeight: 1
      clip: true
      style: control.style
      disableMouseSelection: true
      currentIndex: control.missionStatus.index
      header: Text {
        Layout.fillWidth: true
        text: control.mission.name
        font: Style.fonts.header
        color: Style.getTextColor(Style.background.content)
      }
      model: control.mission.tasks
    }

    MissionControl {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredHeight: implicitHeight
      enabled: control.mission && control.missionStatus
      mission: control.mission
      missionStatus: control.missionStatus
    }
  }
}

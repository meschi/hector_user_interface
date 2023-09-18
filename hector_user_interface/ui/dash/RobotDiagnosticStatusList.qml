import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Ros 1.0
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0

Dialog {
  id: root

  property var nodes_lm: ListModel {id: nodesListModel}
  property var topics_lm: ListModel {id: topicsListModel}
  property var tf_tree_lm: ListModel {id: tfTreeListModel}
  property var computer_monitor_lm: ListModel {id: computerMonitorListModel}
  property var others_lm: ListModel {id: othersListModel}

  // Function to get status index by its name
  function find(model, criteria) {
    for(var i = 0; i < model.count; ++i) if (criteria(model.get(i))) return i
    return null
  }

  function getTopLevel(model) {
    let res = 0
    for (let i = 0; i < model.count; i++) {
      res = Math.max(res, model.get(i).level)
    }
    return res
  }

  Subscriber {
      id: diagnosticAggSubscriber
      topic: "/diagnostics_agg"
      onNewMessage: {
        let computer_monitor_tmp = []
        let nodes_tmp = []
        let topics_tmp = []
        let tf_tree_tmp = []
        let others_tmp = []

        // Store items in temporary arrays
        for (var i = 0; i < diagnosticAggSubscriber.message.status.length; i++) {
          let status = diagnosticAggSubscriber.message.status.at(i)
          if (status.name.startsWith("/Software Monitor/Active Nodes")) {
            if (status.name !== "/Software Monitor/Active Nodes")  // Skip header message
                nodes_tmp.push(status)
          }
          else if (status.name.startsWith("/Software Monitor/Topic Frequency")) {
            if (status.name !== "/Software Monitor/Topic Frequency")
              topics_tmp.push(status)
          }
          else if (status.name.startsWith("/Software Monitor/TF")) {
            if (status.name !== "/Software Monitor/TF")
              tf_tree_tmp.push(status)
          }
          else if (status.name.startsWith("/Computer Monitor")) {
            if (status.name !== "/Computer Monitor")
              computer_monitor_tmp.push(status)
          }
          else
          {
            if (status.name === "/Software Monitor" || status.name === "/Other")
              continue;
            others_tmp.push(status)}
          }

        // Sort arrays
        computer_monitor_tmp.sort()
        nodes_tmp.sort()
        topics_tmp.sort()
        tf_tree_tmp.sort()
        others_tmp.sort()

        // Update ListModels
        for (var j = 0; j < nodes_tmp.length; j++) {

          // Copy keyvalue array to javascript object
          let values = {}
          for (var l = 0; l < nodes_tmp[j].values.length; l++)
            values[nodes_tmp[j].values.toArray()[l].key] = nodes_tmp[j].values.toArray()[l].value

          let status_tmp = {"name": nodes_tmp[j].name, "message": nodes_tmp[j].message, "level": nodes_tmp[j].level, "values": values}
          let idx = find(nodes_lm, function(item){return item.name === nodes_tmp[j].name})

          // Insert new ListElement if not found
          if (idx === null)
            nodes_lm.append(status_tmp)
          // Update otherwise
          else
            nodes_lm.set(idx, status_tmp)
        }

        for (var j = 0; j < topics_tmp.length; j++) {
          let values = {}
          for (var l = 0; l < topics_tmp[j].values.length; l++)
            values[topics_tmp[j].values.toArray()[l].key] = topics_tmp[j].values.toArray()[l].value
          let status_tmp = {"name": topics_tmp[j].name, "message": topics_tmp[j].message, "level": topics_tmp[j].level, "values": values}
          let idx = find(topics_lm, function(item){return item.name === topics_tmp[j].name})
          if (idx === null)
            topics_lm.append(status_tmp)
          else
            topics_lm.set(idx, status_tmp)
        }

        for (var j = 0; j < tf_tree_tmp.length; j++) {
          let values = {}
          for (var l = 0; l < tf_tree_tmp[j].values.length; l++)
            values[tf_tree_tmp[j].values.toArray()[l].key] = tf_tree_tmp[j].values.toArray()[l].value
          let status_tmp = {"name": tf_tree_tmp[j].name, "message": tf_tree_tmp[j].message, "level": tf_tree_tmp[j].level, "values": values}
          let idx = find(tf_tree_lm, function(item){return item.name === tf_tree_tmp[j].name})
          if (idx === null)
            tf_tree_lm.append(status_tmp)
          else
            tf_tree_lm.set(idx, status_tmp)
        }

        for (var j = 0; j < computer_monitor_tmp.length; j++) {
          // Clip namespace
          computer_monitor_tmp[j].name = computer_monitor_tmp[j].name.replace("/Computer Monitor/", "")
          let values = {}
          for (var l = 0; l < computer_monitor_tmp[j].values.length; l++)
            values[computer_monitor_tmp[j].values.toArray()[l].key] = computer_monitor_tmp[j].values.toArray()[l].value
          let status_tmp = {"name": computer_monitor_tmp[j].name, "message": computer_monitor_tmp[j].message, "level": computer_monitor_tmp[j].level, "values": values}
          let idx = find(computer_monitor_lm, function(item){return item.name === computer_monitor_tmp[j].name})
          if (idx === null)
            computer_monitor_lm.append(status_tmp)
          else
            computer_monitor_lm.set(idx, status_tmp)
        }

        for (var j = 0; j < others_tmp.length; j++) {
          let values = {}
          for (var l = 0; l < others_tmp[j].values.length; l++)
            values[others_tmp[j].values.toArray()[l].key] = others_tmp[j].values.toArray()[l].value
          let status_tmp = {"name": others_tmp[j].name, "message": others_tmp[j].message, "level": others_tmp[j].level, "values": values}
          let idx = find(others_lm, function(item){return item.name === others_tmp[j].name})
          if (idx === null)
            others_lm.append(status_tmp)
          else
            others_lm.set(idx, status_tmp)
        }
      }
  }

  GridLayout {
    id: grid
    anchors.fill: parent

    DiagnosticStatus {
      Layout.row: 0
      Layout.column: 0
      Layout.fillWidth: true
      name: "Nodes"
      header: true
      level: getTopLevel(nodesListModel)
    }

    ListView {
      id: nodesList
      Layout.row: 1
      Layout.column: 0
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(5)
      model: nodesListModel
      delegate: DiagnosticStatus {
        property variant myData: model
        name: model.values["node"]
        level: model.level
        width: nodesList.width
      }
    }

    DiagnosticStatus {
      Layout.row: 0
      Layout.column: 1
      Layout.fillWidth: true
      name: "Topics"
      header: true
      level: getTopLevel(topicsListModel)
    }

    ListView {
      id: topicsList
      Layout.row: 1
      Layout.column: 1
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(5)
      model: topicsListModel
      delegate: DiagnosticStatus {
        property variant myData: model
        name: model.values["topic"]
        message: model.level ? model.message : ""
        level: model.level
        width: topicsList.width
      }
    }

    DiagnosticStatus {
      Layout.row: 0
      Layout.column: 2
      Layout.fillWidth: true
      name: "TF Tree"
      header: true
      level: getTopLevel(tfTreeListModel)
    }

    ListView {
      id: tftreeList
      Layout.row: 1
      Layout.column: 2
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(5)
      model: tfTreeListModel

      delegate: DiagnosticStatus {
        property variant myData: model
        name: model.values["source frame"] + " -> " + model.values["target frame"]
        level: model.level
        width: tftreeList.width
      }
    }

    DiagnosticStatus {
      Layout.row: 0
      Layout.column: 3
      Layout.fillWidth: true
      name: "Computer Monitor"
      header: true
      level: getTopLevel(computerMonitorListModel)
    }

    ListView {
      id: computerMonitorList
      Layout.row: 1
      Layout.column: 3
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(5)
      model: computerMonitorListModel

      delegate: DiagnosticStatus {
        property variant myData: model
        name: model.name
        message: model.level ? model.message : ""
        level: model.level
        width: computerMonitorList.width
      }
    }

    DiagnosticStatus {
      Layout.row: 0
      Layout.column: 4
      Layout.fillWidth: true
      name: "Others"
      header: true
      level: getTopLevel(othersListModel)
    }

    ListView {
      id: othersList
      Layout.row: 1
      Layout.column: 4
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: Units.pt(5)
      model: othersListModel

      delegate: DiagnosticStatus {
        property variant myData: model
        name: model.name.replace("/Other", "")
        message: model.level ? model.message : ""
        level: model.level
        width: othersList.width
      }
    }
  }
}

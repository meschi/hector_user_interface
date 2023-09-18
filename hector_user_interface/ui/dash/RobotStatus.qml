import QtQuick 2.3
import QtQuick.Controls 2.1
import QtQuick.Layouts 1.1
import Ros 1.0
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Style 1.0
import Hector.Utils 1.0


Item {
  id: root
  implicitHeight: content.implicitHeight
  implicitWidth: content.implicitWidth
  property alias batteryTopic: batterySubscriber.topic

  Subscriber {
    id: batterySubscriber
  }
  
  // Content
  ColumnLayout {
    id: content
    anchors.fill: parent
    spacing: Units.pt(2)

    Rectangle {
      Layout.fillWidth: true
      color: Style.activeStyle.primary.color
      height: Units.pt(16)
      
      AutoSizeText {
        id: autonomyStateText
        margins: Units.pt(2)
        color: Style.getTextColor(Style.activeStyle.primary.color)
        text: {
          if (OperationModeManager.activeMode == OperationModeManager.Safe) return "Safe"
          if (OperationModeManager.activeMode == OperationModeManager.Teleoperation) return "Teleoperation"
          if (OperationModeManager.activeMode == OperationModeManager.Manipulation) return "Manipulation"
          if (OperationModeManager.activeMode == OperationModeManager.Autonomous) return "Autonomous"
          return "Unknown"
        }
      }
    }

    RobotDiagnosticsStatus {
      Layout.fillWidth: true
      Layout.preferredHeight: Units.pt(16)
    }

    ProgressWithText {
      Layout.fillWidth: true
      height: Units.pt(16)
      value: {
        if (!batterySubscriber.message || !batterySubscriber.message.percentage) return 0
        return batterySubscriber.message.percentage.toFixed(2)
      }
      backgroundColor: Style.battery.background
      foregroundColor: Style.battery.foregroundColor
    }

    Subscriber {
        id: conSubscriber
        property var topicProperty: rviz && rviz.registerRosTopicProperty("Network Topic", "/processed_connectivity", "connectivity_monitor/NetworkInfo")
        topic: topicProperty.value
    }
      
    //Latency
    ProgressWithText {
      Layout.fillWidth: true
      height: Units.pt(16)
      property var maxLatencyProperty: rviz && rviz.registerFloatProperty("Maximum Latency", 150)
      to: maxLatencyProperty.value || 150
      value: {
        if (!conSubscriber.message || !conSubscriber.message.latency) return 0
        return conSubscriber.message.latency
      }
      backgroundColor: Style.battery.background
      foregroundColor: Style.battery.foregroundColor
      text: "Latency: " + value +" ms"
    }

    //Packet Loss
    ProgressWithText {
      Layout.fillWidth: true
      height: Units.pt(16)
      to: 100
      value: {
        if (!conSubscriber.message || !conSubscriber.message.packet_loss) return 0
        return conSubscriber.message.packet_loss
      }
      backgroundColor: Style.battery.background
      foregroundColor: Style.battery.foregroundColor
      text: "Packet Loss: " + value +" %"
    }

    Subscriber {
        id: connlossSubscriber
        property var topicProperty: rviz && rviz.registerRosTopicProperty("Connectivity Loss Navigation Topic", "/connectivity_loss_return_navigation_node/state", "connectivity_loss_return_navigation/ConnectivityLossReturnNavigationState")
        topic: topicProperty.value
    }

    ProgressWithText {
        Layout.fillWidth: true
        height: Units.pt(16)
        to: 100
        value: {
            if (!connlossSubscriber.message || !connlossSubscriber.message.timer_percentage) return 0
            return (connlossSubscriber.message.timer_percentage * 100).toFixed(2)
        }
        backgroundColor: {
            if (!connlossSubscriber.message||connlossSubscriber.message.state > 3) return Style.colors.status.unknown
            return Style.battery.background
        }
        foregroundColor: Style.battery.foregroundColor
        text: {
            if (!connlossSubscriber.message) return "Unknown"
            else if (connlossSubscriber.message.state > 3) return "Disabled"
            else if (connlossSubscriber.message.state === 1) return "Good Connection"
            else if (connlossSubscriber.message.state === 2) return "Timer: " + value +" %"
            else if (connlossSubscriber.message.state === 3) return "Returning!"
            else if (connlossSubscriber.message.state === 0) return "No Msg received!"
            return "Unknown"
        }
    }


  }
}
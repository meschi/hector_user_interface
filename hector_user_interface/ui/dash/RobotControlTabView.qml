
import QtQuick 2.3
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.1
import Hector.InternalControls 1.0

Item {
  id: root
  property var style
  property var configuration
  signal configurationUpdated

  ColumnLayout {
    anchors.fill: parent
    spacing: 0
    
    TabBar {
      id: bar
      Layout.fillWidth: true
      spacing: 0
      z: 1
      currentIndex: 1
      
      StyledTabButton {
        style: root.style
        text: "Mission"
      }
      StyledTabButton {
        style: root.style
        text: "Behaviors"
      }
      StyledTabButton {
        style: root.style
        text: "Settings"
      }
    }

    StackLayout {
      Layout.fillHeight: true
      Layout.fillWidth: true
      currentIndex: bar.currentIndex
      
      MissionTab { Layout.fillWidth: true; Layout.fillHeight: true; style: root.style }
      
      RobotActionTab {
        Layout.fillWidth: true
        Layout.fillHeight: true
        style: root.style
        actions: root.configuration && root.configuration.actions || []
        actionStructure: root.configuration && root.configuration.actionStructure || []
        onActionsUpdated: {
          if (!root.configuration) root.configuration = {}
          root.configuration.actions = actions
          root.configurationUpdated()
        }
        onActionStructureUpdated: {
          if (!root.configuration) root.configuration = {}
          root.configuration.actionStructure = actionStructure
          root.configurationUpdated()
        }
      }

      SettingsTab {
        Layout.fillHeight: true
        Layout.fillWidth: true
        style: root.style
        parameters: root.configuration && root.configuration.params || []
        onParametersUpdated: {
          root.configuration.params = parameters
          root.configurationUpdated()
        }
      }
    }
  }
}

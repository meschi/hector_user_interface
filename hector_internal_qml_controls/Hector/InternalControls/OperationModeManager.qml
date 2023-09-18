pragma Singleton
import QtQuick 2.0
import Hector.Utils 1.0
import Ros 1.0

Object {
  enum OperationMode {
    Unknown,
    Safe,
    Teleoperation,
    Manipulation,
    Autonomous
  }
  readonly property int activeMode: {
    if (estopSubscriber.anyEStopActive) return OperationModeManager.OperationMode.Safe
    if (joySubscriber.joyProfile == "drive") return OperationModeManager.Teleoperation
    if (joySubscriber.joyProfile == "manipulation") return OperationModeManager.Manipulation
    return OperationModeManager.Unknown
  }

  Subscriber {
    id: joySubscriber
    topic: "/joy_teleop_profile"
    property string joyProfile: message && message.data || "drive"
  }

  Subscriber {
    id: estopSubscriber
    topic: "/e_stop_manager/e_stop_list"
    property bool anyEStopActive: {
      if (!message) return false
      for (let i = 0; i < message.values.length; ++i) {
        if (message.values.at(i)) return true
      }
      return false
    }
  }
}

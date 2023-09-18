import QtQuick 2.3
import QtQuick.Controls 2.1
import Ros 1.0
import Hector.Controls 1.0
import Hector.InternalControls 1.0
import Hector.Utils 1.0
import Hector.Style 1.0

Button {
  Subscriber {
    id: diagnosticTopLevelSubscriber
    topic: "/diagnostics_toplevel_state"
  }

  id: robotDiagnosticsStatus
  checkable: false
  enabled: !!diagnosticTopLevelSubscriber.message && !diagnosticPopup.opened
  font.pointSize: 14
  text: !diagnosticTopLevelSubscriber.message ? "Unknown" :
        diagnosticTopLevelSubscriber.message.level === 0 ? "OK" :
        diagnosticTopLevelSubscriber.message.level === 1 ? "Warning" :
                                                           "Error"

  onClicked: {
    if (diagnosticPopup.opened)
      diagnosticPopup.close()
    else
      diagnosticPopup.open()
  }

  background: Rectangle {
    color: {
      if (!diagnosticTopLevelSubscriber.message)
        return Style.colors.status.unknown
      if (diagnosticTopLevelSubscriber.message.level === 0)
        return Style.handleMouseStates(robotDiagnosticsStatus, Style.colors.status.ok)
      if (diagnosticTopLevelSubscriber.message.level === 1)
        return Style.handleMouseStates(robotDiagnosticsStatus, Style.colors.status.warn)
      return Style.handleMouseStates(robotDiagnosticsStatus, Style.colors.status.error)
    }
  }

  RobotDiagnosticStatusList {
      id: diagnosticPopup
      parent: ApplicationWindow.overlay
      x: (parent.width - width) / 2
      y: 5
      title: "Diagnostic messages"
      focus: true
      width: parent.width * 0.9
      height: parent.height * 0.4
  }
}



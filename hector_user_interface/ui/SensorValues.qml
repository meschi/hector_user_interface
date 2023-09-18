import QtQuick 2.3
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.1
import Hector.Style 1.0
import Ros 1.0
import "sensors"

RowLayout {
  id: control
  property int timeout: 5000
  function displaySensorValue(value, decimals) {
    if (value === undefined || value === null) return '?'
    return value.toFixed(decimals)
  }

  function displayAnymalMode(value) {
    switch(value) {
      case 1:
        return 'Autonomous'
      case 2:
        return 'Teleop'
      case 3:
        return 'Controller'
      case 4:
        return 'Emergency'
      default:
        return '?'
    }
  }

  // CO2
  SensorValue {
    id: co2SensorValue

  Timer {
    interval: 250; repeat: true; running: true
    onTriggered: {
      var now = new Date()
      if (now - co2SensorValue.lastUpdate > control.timeout) {
        co2SensorValue.value = "?"
      }
      if (now - radionukularSensorValue.lastUpdate > control.timeout) {
        radionukularSensorValue.value = "?"
      }
    }
  }
    Subscriber {
      id: co2Subscriber
      topic: "/co2"
      onNewMessage: {
        co2SensorValue.visible = true
        co2SensorValue.value = displaySensorValue(co2Subscriber.message && co2Subscriber.message.data, 0)
        co2SensorValue.lastUpdate = new Date()
      }
    }
    Subscriber {
      id: co2WarnSubscriber
      topic: "/co2detected"
    }
    property var lastUpdate: new Date()
    visible: false
    warn: co2WarnSubscriber.message && co2WarnSubscriber.message.data || false
    value: "?"
    unit: "ppm"
    icon: Style.icons.co2
  }

  // Radioactivity
  SensorValue {
    id: radionukularSensorValue
    Subscriber {
      id: radionukularSubscriber
      topic: "/dose_rate"
      onNewMessage: {
        radionukularSensorValue.visible = true
        radionukularSensorValue.value = displaySensorValue(radionukularSubscriber.message && radionukularSubscriber.message.rate, 1)
        radionukularSensorValue.lastUpdate = new Date()
      }
    }
    property var lastUpdate: new Date()
    visible: false
    dangerous: radionukularSubscriber.message && radionukularSubscriber.message.rate > 100 || false
    warn: radionukularSubscriber.message && radionukularSubscriber.message.rate > 10 || false
    value: "?"
    unit: "μSv/h"
    icon: Style.icons.radioactive
  }

  // Force-angle stability margin
  SensorValue {
    id: stabilityMarginValue
    Subscriber {
      id: stabilityMarginSubscriber
      topic: "/stability_visualization/stability_margin"
      onNewMessage: {
        stabilityMarginValue.visible = true
        stabilityMarginValue.value = displaySensorValue(stabilityMarginSubscriber.message && stabilityMarginSubscriber.message.data, 1)
        stabilityMarginValue.lastUpdate = new Date()
      }
    }
    property var lastUpdate: new Date()
    visible: false
    dangerous: stabilityMarginSubscriber.message && stabilityMarginSubscriber.message.data < 0.5 || false
    warn: stabilityMarginSubscriber.message && stabilityMarginSubscriber.message.data < 1.0 || false
    value: "?"
    unit: "FASM"
    icon: Style.icons.stability
  }

  // Polarity
  SensorValue {
    id: polaritySensorValue
    Subscriber {
      id: polaritySubscriber1
      topic: "/hall_sensor_1"
      onNewMessage: {
        polaritySensorValue.visible = true
        polaritySensorValue.lastUpdate = new Date()
      }
    }
    Subscriber {
      id: polaritySubscriber2
      topic: "/hall_sensor_2"
      onNewMessage: {
        polaritySensorValue.visible = true
        polaritySensorValue.lastUpdate = new Date()
      }
    }
    
    property var lastUpdate: new Date()
    property var polarity1: polaritySubscriber1.message && (polaritySubscriber1.message.data - 1)
    property var polarity2: polaritySubscriber2.message && (polaritySubscriber2.message.data - 1)
    visible: false
    value: {  
      if (polarity1 == null && polarity2 == null) {
        return '?'
      } else if (polarity1 == null) {
        return ((polarity2 * 1000) / 90).toFixed(1)
      } else if (polarity2 == null || Math.abs(polarity1) > Math.abs(polarity2)) {
        return (-(polarity1 * 1000) / 90).toFixed(1)
      } else {
        return ((polarity2 * 1000) / 90).toFixed(1)
      }
    }
    unit: "mT"
    icon: Style.icons.magnet
  }

  //ChemproX
  SensorValue {
    id: chemproxMeasurement
    Subscriber {
      id: chemproxMeasurementSubscriber
      topic: "/chemprox/measurement"
      onNewMessage: {
        chemproxMeasurement.visible = true
        chemproxMeasurement.value = message.compound_name
        chemproxMeasurement.lastUpdate = new Date()
      }
    }
    property var lastUpdate: new Date()
    visible: false
    dangerous: !(chemproxMeasurementSubscriber.message && (chemproxMeasurementSubscriber.message.compound_name == 'AIR'))
    value: "?"
  }

  // Anymal Control
  SensorValue {
    id: anymalOperationMode
    Subscriber {
      id: anymalOperationModeSubscriber
      topic: "/user_interaction_mode_manager/current_mode"
      onNewMessage: {
        anymalOperationMode.visible = true
        anymalOperationMode.value = displayAnymalMode(anymalOperationModeSubscriber.message.data)
        anymalOperationMode.lastUpdate = new Date()
      }
    }
    property var lastUpdate: new Date()
    property int mode: anymalOperationModeSubscriber.message && anymalOperationMode.message.data || -1
    visible: false
    dangerous: mode == 4
    warn: mode == 2 || mode == 3
    value: "?"
  }

  // Anymal State
  SensorValue {
    id: anymalState
    Subscriber {
      id: anymalStateSubscriber
      topic: "/operational_mode_manager/state_notification"
      onNewMessage: {
        anymalState.visible = true
        anymalState.value = anymalStateSubscriber.message.deduction_status.mode.name
        anymalState.lastUpdate = new Date()
      }
    }
    property var lastUpdate: new Date()
    property var status: anymalStateSubscriber.message && anymalStateSubscriber.message.deduction_status.mode.name || 'None'
    visible: false
    dangerous: status === 'Sleep'
    warn: status === 'Rest' || status === 'Stand'
    value: "?"
  }
}

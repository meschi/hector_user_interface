# Hector User Interface

**Maintainer:** Stefan Fabian

This is the hector user interface.  
The third generation of the Team Hector rviz-based user interface.

## Style

The resources and styles / colors used are defined in hector_user_interface_resources for consistent styling.
You can import the Style singleton using

```qml
import Hector.Style 1.0
```

## Internal controls

The hector_internal_qml_controls package contains QML components used only internally by Team Hector because they depend on our styling or are strongly dependant on our software architecture.
They can be imported using

```qml
import Hector.InternalControls 1.0
```

For controls, that can be used with little to no adaptation necessary have a look at the [`hector_qml_controls` repo](https://github.com/tu-darmstadt-ros-pkg/hector_qml_controls).

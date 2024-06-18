//
// Created by Jonas Suess on 19.04.2023
//

#ifndef HECTOR_USER_INTERFACE_STOP_SWIPE_TOOL_H
#define HECTOR_USER_INTERFACE_STOP_SWIPE_TOOL_H

#include <rviz/default_plugin/tools/interaction_tool.h>
#include <rviz/ogre_helpers/arrow.h>

#include <OgreSharedPtr.h>
#include <QQuaternion>
#include <QVariantMap>
#include <QVector3D>
#include <QKeyEvent>

#include <OgreEntity.h>
#include <OgreSubMesh.h>
#include <OgreSceneManager.h>

#include <ros/ros.h>

namespace hector_user_interface {

class StopSwipeTool : public rviz::InteractionTool {
Q_OBJECT

public:
  StopSwipeTool();

  ~StopSwipeTool();

  void activate() override;

  void deactivate() override;

signals:

  void lookAtChanged();

protected:

  void onInitialize() override;

  ros::NodeHandle nh_;

};
}  // namespace hector_user_interface

#endif  // HECTOR_USER_INTERFACE_STOP_SWIPE_TOOL_H

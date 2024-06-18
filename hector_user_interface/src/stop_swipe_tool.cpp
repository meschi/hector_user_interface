//
// Created by Jonas Suess on 19.04.2023
//

#include "hector_user_interface/stop_swipe_tool.h"

#include <rviz/properties/bool_property.h>
#include <rviz/selection/selection_manager.h>
#include <rviz/display_context.h>
#include <rviz/geometry.h>
#include <rviz/mesh_loader.h>
#include <rviz/viewport_mouse_event.h>
#include <rviz/view_manager.h>
#include <rviz/tool_manager.h>
#include <rviz/tool.h>
#include <rviz/render_panel.h>

#include <ros/package.h>

#include <ros/ros.h>
#include <tf2_ros/static_transform_broadcaster.h>
#include <tf2_ros/transform_listener.h>
#include <tf2/LinearMath/Quaternion.h> // TODO: needed?
#include <geometry_msgs/TransformStamped.h>
#include <std_srvs/Trigger.h>

#include <stdio.h>



namespace hector_user_interface {

StopSwipeTool::StopSwipeTool() {
  shortcut_key_ = 'l';
}

StopSwipeTool::~StopSwipeTool() {
}

void StopSwipeTool::activate() {
  // trigger service
  ros::service::waitForService("/stop_swipe_skill");  //this is optional

  ros::ServiceClient swipeClient
    = nh_.serviceClient<std_srvs::Trigger>("/stop_swipe_skill");
  std_srvs::Trigger srv;
  swipeClient.call(srv);
  // srv.success, srv.message are the return values
  context_->getToolManager()->setCurrentTool(context_->getToolManager()->getDefaultTool());
}

void StopSwipeTool::deactivate() {
}

void StopSwipeTool::onInitialize() {
  rviz::InteractionTool::onInitialize();
}

}  // namespace hector_user_interface

#include <pluginlib/class_list_macros.h>

PLUGINLIB_EXPORT_CLASS(hector_user_interface::StopSwipeTool, rviz::Tool)

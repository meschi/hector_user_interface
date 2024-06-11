//
// Created by Jonas Suess on 19.04.2023
//

#include "hector_user_interface/swipe_skill_tool.h"

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

const char *SWIPE_DIRECTION_ARROW_RESOURCE = "package://hector_user_interface/media/arrow.dae";

SwipeSkillTool::SwipeSkillTool() {
  shortcut_key_ = 'l';
  placed = false;
}

SwipeSkillTool::~SwipeSkillTool() {
  delete preview_arrow_;
  delete arrow_;
}

void SwipeSkillTool::activate() {
  context_->getViewManager()->getRenderPanel()->installEventFilter(this);
}

void SwipeSkillTool::deactivate() {
  context_->getViewManager()->getRenderPanel()->removeEventFilter(this);
  if (preview_arrow_ != nullptr)
    preview_arrow_->getSceneNode()->setVisible(false);
}

void SwipeSkillTool::onInitialize() {
  rviz::InteractionTool::onInitialize();
  createPreviewArrow(preview_arrow_, Ogre::Vector3::ZERO, Ogre::Vector3::UNIT_X, arrow_length_, 1.2);
  createArrow(arrow_, Ogre::Vector3::ZERO, Ogre::Vector3::UNIT_X, arrow_length_);
  preview_arrow_position_ = Ogre::Vector3::ZERO;
  arrow_position_ = Ogre::Vector3::ZERO;
  arrow_tip_ = Ogre::Vector3::ZERO;
  arrow_direction_ = Ogre::Vector3::UNIT_X;
  mode_ = MODE_PREVIEW;

  arrow_mesh_ = rviz::loadMeshFromResource(SWIPE_DIRECTION_ARROW_RESOURCE);
  if ( arrow_mesh_.isNull() ) {
    ROS_ERROR_NAMED( "hector_user_interface",
                     "Failed to load waypoint tool orientation preview mesh." );
    return;
  }
}

void setSkillOrientation( Ogre::SceneNode *node, const Ogre::Quaternion &orientation )
{
  auto *arrow_node = dynamic_cast<Ogre::SceneNode *>( node->getChild( 0 ) );
  if ( orientation.Norm() > 0 ) {
    arrow_node->setPosition( orientation * Ogre::Vector3{ 1, 0, 2 } );
    arrow_node->setOrientation( orientation );
    arrow_node->setVisible( true );
  } else {
    arrow_node->setVisible( false );
  }
}

bool SwipeSkillTool::getNormalAtPoint(rviz::ViewportMouseEvent &event, Ogre::Vector3 &normal) {
  // first implementation using just three points
  int offset_pixel = 3;
  std::vector<std::pair<int, int>> offsets = {{1,   1},
                                              {-1,  1},
                                              {-1,  -1},
                                              {1,   -1},
                                              {0.5, 0}};
  std::vector<Ogre::Vector3> intersections;
  for (const auto &offset: offsets) {
    Ogre::Vector3 intersection;
    if (context_->getSelectionManager()->get3DPoint(event.viewport, event.x + offset.first * offset_pixel,
                                                    event.y + offset.second * offset_pixel, intersection)) {
      intersections.push_back(intersection);
    }
    if (intersections.size() == 3)break;
  }
  if (intersections.size() < 3) return false;
  normal = (intersections[0] - intersections[1]).crossProduct((intersections[0] - intersections[2]));
  normal.normalise();
  return true;
}


int SwipeSkillTool::processMouseEvent(rviz::ViewportMouseEvent &event) {
  if (preview_arrow_ == nullptr)
    return rviz::InteractionTool::processMouseEvent(event);
  if (arrow_ == nullptr)
    return rviz::InteractionTool::processMouseEvent(event);

  ROS_WARN("mouse  event %i",mode_);

  // Show preview arrow
  if (mode_ == MODE_PREVIEW) {
    ROS_WARN("mode_preview");
    // Compute raycast to get position of arrow
    preview_arrow_->getSceneNode()->setVisible(false);
    arrow_->getSceneNode()->setVisible(false);
    if (context_->getSelectionManager()->get3DPoint(event.viewport, event.x, event.y, intersection_)) {
      camera_intersection_offset_ = intersection_ - event.viewport->getCamera()->getPosition();
      Ogre::Real length = std::sqrt(camera_intersection_offset_.x * camera_intersection_offset_.x +
                                    camera_intersection_offset_.y * camera_intersection_offset_.y +
                                    camera_intersection_offset_.z * camera_intersection_offset_.z);
      if (length > 1E-6) {
        camera_intersection_offset_.x /= length;
        camera_intersection_offset_.y /= length;
        camera_intersection_offset_.z /= length;
      }
      preview_arrow_position_ =
        intersection_ - Ogre::Vector3(camera_intersection_offset_.x, camera_intersection_offset_.y,
                                      camera_intersection_offset_.z) * arrow_length_;
      // compute normal at preview arrow position -> this will be the initial direction
      if (getNormalAtPoint(event, normal_)) {
        if (normal_.dotProduct(camera_intersection_offset_) < 0)normal_ *= -1;
      } else {
        normal_ = camera_intersection_offset_;
      }
      preview_arrow_position_ = intersection_ - Ogre::Vector3(normal_.x, normal_.y, normal_.z) * arrow_length_;
    }

    preview_arrow_->setPosition(preview_arrow_position_);
    preview_arrow_->setDirection(
      Ogre::Vector3(normal_.x, normal_.y, normal_.z));
    preview_arrow_->getSceneNode()->setVisible(true);
    if (placed) {
        arrow_->getSceneNode()->setVisible(true);
    }

    // Place arrow
    if (event.leftDown() && ros::service::exists("/start_swipe_skill", true)) {
      ROS_WARN("Place Arrow");
      arrow_direction_ =
        Ogre::Vector3(normal_.x, normal_.y, normal_.z);
      arrow_position_ = preview_arrow_position_;
      arrow_tip_ = arrow_position_ + arrow_length_ * arrow_direction_;
      arrow_->setPosition(arrow_position_);
      arrow_->setDirection(arrow_direction_);
      arrow_->getSceneNode()->setVisible(true);
      preview_arrow_->getSceneNode()->setVisible(false);

      //mode_ = MODE_CHANGE_DIRECTION;
      mode_ = MODE_EXIT;
      mouse_position_ = {event.x, event.y};
      original_arrow_direction_ = arrow_direction_;

      placed = true;

      // send transform
      static tf2_ros::StaticTransformBroadcaster static_broadcaster;
      geometry_msgs::TransformStamped static_transformStamped;

      static_transformStamped.header.stamp = ros::Time::now();
      static_transformStamped.header.frame_id = "world";
      static_transformStamped.child_frame_id = "swipe_target";
      static_transformStamped.transform.translation.x = arrow_tip_[0];
      static_transformStamped.transform.translation.y = arrow_tip_[1];
      static_transformStamped.transform.translation.z = arrow_tip_[2];
      tf2::Quaternion quat;
      quat.setRPY(0.0, 0.0, 0.0);
      static_transformStamped.transform.rotation.x = quat.x();
      static_transformStamped.transform.rotation.y = quat.y();
      static_transformStamped.transform.rotation.z = quat.z();
      static_transformStamped.transform.rotation.w = quat.w();
      static_broadcaster.sendTransform(static_transformStamped);

      // calculate distance w.r.t. robot base
      tf2_ros::Buffer tfBuffer;
      tf2_ros::TransformListener tfListener(tfBuffer);

      geometry_msgs::TransformStamped tf_base_target;
      if (!tfBuffer.canTransform("base_link", "swipe_target", ros::Time(0), ros::Duration(3.0))) {
        ROS_WARN("transform not available (base_link, swipe_target)");
        mode_ = MODE_EXIT;
        return Render;
      }
      try {
        tf_base_target = tfBuffer.lookupTransform("base_link", "swipe_target",
                               ros::Time(0));
      } catch (tf2::TransformException &ex) {
        ROS_WARN("failed to get transform: %s", ex.what());
        mode_ = MODE_EXIT;
        return Render;
      }
      Ogre::Real offset_x = tf_base_target.transform.translation.x;
      Ogre::Real offset_y = tf_base_target.transform.translation.y;
      Ogre::Real angle = std::atan2(offset_y, offset_x);

      quat.setRPY(0.0, 0.0, angle);
      static_transformStamped.transform.rotation.x = quat.x();
      static_transformStamped.transform.rotation.y = quat.y();
      static_transformStamped.transform.rotation.z = quat.z();
      static_transformStamped.transform.rotation.w = quat.w();
      // re-publish rotation
      static_broadcaster.sendTransform(static_transformStamped);

      // trigger service
      ros::service::waitForService("/start_swipe_skill");  //this is optional

      ros::ServiceClient swipeClient
        = nh_.serviceClient<std_srvs::Trigger>("/start_swipe_skill");
      std_srvs::Trigger srv;
      swipeClient.call(srv);
      // srv.success, srv.message are the return values
      if (srv.response.success) {
        arrow_->setColor(0., 1.0, 0.6, 1.);
      } else {
        arrow_->setColor(0.6, 0.6, 0.6, 1.);
      }

      // set orientation of skill
      //ROS_WARN("going to set skill orientation");
      //setSkillOrientation(arrow_->getSceneNode(), orientation);
      ROS_WARN("set skill orientation");


      return Render;
    }
  } else if (mode_ == MODE_CHANGE_DIRECTION) {
    ROS_WARN("mode_change_direction");
    // TODO change direction if mouse is far enough away from placed arrow
    // setSkillRotation(w.r.t mouse selection)
    mode_ == MODE_EXIT;
  }

  return rviz::InteractionTool::processMouseEvent(event);
}

bool SwipeSkillTool::eventFilter(QObject *object, QEvent *event) {
  if (event->type() == QEvent::MouseButtonRelease) {
    auto *mouseEvent = dynamic_cast<QMouseEvent *>(event);
    //if (mouseEvent->button() == Qt::MouseButton::LeftButton && mode_ == MODE_EXIT)
    if (mode_ == MODE_EXIT)
        exitSwipeSkill();
  }
  return false;
}

void SwipeSkillTool::exitSwipeSkill() {
  mode_ = MODE_PREVIEW;
  context_->getToolManager()->setCurrentTool(context_->getToolManager()->getDefaultTool());
}

void SwipeSkillTool::createArrow(rviz::Arrow *&arrow, const Ogre::Vector3 &base, const Ogre::Vector3 &direction,
                             double length, double alpha) {
  arrow = new rviz::Arrow(context_->getSceneManager(), scene_manager_->getRootSceneNode());
  arrow->set(0.5f * length, 0.07, 0.5f * length, 0.2);
  arrow->setColor(0., 1.0, 0.6, alpha);
  arrow->setPosition(base);
  arrow->setDirection(direction);
  arrow->getSceneNode()->setVisible(false);
}

void SwipeSkillTool::createPreviewArrow(rviz::Arrow *&arrow, const Ogre::Vector3 &base, const Ogre::Vector3 &direction,
                             double length, double alpha) {
  arrow = new rviz::Arrow(context_->getSceneManager(), scene_manager_->getRootSceneNode());
  arrow->set(0.5f * length, 0.05, 0.5f * length, 0.15);
  arrow->setColor(1., 0.3, 0.0, alpha);
  arrow->setPosition(base);
  arrow->setDirection(direction);
  arrow->getSceneNode()->setVisible(false);
}

QVector3D SwipeSkillTool::lookAtPosition() const {
  return {arrow_tip_.x, arrow_tip_.y, arrow_tip_.z};
}

QVector3D SwipeSkillTool::lookAtDirection() const {
  return {arrow_direction_.x, arrow_direction_.y, arrow_direction_.z};
}

QQuaternion SwipeSkillTool::lookAtOrientation() const {
  Ogre::Quaternion orientation;

  Ogre::Vector3 xAxis = -arrow_direction_;
  xAxis.normalise();
  Ogre::Vector3 zAxis = xAxis.crossProduct(Ogre::Vector3::UNIT_Z);
  zAxis.normalise();
  Ogre::Vector3 yAxis = zAxis.crossProduct(xAxis);
  yAxis.normalise();
  orientation.FromAxes(xAxis, yAxis, zAxis);

  QQuaternion q(orientation.w, orientation.x, orientation.y, orientation.z);
  return q;
}

}  // namespace hector_user_interface

#include <pluginlib/class_list_macros.h>

PLUGINLIB_EXPORT_CLASS(hector_user_interface::SwipeSkillTool, rviz::Tool)

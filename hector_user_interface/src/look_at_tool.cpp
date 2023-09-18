//
// Created by Jonas Suess on 19.04.2023
//

#include "hector_user_interface/look_at_tool.h"

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

namespace hector_user_interface {

LookAtTool::LookAtTool() {
  shortcut_key_ = 'l';
}

LookAtTool::~LookAtTool() {
  delete preview_arrow_;
  delete arrow_;
}

void LookAtTool::activate() {
  context_->getViewManager()->getRenderPanel()->installEventFilter(this);
}

void LookAtTool::deactivate() {
  context_->getViewManager()->getRenderPanel()->removeEventFilter(this);
  if (preview_arrow_ != nullptr)
    preview_arrow_->getSceneNode()->setVisible(false);
}

void LookAtTool::onInitialize() {
  rviz::InteractionTool::onInitialize();
  createArrow(preview_arrow_, Ogre::Vector3::ZERO, Ogre::Vector3::UNIT_X, arrow_length_, 0.7);
  createArrow(arrow_, Ogre::Vector3::ZERO, Ogre::Vector3::UNIT_X, arrow_length_);
  preview_arrow_position_ = Ogre::Vector3::ZERO;
  arrow_position_ = Ogre::Vector3::ZERO;
  arrow_tip_ = Ogre::Vector3::ZERO;
  arrow_direction_ = Ogre::Vector3::UNIT_X;
  mode_ = MODE_PREVIEW;
}

bool LookAtTool::getNormalAtPoint(rviz::ViewportMouseEvent &event, Ogre::Vector3 &normal) {
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


int LookAtTool::processMouseEvent(rviz::ViewportMouseEvent &event) {
  if (preview_arrow_ == nullptr)
    return rviz::InteractionTool::processMouseEvent(event);
  if (arrow_ == nullptr)
    return rviz::InteractionTool::processMouseEvent(event);

  // Show preview arrow
  if (mode_ == MODE_PREVIEW) {
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

    // Place arrow
    if (event.leftDown()) {
      arrow_direction_ =
        Ogre::Vector3(normal_.x, normal_.y, normal_.z);
      arrow_position_ = preview_arrow_position_;
      arrow_tip_ = arrow_position_ + arrow_length_ * arrow_direction_;
      arrow_->setPosition(arrow_position_);
      arrow_->setDirection(arrow_direction_);
      arrow_->getSceneNode()->setVisible(true);
      preview_arrow_->getSceneNode()->setVisible(false);

      mode_ = MODE_ADAPT_DIRECTION;
      mouse_position_ = {event.x, event.y};
      original_arrow_direction_ = arrow_direction_;
      return Render;
    }
  } else if (mode_ == MODE_ADAPT_DIRECTION) {
    if(event.right())
        return rviz::InteractionTool::processMouseEvent(event);
    // adapt intersection point along current arrow_direction
    Ogre::Real wheel_delta = event.wheel_delta * scroll_factor_;
    intersection_ += wheel_delta * arrow_direction_;
    // y-Difference -> turn direction around vector vec
    Ogre::Vector3 axis = Ogre::Vector3(0,0,1);
    if(abs(original_arrow_direction_.dotProduct({0,0,1}))>0.5){
      axis=intersection_ - event.viewport->getCamera()->getPosition();;
      axis[2] = 0;
      axis.normalise();
    }
    Ogre::Vector3 vec = original_arrow_direction_.crossProduct(axis);
    Ogre::Quaternion rot = Ogre::Quaternion(
    Ogre::Degree(change_direction_factor_ * (event.y - mouse_position_.second)), vec);
    arrow_direction_ = rot * original_arrow_direction_;
    // x-Difference
    vec = axis;
    rot = Ogre::Quaternion(Ogre::Degree(change_direction_factor_ * (event.x - mouse_position_.first)), vec);
    arrow_direction_ = rot * arrow_direction_;
    // set new position (end of arrow not tip) and direction
    arrow_position_ = intersection_ - arrow_direction_ * arrow_length_;
    arrow_->setDirection(arrow_direction_);
    arrow_->setPosition(arrow_position_);
    mouse_position_translation_ = {event.x, event.y};
    return Render;
  } else if (mode_ == MODE_ADAPT_POSITION) {
      if(!event.left()) mode_=MODE_ADAPT_DISTANCE;
      if(event.right())
          return rviz::InteractionTool::processMouseEvent(event);
      // adapt intersection point along current arrow_direction
      Ogre::Real wheel_delta = event.wheel_delta * scroll_factor_;
      intersection_ += wheel_delta * arrow_direction_;
      // y-Difference -> move direction along vector vec
      Ogre::Vector3 axis = Ogre::Vector3(0,0,1);
      if(abs(original_arrow_direction_.dotProduct({0,0,1}))>0.5){
          axis=intersection_ - event.viewport->getCamera()->getPosition();;
          axis[2] = 0;
          axis.normalise();
      }
      Ogre::Vector3 vec = original_arrow_direction_.crossProduct(axis);
      intersection_ += change_position_factor_ * (event.x - mouse_position_translation_.first) * vec;
      // x-Difference
      vec = axis;
      intersection_ -= change_position_factor_ * (event.y - mouse_position_translation_.second) * vec;
      // set new position (end of arrow not tip) and direction
      arrow_position_ = intersection_ - arrow_direction_ * arrow_length_;
      arrow_->setPosition(arrow_position_);
      mouse_position_translation_ = {event.x, event.y};
      return Render;

  } else if (mode_ == MODE_ADAPT_DISTANCE) {
    if (event.wheel_delta != 0) {
      Ogre::Vector3 scrollOffset = event.wheel_delta * scroll_factor_ * arrow_direction_;
      arrow_->setPosition(arrow_->getPosition() + scrollOffset);
      return Render;
    } else if (!event.control()) {
      exitLookAt();
    }
  }

  return rviz::InteractionTool::processMouseEvent(event);
}

bool LookAtTool::eventFilter(QObject *object, QEvent *event) {
  if (event->type() == QEvent::KeyRelease) {
      auto *keyEvent = dynamic_cast<QKeyEvent *>(event);
      if (keyEvent->key() == Qt::Key_Control) {
          if (mode_ == MODE_ADAPT_DISTANCE) {
              exitLookAt();
          }
      } else {
          if (keyEvent->key() == Qt::Key_Shift) {
              if (mode_ == MODE_ADAPT_POSITION) {
                  mode_ = MODE_ADAPT_DIRECTION;
                  mouse_position_ = mouse_position_translation_;
              }
          }
      }
  }else if (event->type() == QEvent::KeyPress) {
      auto *keyEvent = dynamic_cast<QKeyEvent *>(event);
      if (keyEvent->key() == Qt::Key_Shift) {
          if (mode_ == MODE_ADAPT_DIRECTION) {
              mode_ = MODE_ADAPT_POSITION;
              mouse_position_translation_ = mouse_position_;
          }
      }
  } else if (event->type() == QEvent::MouseButtonRelease) {
    auto *mouseEvent = dynamic_cast<QMouseEvent *>(event);
    if (mouseEvent->button() == Qt::MouseButton::LeftButton && mode_ == MODE_ADAPT_DIRECTION)
        mode_ = MODE_ADAPT_DISTANCE;
  }
  return false;
}

void LookAtTool::exitLookAt() {
  mode_ = MODE_PREVIEW;
  context_->getToolManager()->setCurrentTool(context_->getToolManager()->getDefaultTool());
}

void LookAtTool::createArrow(rviz::Arrow *&arrow, const Ogre::Vector3 &base, const Ogre::Vector3 &direction,
                             double length, double alpha) {
  arrow = new rviz::Arrow(context_->getSceneManager(), scene_manager_->getRootSceneNode());
  arrow->set(0.75f * length, 0.025, 0.25 * length, 0.075);
  arrow->setColor(255.0 / 255.0, 210.0 / 255.0, 0, alpha);
  arrow->setPosition(base);
  arrow->setDirection(direction);
  arrow->getSceneNode()->setVisible(false);
}

QVector3D LookAtTool::lookAtPosition() const {
  return {arrow_tip_.x, arrow_tip_.y, arrow_tip_.z};
}

QVector3D LookAtTool::lookAtDirection() const {
  return {arrow_direction_.x, arrow_direction_.y, arrow_direction_.z};
}

QQuaternion LookAtTool::lookAtOrientation() const {
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

PLUGINLIB_EXPORT_CLASS(hector_user_interface::LookAtTool, rviz::Tool)

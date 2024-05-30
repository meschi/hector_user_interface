//
// Created by Jonas Suess on 19.04.2023
//

#ifndef HECTOR_USER_INTERFACE_SWIPE_SKILL_TOOL_H
#define HECTOR_USER_INTERFACE_SWIPE_SKILL_TOOL_H

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

class SwipeSkillTool : public rviz::InteractionTool {
Q_OBJECT
  Q_PROPERTY(QVector3D lookAtPosition READ lookAtPosition NOTIFY lookAtChanged)
  Q_PROPERTY(QVector3D lookAtDirection READ lookAtDirection NOTIFY lookAtChanged)
  Q_PROPERTY(QQuaternion lookAtOrientation READ lookAtOrientation NOTIFY lookAtChanged)

  enum SelectionMode {
    MODE_PREVIEW,
    MODE_ADAPT_DIRECTION,
    MODE_ADAPT_DISTANCE,
    MODE_ADAPT_POSITION
  };

public:
  SwipeSkillTool();

  ~SwipeSkillTool();

  void activate() override;

  void deactivate() override;

  int processMouseEvent(rviz::ViewportMouseEvent &event) override;

  QVector3D lookAtPosition() const;

  QVector3D lookAtDirection() const;

  QQuaternion lookAtOrientation() const;

signals:

  void lookAtChanged();

protected:
  void exitLookAt();

  void onInitialize() override;

  void createArrow(rviz::Arrow *&arrow, const Ogre::Vector3 &base, const Ogre::Vector3 &direction, double length,
                   double alpha = 1.0);

  bool eventFilter(QObject *object, QEvent *event) override;

  bool getNormalAtPoint(rviz::ViewportMouseEvent &event, Ogre::Vector3 &normal);

  rviz::Arrow *arrow_ = nullptr;
  rviz::Arrow *preview_arrow_ = nullptr;
  Ogre::Vector3 preview_arrow_position_, camera_intersection_offset_, normal_;
  Ogre::Vector3 arrow_position_, arrow_tip_, arrow_direction_;
  Ogre::Vector3 original_arrow_direction_, intersection_;
  std::pair<int, int> mouse_position_, mouse_position_translation_;
  Ogre::Real arrow_length_ = 0.3;
  Ogre::Real scroll_factor_ = 0.0005;
  Ogre::Real change_direction_factor_ = 0.5;
  Ogre::Real change_position_factor_ = 0.005;
  SelectionMode mode_;
  ros::NodeHandle nh_;
};
}  // namespace hector_user_interface

#endif  // HECTOR_USER_INTERFACE_SWIPE_SKILL_TOOL_H

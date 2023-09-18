//
// Created by Stefan Fabian on 23.03.21.
//

#ifndef HECTOR_USER_INTERFACE_WAYPOINT_TOOL_H
#define HECTOR_USER_INTERFACE_WAYPOINT_TOOL_H

#include <rviz/default_plugin/tools/interaction_tool.h>

#include <OgreSharedPtr.h>
#include <QQuaternion>
#include <QVariantMap>

namespace Ogre
{
class SceneNode;

class Vector3;
} // namespace Ogre

namespace hector_user_interface
{

class WaypointTool : public rviz::InteractionTool
{
  Q_OBJECT
  Q_PROPERTY( QVariantList waypoints READ waypoints NOTIFY waypointsChanged )
  Q_PROPERTY( QString frame READ frame )
public:
  WaypointTool();

  ~WaypointTool();

  void activate() override;

  void deactivate() override;

  int processMouseEvent( rviz::ViewportMouseEvent &event ) override;

  int processKeyEvent( QKeyEvent *event, rviz::RenderPanel *panel ) override;

  QVariantList waypoints() const;

  Q_INVOKABLE void clearWaypoints();

  Q_INVOKABLE void removeWaypoint( int index );

  Q_INVOKABLE void addWaypoint( const QVector3D &position,
                                const QQuaternion &orientation = QQuaternion( 0, 0, 0, 0 ) );

  Q_INVOKABLE void addWaypoint( float x, float y, float z );

  Q_INVOKABLE void addWaypoint( float x, float y, float z, float qw, float qx, float qy, float qz );

  QString frame() const;

signals:

  void waypointsChanged();

  void waypointRemoved( int index, QVariantMap waypoint );

  void waypointAdded( QVariantMap waypoint );

protected:
  void onInitialize() override;

  Ogre::SceneNode *createWaypointNode();

  void destroyWaypointNode( Ogre::SceneNode *node );

  Ogre::SceneNode *createWaypointNode( const Ogre::Vector3 &position,
                                       const Ogre::Quaternion &orientation );

  Ogre::MeshPtr preview_mesh_;
  Ogre::MeshPtr arrow_mesh_;
  Ogre::SceneNode *waypoint_preview_node_ = nullptr;
  std::vector<Ogre::SceneNode *> waypoint_nodes_;
  QVariantList waypoints_;
  // The waypoint that is currently placed. Nullptr if not currently in placing state.
  Ogre::SceneNode *active_waypoint_ = nullptr;
  rviz::BoolProperty *raycast3d_property_ = nullptr;
};
} // namespace hector_user_interface

#endif // HECTOR_USER_INTERFACE_WAYPOINT_TOOL_H

//
// Created by Stefan Fabian on 23.03.21.
//

#include <hector_user_interface/waypoint_tool.h>

#include <OgreEntity.h>
#include <OgreSceneManager.h>
#include <OgreSubMesh.h>
#include <rviz/display_context.h>
#include <rviz/geometry.h>
#include <rviz/mesh_loader.h>
#include <rviz/properties/bool_property.h>
#include <rviz/selection/selection_manager.h>
#include <rviz/viewport_mouse_event.h>

#include <ros/console.h>
#include <ros/package.h>

#include <QVector3D>

namespace hector_user_interface
{

const char *WAYPOINT_PREVIEW_RESOURCE = "package://hector_user_interface/media/flag.dae";
const char *WAYPOINT_ARROW_RESOURCE = "package://hector_user_interface/media/arrow.dae";
const float WAYPOINT_PREVIEW_SCALE = 0.1f;

WaypointTool::WaypointTool()
{
  shortcut_key_ = 'w';
  raycast3d_property_ = new rviz::BoolProperty(
      "3D Raycast", true,
      "If true, will use scene manager to find intersection with compatible displayed entities. "
      "If false, will only check for intersection with ground plane.",
      this->getPropertyContainer() );
}

WaypointTool::~WaypointTool()
{
  blockSignals( true );
  clearWaypoints();

  if ( waypoint_preview_node_ != nullptr )
    destroyWaypointNode( waypoint_preview_node_ );
  if ( active_waypoint_ )
    destroyWaypointNode( active_waypoint_ );
}

void WaypointTool::onInitialize()
{
  rviz::InteractionTool::onInitialize();
  preview_mesh_ = rviz::loadMeshFromResource( WAYPOINT_PREVIEW_RESOURCE );
  if ( preview_mesh_.isNull() ) {
    ROS_ERROR_NAMED( "hector_user_interface", "Failed to load waypoint tool preview mesh." );
    return;
  }
  arrow_mesh_ = rviz::loadMeshFromResource( WAYPOINT_ARROW_RESOURCE );
  if ( arrow_mesh_.isNull() ) {
    ROS_ERROR_NAMED( "hector_user_interface",
                     "Failed to load waypoint tool orientation preview mesh." );
    return;
  }
  waypoint_preview_node_ = createWaypointNode();
  waypoint_preview_node_->setVisible( false );
}

Ogre::SceneNode *WaypointTool::createWaypointNode()
{
  Ogre::SceneNode *node = scene_manager_->getRootSceneNode()->createChildSceneNode();
  Ogre::Entity *entity = scene_manager_->createEntity( preview_mesh_ );
  node->attachObject( entity );
  node->setScale( WAYPOINT_PREVIEW_SCALE, WAYPOINT_PREVIEW_SCALE, WAYPOINT_PREVIEW_SCALE );
  Ogre::SceneNode *arrow_node = node->createChildSceneNode();
  entity = scene_manager_->createEntity( arrow_mesh_ );
  arrow_node->attachObject( entity );
  arrow_node->setVisible( false );
  arrow_node->setScale( 30 * WAYPOINT_PREVIEW_SCALE, 30 * WAYPOINT_PREVIEW_SCALE,
                        30 * WAYPOINT_PREVIEW_SCALE );
  return node;
}

void WaypointTool::destroyWaypointNode( Ogre::SceneNode *node )
{
  node->removeAndDestroyAllChildren();
  // Destroy waypoint node
  scene_manager_->getRootSceneNode()->removeChild( node );
  delete node;
}

void WaypointTool::activate()
{
  if ( waypoint_preview_node_ == nullptr )
    return;
  waypoint_preview_node_->setVisible( true, false );
}

void WaypointTool::deactivate()
{
  if ( waypoint_preview_node_ == nullptr )
    return;
  waypoint_preview_node_->setVisible( false );
}

namespace
{

template<typename Scalar>
Scalar square( Scalar x )
{
  return x * x;
}

void setWaypointOrientation( Ogre::SceneNode *node, const Ogre::Quaternion &orientation )
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
} // namespace

int WaypointTool::processMouseEvent( rviz::ViewportMouseEvent &event )
{
  if ( waypoint_preview_node_ == nullptr )
    return rviz::InteractionTool::processMouseEvent( event );

  // Perform raycast
  waypoint_preview_node_->setVisible( false ); // Disable for raycast
  Ogre::Vector3 intersection;
  if ( !raycast3d_property_->getBool() || !context_->getSelectionManager()->get3DPoint(
                                              event.viewport, event.x, event.y, intersection ) ) {
    // Fall back to plane intersection
    Ogre::Plane ground_plane( Ogre::Vector3::UNIT_Z, 0.f );
    if ( !rviz::getPointOnPlaneFromWindowXY( event.viewport, ground_plane, event.x, event.y,
                                             intersection ) ) {
      return Render;
    }
  }

  // Show preview node at current intersection unless we are in the process of placing a waypoint
  waypoint_preview_node_->setVisible( active_waypoint_ == nullptr, false );
  waypoint_preview_node_->setPosition( intersection );
  if ( event.leftDown() ) {
    active_waypoint_ = createWaypointNode( intersection, Ogre::Quaternion::ZERO );
    return Render;
  }
  if ( event.rightDown() ) {
    if ( active_waypoint_ != nullptr ) {
      destroyWaypointNode( active_waypoint_ );
      active_waypoint_ = nullptr;
    }
    // Right click removes last waypoint
    if ( waypoint_nodes_.empty() )
      return 0;
    removeWaypoint( static_cast<int>( waypoint_nodes_.size() - 1 ) );
    return Render;
  }
  if ( active_waypoint_ != nullptr ) {
    const Ogre::Vector3 &waypoint_position = active_waypoint_->getPosition();
    Ogre::Real offset_x = intersection.x - waypoint_position.x;
    Ogre::Real offset_y = intersection.y - waypoint_position.y;
    Ogre::Real length = std::sqrt( square( offset_x ) + square( offset_y ) );
    if ( length > 1E-6 ) {
      offset_x /= 2 * length;
      offset_y /= 2 * length;
    }
    // Rotate the arrow so it points in the direction of the intersection
    Ogre::Real angle = std::atan2( offset_y, offset_x );
    Ogre::Quaternion orientation = Ogre::Quaternion::ZERO;
    if ( length >= 0.1 )
      orientation = Ogre::Quaternion( std::cos( angle / 2 ), 0, 0, std::sin( angle / 2 ) );
    setWaypointOrientation( active_waypoint_, orientation );
    if ( event.leftUp() ) {
      waypoint_nodes_.push_back( active_waypoint_ );
      QVariantMap waypoint;
      waypoint.insert( "position",
                       QVector3D( waypoint_position.x, waypoint_position.y, waypoint_position.z ) );
      waypoint.insert( "orientation",
                       QQuaternion( orientation.w, orientation.x, orientation.y, orientation.z ) );
      waypoints_.push_back( waypoint );
      emit waypointAdded( waypoint );
      emit waypointsChanged();
      active_waypoint_ = nullptr;
    }
    return Render;
  }
  return rviz::InteractionTool::processMouseEvent( event );
}

int WaypointTool::processKeyEvent( QKeyEvent *event, rviz::RenderPanel *panel )
{
  return rviz::InteractionTool::processKeyEvent( event, panel );
}

Ogre::SceneNode *WaypointTool::createWaypointNode( const Ogre::Vector3 &position,
                                                   const Ogre::Quaternion &orientation )
{
  Ogre::SceneNode *node = createWaypointNode();
  node->setVisible( true, false );
  node->setPosition( position );
  setWaypointOrientation( node, orientation );
  return node;
}

QVariantList WaypointTool::waypoints() const { return waypoints_; }

void WaypointTool::clearWaypoints()
{
  for ( const auto &node : waypoint_nodes_ ) { destroyWaypointNode( node ); }
  waypoint_nodes_.clear();
  waypoints_.clear();
  emit waypointsChanged();
}

QString WaypointTool::frame() const { return context_->getFixedFrame(); }

Q_INVOKABLE void WaypointTool::removeWaypoint( int index )
{
  if ( index >= waypoints_.size() || index < 0 ) {
    ROS_ERROR_STREAM_NAMED( "hector_user_interface", "Index " << index << " out of bounds." );
    return;
  }
  Ogre::SceneNode *node = waypoint_nodes_.at( index );
  destroyWaypointNode( node );
  waypoint_nodes_.erase( waypoint_nodes_.begin() + index );
  QVariantMap waypoint = waypoints_[index].toMap();
  waypoints_.removeAt( index );
  emit waypointRemoved( index, waypoint );
  emit waypointsChanged();
}

Q_INVOKABLE void WaypointTool::addWaypoint( const QVector3D &position, const QQuaternion &orientation )
{
  createWaypointNode(
      Ogre::Vector3{ position.x(), position.y(), position.z() },
      Ogre::Quaternion( orientation.scalar(), orientation.x(), orientation.y(), orientation.z() ) );
  QVariantMap waypoint;
  waypoint.insert( "position", position );
  waypoint.insert( "orientation", orientation );
  waypoints_.push_back( waypoint );
}

Q_INVOKABLE void WaypointTool::addWaypoint( float x, float y, float z )
{
  addWaypoint( x, y, z, 0, 0, 0, 0 );
}

Q_INVOKABLE void WaypointTool::addWaypoint( float x, float y, float z, float qw, float qx, float qy,
                                            float qz )
{
  addWaypoint( QVector3D( x, y, z ), QQuaternion( qw, qx, qy, qz ) );
}
} // namespace hector_user_interface

#include <pluginlib/class_list_macros.h>

PLUGINLIB_EXPORT_CLASS( hector_user_interface::WaypointTool, rviz::Tool )

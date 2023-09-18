//
// Created by Stefan Fabian on 07.02.20.
//

#include "hector_user_interface/user_interface.h"

#include <ros/package.h>

namespace hector_user_interface
{
QString UserInterface::getPathToQml()
{
  std::string path = ros::package::getPath( "hector_user_interface" );
  return QString::fromStdString( path ) + "/ui/main.qml";
}
} // namespace hector_user_interface

#include <pluginlib/class_list_macros.h>

PLUGINLIB_EXPORT_CLASS( hector_user_interface::UserInterface, rviz::Display )
cmake_minimum_required(VERSION 3.5.0)
project(hector_user_interface_resources VERSION 1.0.0)

find_package(catkin REQUIRED)

catkin_package()

catkin_add_env_hooks(export_hector_user_interface_resources SHELLS sh)

#############
## Install ##
#############

# all install targets should use catkin DESTINATION variables
# See http://ros.org/doc/api/catkin/html/adv_user_guide/variables.html

install(DIRECTORY Hector DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})

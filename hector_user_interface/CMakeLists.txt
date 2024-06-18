cmake_minimum_required(VERSION 3.5.0)
project(hector_user_interface VERSION 1.0.0)
set(CMAKE_CXX_STANDARD 11)

find_package(catkin REQUIRED COMPONENTS hector_rviz_overlay rviz)
find_package(Qt5 COMPONENTS Core REQUIRED)
set(CMAKE_AUTOMOC ON)

catkin_package(
  LIBRARIES hector_user_interface
  CATKIN_DEPENDS hector_rviz_overlay rviz
#  DEPENDS system_lib
)

###########
## Build ##
###########

include_directories(
  include
  ${catkin_INCLUDE_DIRS}
)

add_library(${PROJECT_NAME}
  include/hector_user_interface/look_at_tool.h
  include/hector_user_interface/user_interface.h
  include/hector_user_interface/waypoint_tool.h
  include/hector_user_interface/swipe_skill_tool.h
  include/hector_user_interface/stop_swipe_tool.h
  src/look_at_tool.cpp
  src/user_interface.cpp
  src/waypoint_tool.cpp
  src/swipe_skill_tool.cpp
  src/stop_swipe_tool.cpp
)
target_link_libraries(${PROJECT_NAME} ${catkin_LIBRARIES})


#############
## Install ##
#############

# all install targets should use catkin DESTINATION variables
# See http://ros.org/doc/api/catkin/html/adv_user_guide/variables.html

## Mark libraries for installation
## See http://docs.ros.org/melodic/api/catkin/html/howto/format1/building_libraries.html
install(TARGETS ${PROJECT_NAME} LIBRARY DESTINATION ${CATKIN_PACKAGE_LIB_DESTINATION})

install(DIRECTORY icons media ui DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})
install(FILES plugin_description.xml DESTINATION ${CATKIN_PACKAGE_SHARE_DESTINATION})

cmake_minimum_required(VERSION 3.20)
project(Iris LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick DBus Network)
qt_standard_project_setup(REQUIRES 6.5)   # turns on AUTOMOC etc.

# Lets qmlls find the module (generates .qmlls.ini)
set(QT_QML_GENERATE_QMLLS_INI ON)

qt_add_qml_module(iris
    URI Iris
    VERSION 1.0
    PLUGIN_TARGET iris
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Iris
    SOURCES
        src/core/Theme.h
        src/core/Theme.cpp
        src/core/Applications.h
        src/core/Applications.cpp
        src/core/Cava.h
        src/core/Cava.cpp
        src/core/Brightness.h
        src/core/Brightness.cpp
        src/core/Hud.h
        src/core/Hud.cpp
        src/core/WavyBar.h
        src/core/WavyBar.cpp
        src/core/Wallpapers.h
        src/core/Wallpapers.cpp
        src/core/SysInfo.h
        src/core/SysInfo.cpp
        src/core/Config.h
        src/core/Config.cpp
)

target_include_directories(iris PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
)

target_link_libraries(iris PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::DBus
    Qt6::Network
)

install(DIRECTORY ${CMAKE_BINARY_DIR}/Iris
    DESTINATION ${QT6_INSTALL_PREFIX}/${QT6_INSTALL_QML}
)
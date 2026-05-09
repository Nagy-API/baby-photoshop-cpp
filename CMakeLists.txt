cmake_minimum_required(VERSION 3.16)

project(BabyPhotoshopNeo VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 6.2 COMPONENTS Quick REQUIRED)

qt_add_executable(appBabyPhotoshopNeo
    main.cpp
    imageprocessor.cpp
    imageprocessor.h
    libs/Image_Class.h
    libs/stb_image.h
    libs/stb_image_write.h
)

qt_add_qml_module(appBabyPhotoshopNeo
    URI BabyPhotoshopNeo
    VERSION 1.0
    RESOURCE_PREFIX /
    QML_FILES
        main.qml
)

qt_add_resources(appBabyPhotoshopNeo "pixora_assets"
    PREFIX "/"
    FILES
        assets/splash_pixora.png
        assets/ui_reference.png
        assets/moon_real.jpg
        assets/rocket_3d.jpg
        assets/samples/sample_toys.jpg
        assets/samples/sample_samurai.jpg
        assets/samples/sample_sunset.jpg
)

set_target_properties(appBabyPhotoshopNeo PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_include_directories(appBabyPhotoshopNeo
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/libs
)

target_link_libraries(appBabyPhotoshopNeo
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)

install(TARGETS appBabyPhotoshopNeo
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
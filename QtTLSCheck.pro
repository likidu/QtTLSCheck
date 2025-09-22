TEMPLATE = app
TARGET = QtTLSCheck

# Qt 4.x modules
QT += core gui network declarative

CONFIG -= debug_and_release
CONFIG += debug
CONFIG(debug, debug|release) { CONFIG += console }

# Place all build artifacts inside build directory
DESTDIR = $$OUT_PWD
OBJECTS_DIR = $$OUT_PWD/obj
MOC_DIR = $$OUT_PWD/moc
RCC_DIR = $$OUT_PWD/rcc
UI_DIR = $$OUT_PWD/ui

INCLUDEPATH += src

SOURCES += \
    src/main.cpp \
    src/TlsChecker.cpp

HEADERS += \
    src/TlsChecker.h

RESOURCES += \
    qml/qml.qrc

OTHER_FILES += \
    qml/MainPage.qml

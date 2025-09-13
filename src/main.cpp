#include <QtGui/QApplication>
#include <QtCore/QCoreApplication>
#include <QtCore/QStringList>
#include "MainWindow.h"

int main(int argc, char *argv[])
{
    // Use raster graphics system on older Qt/Win to avoid driver quirks
    QApplication::setGraphicsSystem("raster");
    QApplication a(argc, argv);

    // Keep plugin lookups local to the app folder to avoid mismatched plugins
    QCoreApplication::setLibraryPaths(QStringList() << QApplication::applicationDirPath());
    MainWindow w;
    w.resize(360, 240);
    w.show();
    return a.exec();
}

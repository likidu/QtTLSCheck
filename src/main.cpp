#include <QtGui/QApplication>
#include <QtCore/QCoreApplication>
#include <QtCore/QStringList>
#include <QtCore/QSize>
#include <QtCore/QUrl>
#include <QtDeclarative/QDeclarativeView>
#include <QtDeclarative/QDeclarativeContext>

#include "TlsChecker.h"

int main(int argc, char *argv[])
{
    // Use raster graphics system on older Qt/Win to avoid driver quirks
    QApplication::setGraphicsSystem("raster");
    QApplication app(argc, argv);

    // Keep plugin lookups local to the app folder to avoid mismatched plugins
    QCoreApplication::setLibraryPaths(QStringList() << QApplication::applicationDirPath());

    TlsChecker checker;

    QDeclarativeView view;
    view.rootContext()->setContextProperty("tlsChecker", &checker);
    view.setSource(QUrl("qrc:/qml/MainPage.qml"));
    view.setResizeMode(QDeclarativeView::SizeRootObjectToView);
    view.setWindowTitle(QObject::tr("Qt TLS Check"));
    view.setMinimumSize(QSize(360, 640));
    view.setMaximumSize(QSize(480, 800));
    view.resize(360, 640);

    view.show();
    return app.exec();
}

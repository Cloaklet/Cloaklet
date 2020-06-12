#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFont>
#include <QFontDatabase>
#include <QDirIterator>

#include "cursorposprovider.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    // FIXME
    app.setApplicationDisplayName(QStringLiteral("Cloaklet"));

    // Load custom font
    QDirIterator fonts(":/fonts");
    int fontId;
    while (fonts.hasNext()) {
        QString fontFilename = fonts.next();
        if (fontFilename.endsWith(".ttf")) {
            fontId = QFontDatabase::addApplicationFont(fontFilename);
            qDebug() << fontId;
        }
    }
    QFont openSans(QFontDatabase::applicationFontFamilies(fontId).at(0));
    app.setFont(openSans);

    CursorPosProvider mousePosProvider;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("mousePosition", &mousePosProvider);
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}


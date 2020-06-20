#include "_cgo_export.h"
#include "extend.h"
#include <QApplication>
#include <QCursor>
#include <QPointF>
#include <QFont>
#include <QFontDatabase>
#include <QDirIterator>

QPointF MousePos::pos() {
    return QCursor::pos();
}

void MousePos_RegisterQML(char* uri, int versionMajor, int versionMinor, char* qmlName) {
    qmlRegisterType<MousePos>(uri, versionMajor, versionMinor, qmlName);
}

void LoadFonts() {
    QDirIterator fonts(":/res/fonts");
    int fontId;
    while (fonts.hasNext()) {
        QString fontFileName = fonts.next();
        if (fontFileName.endsWith(".ttf")) {
            fontId = QFontDatabase::addApplicationFont(fontFileName);
        }
    }
    QFont openSans(QFontDatabase::applicationFontFamilies(fontId).at(0));
    QApplication::setFont(openSans);
}

#include "moc-extend.h"

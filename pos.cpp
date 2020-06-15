#include "_cgo_export.h"
#include "pos.h"
#include <QCursor>
#include <QPointF>

QPointF MousePos::pos() {
    return QCursor::pos();
}

void MousePos_RegisterQML(char* uri, int versionMajor, int versionMinor, char* qmlName) {
	qmlRegisterType<MousePos>(uri, versionMajor, versionMinor, qmlName);
}

#include "moc-pos.h"

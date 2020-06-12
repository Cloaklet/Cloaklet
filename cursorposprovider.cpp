#include "cursorposprovider.h"

// Ref: https://stackoverflow.com/a/39265325

CursorPosProvider::CursorPosProvider(QObject *parent) : QObject(parent)
{
}

QPointF CursorPosProvider::cursorPos() {
    return QCursor::pos();
}

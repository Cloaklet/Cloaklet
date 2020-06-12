#ifndef CURSORPOSPROVIDER_H
#define CURSORPOSPROVIDER_H

#include <QObject>
#include <QPointF>
#include <QCursor>

class CursorPosProvider : public QObject
{
    Q_OBJECT
public:
    explicit CursorPosProvider(QObject *parent = nullptr);
    virtual ~CursorPosProvider() = default;
    Q_INVOKABLE QPointF cursorPos();
signals:

};

#endif // CURSORPOSPROVIDER_H

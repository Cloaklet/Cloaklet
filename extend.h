#pragma once

#ifndef CLOAK_POS_H
#define CLOAK_POS_H

#ifdef __cplusplus

#include <QObject>
#include <QQuickItem>
#include <QPointF>

#include "_cgo_export.h"

class MousePos : public QQuickItem {
	Q_OBJECT

private:

public:

signals:

public slots:
	QPointF pos();
};

extern "C" {
#endif

void MousePos_RegisterQML(char* uri, int versionMajor, int versionMinor, char* qmlName);

void LoadFonts();

#ifdef __cplusplus
}
#endif

#endif

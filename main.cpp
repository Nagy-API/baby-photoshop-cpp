#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

#include "imageprocessor.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    ImageProcessor imageProcessor;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("imageProcessor", &imageProcessor);

    const QUrl url(QStringLiteral("qrc:/BabyPhotoshopNeo/main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection
        );

    engine.load(url);

    return QCoreApplication::exec();
}

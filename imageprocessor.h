#ifndef IMAGEPROCESSOR_H
#define IMAGEPROCESSOR_H

#include <QObject>
#include <QString>

class ImageProcessor : public QObject
{
    Q_OBJECT

public:
    explicit ImageProcessor(QObject *parent = nullptr);

    Q_INVOKABLE QString applyFilterAdvanced(
        const QString &inputPath,
        const QString &filterName,
        double strength,
        int p1,
        int p2,
        int p3,
        int p4
        );

    Q_INVOKABLE QString mergeImages(
        const QString &firstPath,
        const QString &secondPath,
        double opacity
        );

    Q_INVOKABLE bool exportImage(
        const QString &inputPath,
        const QString &outputPath
        );

    Q_INVOKABLE QString loadSampleImage(
        const QString &resourcePath,
        const QString &outputName
        );

    Q_INVOKABLE QString applyPreset(
        const QString &inputPath,
        const QString &presetName
        );

private:
    QString normalizePath(const QString &path) const;
    QString outputDirectory() const;
    QString createOutputPath(const QString &suffix = "png") const;
    int clampInt(int value, int minValue = 0, int maxValue = 255) const;
};

#endif // IMAGEPROCESSOR_H
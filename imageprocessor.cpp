#include "imageprocessor.h"

#include <QImage>
#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QPainter>
#include <QStandardPaths>
#include <QDateTime>
#include <QUrl>
#include <QtMath>

ImageProcessor::ImageProcessor(QObject *parent)
    : QObject(parent)
{
}

QString ImageProcessor::normalizePath(const QString &path) const
{
    QString p = path;

    if (p.startsWith("file:///"))
        p = QUrl(p).toLocalFile();

    return p;
}

QString ImageProcessor::outputDirectory() const
{
    QString dir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);

    if (dir.isEmpty())
        dir = QDir::homePath();

    dir += "/Pixora_Output";

    QDir outputDir(dir);

    if (!outputDir.exists())
        outputDir.mkpath(".");

    return dir;
}

QString ImageProcessor::createOutputPath(const QString &suffix) const
{
    const QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss_zzz");
    return outputDirectory() + "/pixora_" + timestamp + "." + suffix;
}

int ImageProcessor::clampInt(int value, int minValue, int maxValue) const
{
    return qMax(minValue, qMin(maxValue, value));
}

QString ImageProcessor::applyFilterAdvanced(
    const QString &inputPath,
    const QString &filterName,
    double strength,
    int p1,
    int p2,
    int p3,
    int p4
    )
{
    const QString cleanInput = normalizePath(inputPath);

    QImage img(cleanInput);

    if (img.isNull())
        return "";

    img = img.convertToFormat(QImage::Format_ARGB32);

    QImage result = img;

    if (filterName == "Grayscale") {
        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);
                int gray = (c.red() + c.green() + c.blue()) / 3;
                line[x] = qRgba(gray, gray, gray, c.alpha());
            }
        }
    }

    else if (filterName == "Black & White") {
        int threshold = clampInt(static_cast<int>(128 * strength), 40, 220);

        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);
                int gray = (c.red() + c.green() + c.blue()) / 3;
                int bw = gray >= threshold ? 255 : 0;
                line[x] = qRgba(bw, bw, bw, c.alpha());
            }
        }
    }

    else if (filterName == "Invert") {
        result.invertPixels(QImage::InvertRgb);
    }

    else if (filterName == "Brightness") {
        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);

                int r = clampInt(static_cast<int>(c.red() * strength));
                int g = clampInt(static_cast<int>(c.green() * strength));
                int b = clampInt(static_cast<int>(c.blue() * strength));

                line[x] = qRgba(r, g, b, c.alpha());
            }
        }
    }

    else if (filterName == "Purple Tone") {
        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);

                int r = clampInt(c.red() + static_cast<int>(38 * strength));
                int g = clampInt(c.green() - static_cast<int>(12 * strength));
                int b = clampInt(c.blue() + static_cast<int>(56 * strength));

                line[x] = qRgba(r, g, b, c.alpha());
            }
        }
    }

    else if (filterName == "Sunlight") {
        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);

                int r = clampInt(c.red() + static_cast<int>(45 * strength));
                int g = clampInt(c.green() + static_cast<int>(22 * strength));
                int b = clampInt(c.blue() - static_cast<int>(10 * strength));

                line[x] = qRgba(r, g, b, c.alpha());
            }
        }
    }

    else if (filterName == "TV Effect") {
        for (int y = 0; y < result.height(); ++y) {
            QRgb *line = reinterpret_cast<QRgb *>(result.scanLine(y));

            for (int x = 0; x < result.width(); ++x) {
                QColor c(line[x]);

                int noise = ((x * 13 + y * 7) % 31) - 15;
                int scan = (y % 4 == 0) ? static_cast<int>(28 * strength) : 0;

                int r = clampInt(c.red() + noise - scan);
                int g = clampInt(c.green() + noise - scan);
                int b = clampInt(c.blue() + noise - scan);

                line[x] = qRgba(r, g, b, c.alpha());
            }
        }
    }

    else if (filterName == "Blur") {
        int radius = clampInt(static_cast<int>(strength), 1, 16);

        if (radius <= 1) {
            result = img;
        } else {
            QSize smallSize(
                qMax(1, img.width() / radius),
                qMax(1, img.height() / radius)
                );

            result = img.scaled(
                            smallSize,
                            Qt::IgnoreAspectRatio,
                            Qt::SmoothTransformation
                            ).scaled(
                             img.size(),
                             Qt::IgnoreAspectRatio,
                             Qt::SmoothTransformation
                             );
        }
    }

    else if (filterName == "Frame") {
        int thickness = qMax(1, p1);

        QColor frameColor(
            clampInt(p2),
            clampInt(p3),
            clampInt(p4)
            );

        QImage framed(
            img.width() + thickness * 2,
            img.height() + thickness * 2,
            QImage::Format_ARGB32
            );

        framed.fill(frameColor);

        QPainter painter(&framed);
        painter.drawImage(thickness, thickness, img);
        painter.end();

        result = framed;
    }

    else if (filterName == "Flip Horizontal") {
        result = img.flipped(Qt::Horizontal);
    }

    else if (filterName == "Flip Vertical") {
        result = img.flipped(Qt::Vertical);
    }

    else if (filterName == "Rotate 90") {
        QTransform transform;
        transform.rotate(90);
        result = img.transformed(transform, Qt::SmoothTransformation);
    }

    else if (filterName == "Rotate 180") {
        QTransform transform;
        transform.rotate(180);
        result = img.transformed(transform, Qt::SmoothTransformation);
    }

    else if (filterName == "Rotate 270") {
        QTransform transform;
        transform.rotate(270);
        result = img.transformed(transform, Qt::SmoothTransformation);
    }

    else if (filterName == "Resize") {
        int newW = qMax(1, p1);
        int newH = qMax(1, p2);

        result = img.scaled(
            newW,
            newH,
            Qt::IgnoreAspectRatio,
            Qt::SmoothTransformation
            );
    }

    else if (filterName == "Crop") {
        int x = clampInt(p1, 0, img.width() - 1);
        int y = clampInt(p2, 0, img.height() - 1);
        int w = qMax(1, p3);
        int h = qMax(1, p4);

        if (x + w > img.width())
            w = img.width() - x;

        if (y + h > img.height())
            h = img.height() - y;

        result = img.copy(x, y, w, h);
    }

    else if (filterName == "Edge Detection") {
        QImage gray = img.convertToFormat(QImage::Format_ARGB32);
        result = QImage(img.size(), QImage::Format_ARGB32);
        result.fill(Qt::black);

        for (int y = 1; y < img.height() - 1; ++y) {
            for (int x = 1; x < img.width() - 1; ++x) {
                auto intensity = [&](int px, int py) -> int {
                    QColor c(gray.pixel(px, py));
                    return (c.red() + c.green() + c.blue()) / 3;
                };

                int gx =
                    -intensity(x - 1, y - 1) + intensity(x + 1, y - 1)
                    -2 * intensity(x - 1, y) + 2 * intensity(x + 1, y)
                    -intensity(x - 1, y + 1) + intensity(x + 1, y + 1);

                int gy =
                    -intensity(x - 1, y - 1) - 2 * intensity(x, y - 1) - intensity(x + 1, y - 1)
                    + intensity(x - 1, y + 1) + 2 * intensity(x, y + 1) + intensity(x + 1, y + 1);

                int magnitude = clampInt(static_cast<int>(qSqrt(gx * gx + gy * gy)));
                result.setPixel(x, y, qRgba(magnitude, magnitude, magnitude, 255));
            }
        }
    }

    const QString outputPath = createOutputPath("png");

    if (!result.save(outputPath))
        return "";

    return QUrl::fromLocalFile(outputPath).toString();
}

QString ImageProcessor::mergeImages(
    const QString &firstPath,
    const QString &secondPath,
    double opacity
    )
{
    const QString cleanFirst = normalizePath(firstPath);
    const QString cleanSecond = normalizePath(secondPath);

    QImage base(cleanFirst);
    QImage overlay(cleanSecond);

    if (base.isNull() || overlay.isNull())
        return "";

    base = base.convertToFormat(QImage::Format_ARGB32);
    overlay = overlay.convertToFormat(QImage::Format_ARGB32);

    overlay = overlay.scaled(
        base.size(),
        Qt::IgnoreAspectRatio,
        Qt::SmoothTransformation
        );

    QImage result = base.copy();

    QPainter painter(&result);
    painter.setOpacity(qBound(0.0, opacity, 1.0));
    painter.drawImage(0, 0, overlay);
    painter.end();

    const QString outputPath = createOutputPath("png");

    if (!result.save(outputPath))
        return "";

    return QUrl::fromLocalFile(outputPath).toString();
}

bool ImageProcessor::exportImage(
    const QString &inputPath,
    const QString &outputPath
    )
{
    const QString cleanInput = normalizePath(inputPath);
    const QString cleanOutput = normalizePath(outputPath);

    QImage img(cleanInput);

    if (img.isNull())
        return false;

    QString suffix = QFileInfo(cleanOutput).suffix().toLower();

    if (suffix.isEmpty())
        suffix = "png";

    return img.save(cleanOutput, suffix.toUpper().toUtf8().constData());
}

QString ImageProcessor::loadSampleImage(
    const QString &resourcePath,
    const QString &outputName
    )
{
    QImage sample(resourcePath);

    if (sample.isNull())
        return "";

    QString cleanName = outputName;

    if (cleanName.trimmed().isEmpty())
        cleanName = "sample.png";

    QString finalPath = outputDirectory() + "/" + cleanName;

    if (!sample.save(finalPath))
        return "";

    return QUrl::fromLocalFile(finalPath).toString();
}

QString ImageProcessor::applyPreset(
    const QString &inputPath,
    const QString &presetName
    )
{
    QString current = inputPath;

    if (presetName == "Warm Cinematic") {
        current = applyFilterAdvanced(current, "Sunlight", 1.15, 0, 0, 0, 0);
        current = applyFilterAdvanced(current, "Brightness", 1.07, 0, 0, 0, 0);
        return current;
    }

    if (presetName == "Vintage TV") {
        current = applyFilterAdvanced(current, "TV Effect", 0.85, 0, 0, 0, 0);
        current = applyFilterAdvanced(current, "Sunlight", 0.45, 0, 0, 0, 0);
        return current;
    }

    if (presetName == "Soft Purple") {
        current = applyFilterAdvanced(current, "Purple Tone", 0.75, 0, 0, 0, 0);
        current = applyFilterAdvanced(current, "Brightness", 1.03, 0, 0, 0, 0);
        return current;
    }

    if (presetName == "High Contrast B&W") {
        current = applyFilterAdvanced(current, "Black & White", 1.0, 0, 0, 0, 0);
        current = applyFilterAdvanced(current, "Brightness", 1.05, 0, 0, 0, 0);
        return current;
    }

    return applyFilterAdvanced(current, "Brightness", 1.0, 0, 0, 0, 0);
}
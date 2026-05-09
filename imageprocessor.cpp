#include "imageprocessor.h"

#include <QUrl>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QDateTime>
#include <QStandardPaths>
#include <QFile>

#include <algorithm>
#include <stdexcept>
#include <cmath>
#include <cstdlib>

#include "libs/Image_Class.h"

ImageProcessor::ImageProcessor(QObject *parent)
    : QObject(parent)
{
    std::srand(static_cast<unsigned int>(QDateTime::currentMSecsSinceEpoch() % 1000000));
}

static unsigned char clampColor(int value)
{
    return static_cast<unsigned char>(std::max(0, std::min(255, value)));
}

static QString toLocalPath(const QString &path)
{
    QString localPath = QUrl(path).toLocalFile();

    if (localPath.isEmpty()) {
        localPath = path;
    }

    return localPath;
}

static QString makeSafeFilterName(const QString &suffix)
{
    QString safeSuffix = suffix;
    safeSuffix.replace(" ", "_");
    safeSuffix.replace("&", "and");
    safeSuffix.replace("/", "_");
    safeSuffix.replace("\\", "_");
    safeSuffix.replace(":", "_");
    return safeSuffix;
}

static QString findStableOutputDir(const QString &inputPath)
{
    Q_UNUSED(inputPath);

    QString tempRoot = QStandardPaths::writableLocation(QStandardPaths::TempLocation);

    if (tempRoot.isEmpty()) {
        tempRoot = QDir::tempPath();
    }

    QDir dir(tempRoot);
    QString outputDir = dir.absoluteFilePath("Pixora_Temp");

    QDir tempDir;
    tempDir.mkpath(outputDir);

    return outputDir;
}

static QString makeOutputPath(const QString &inputPath, const QString &suffix)
{
    QString outputDir = findStableOutputDir(inputPath);
    QString safeSuffix = makeSafeFilterName(suffix);

    QString fileName =
        "preview_" +
        QString::number(QDateTime::currentMSecsSinceEpoch()) +
        "_" +
        safeSuffix +
        ".png";

    QDir dir(outputDir);
    return dir.absoluteFilePath(fileName);
}

static void applyGrayscale(Image &img)
{
    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            int avg = (img(x, y, 0) + img(x, y, 1) + img(x, y, 2)) / 3;

            img(x, y, 0) = clampColor(avg);
            img(x, y, 1) = clampColor(avg);
            img(x, y, 2) = clampColor(avg);
        }
    }
}

static void applyBlackAndWhite(Image &img)
{
    int threshold = 128;

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            int gray = (img(x, y, 0) + img(x, y, 1) + img(x, y, 2)) / 3;
            int value = gray >= threshold ? 255 : 0;

            img(x, y, 0) = value;
            img(x, y, 1) = value;
            img(x, y, 2) = value;
        }
    }
}

static void applyInvert(Image &img)
{
    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            img(x, y, 0) = clampColor(255 - img(x, y, 0));
            img(x, y, 1) = clampColor(255 - img(x, y, 1));
            img(x, y, 2) = clampColor(255 - img(x, y, 2));
        }
    }
}

static void applyHorizontalFlip(Image &img)
{
    for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width / 2; x++) {
            for (int c = 0; c < 3; c++) {
                unsigned char temp = img(x, y, c);
                img(x, y, c) = img(img.width - 1 - x, y, c);
                img(img.width - 1 - x, y, c) = temp;
            }
        }
    }
}

static void applyVerticalFlip(Image &img)
{
    for (int y = 0; y < img.height / 2; y++) {
        for (int x = 0; x < img.width; x++) {
            for (int c = 0; c < 3; c++) {
                unsigned char temp = img(x, y, c);
                img(x, y, c) = img(x, img.height - 1 - y, c);
                img(x, img.height - 1 - y, c) = temp;
            }
        }
    }
}

static void applyFrame(Image &img, int thickness, int r, int g, int b)
{
    thickness = std::max(2, std::min(thickness, std::min(img.width, img.height) / 4));

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            if (x < thickness || x >= img.width - thickness ||
                y < thickness || y >= img.height - thickness) {

                img(x, y, 0) = clampColor(r);
                img(x, y, 1) = clampColor(g);
                img(x, y, 2) = clampColor(b);
            }
        }
    }
}

static void applyEdges(Image &img)
{
    applyGrayscale(img);

    Image result(img.width, img.height);

    for (int x = 0; x < result.width; x++) {
        for (int y = 0; y < result.height; y++) {
            result(x, y, 0) = 255;
            result(x, y, 1) = 255;
            result(x, y, 2) = 255;
        }
    }

    const int threshold = 65;

    for (int x = 1; x < img.width - 1; x++) {
        for (int y = 1; y < img.height - 1; y++) {
            int g00 = img(x - 1, y - 1, 0);
            int g01 = img(x - 1, y, 0);
            int g02 = img(x - 1, y + 1, 0);
            int g10 = img(x, y - 1, 0);
            int g12 = img(x, y + 1, 0);
            int g20 = img(x + 1, y - 1, 0);
            int g21 = img(x + 1, y, 0);
            int g22 = img(x + 1, y + 1, 0);

            int sx = (g00) + (-g02) + (2 * g10) + (-2 * g12) + (g20) + (-g22);
            int sy = (g00) + (2 * g01) + (g02) + (-g20) + (-2 * g21) + (-g22);

            int magnitude = static_cast<int>(std::sqrt(sx * sx + sy * sy));

            // Sketch-style edge detection:
            // strong edges = black, background = white.
            int value = magnitude > threshold ? 0 : 255;

            result(x, y, 0) = clampColor(value);
            result(x, y, 1) = clampColor(value);
            result(x, y, 2) = clampColor(value);
        }
    }

    img = result;
}

static void applyRotate(Image &img, int angle)
{
    Image result;

    if (angle == 90 || angle == 270) {
        result = Image(img.height, img.width);
    }
    else if (angle == 180) {
        result = Image(img.width, img.height);
    }
    else {
        return;
    }

    if (angle == 90) {
        for (int x = 0; x < img.width; x++) {
            for (int y = 0; y < img.height; y++) {
                for (int c = 0; c < 3; c++) {
                    result(img.height - 1 - y, x, c) = img(x, y, c);
                }
            }
        }
    }
    else if (angle == 180) {
        for (int x = 0; x < img.width; x++) {
            for (int y = 0; y < img.height; y++) {
                for (int c = 0; c < 3; c++) {
                    result(img.width - 1 - x, img.height - 1 - y, c) = img(x, y, c);
                }
            }
        }
    }
    else if (angle == 270) {
        for (int x = 0; x < img.width; x++) {
            for (int y = 0; y < img.height; y++) {
                for (int c = 0; c < 3; c++) {
                    result(y, img.width - 1 - x, c) = img(x, y, c);
                }
            }
        }
    }

    img = result;
}

static void applyBrightness(Image &img, double strength)
{
    strength = std::max(0.2, std::min(2.0, strength));

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            for (int c = 0; c < 3; c++) {
                img(x, y, c) = clampColor(static_cast<int>(img(x, y, c) * strength));
            }
        }
    }
}

static void applyBlur(Image &img, int radius)
{
    radius = std::max(1, std::min(8, radius));

    if (img.width < radius * 2 + 1 || img.height < radius * 2 + 1) {
        return;
    }

    Image source = img;

    for (int x = radius; x < img.width - radius; x++) {
        for (int y = radius; y < img.height - radius; y++) {
            for (int c = 0; c < 3; c++) {
                int sum = 0;
                int count = 0;

                for (int dx = -radius; dx <= radius; dx++) {
                    for (int dy = -radius; dy <= radius; dy++) {
                        sum += source(x + dx, y + dy, c);
                        count++;
                    }
                }

                img(x, y, c) = clampColor(sum / count);
            }
        }
    }
}

static void applyPurpleFilter(Image &img, double strength)
{
    strength = std::max(0.2, std::min(2.0, strength));

    int addR = static_cast<int>(35 * strength);
    int addB = static_cast<int>(55 * strength);
    int subG = static_cast<int>(18 * strength);

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            int r = img(x, y, 0);
            int g = img(x, y, 1);
            int b = img(x, y, 2);

            img(x, y, 0) = clampColor(r + addR);
            img(x, y, 1) = clampColor(g - subG);
            img(x, y, 2) = clampColor(b + addB);
        }
    }
}

static void applySunlight(Image &img, double strength)
{
    strength = std::max(0.2, std::min(2.0, strength));

    int addR = static_cast<int>(35 * strength);
    int addG = static_cast<int>(22 * strength);
    int addB = static_cast<int>(4 * strength);

    for (int x = 0; x < img.width; x++) {
        for (int y = 0; y < img.height; y++) {
            int r = img(x, y, 0);
            int g = img(x, y, 1);
            int b = img(x, y, 2);

            img(x, y, 0) = clampColor(r + addR);
            img(x, y, 1) = clampColor(g + addG);
            img(x, y, 2) = clampColor(b + addB);
        }
    }
}

static void applyTVFilter(Image &img, double strength)
{
    strength = std::max(0.2, std::min(2.0, strength));

    int noiseRange = std::max(6, static_cast<int>(20 * strength));

    for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
            for (int c = 0; c < 3; c++) {
                int value = img(x, y, c);

                if (y % 5 == 0) {
                    value = static_cast<int>(value * 0.82);
                }

                int noise = (std::rand() % noiseRange) - noiseRange / 2;
                value += noise;

                img(x, y, c) = clampColor(value);
            }
        }
    }
}

static void applyCrop(Image &img, int startX, int startY, int cropWidth, int cropHeight)
{
    startX = std::max(0, std::min(startX, img.width - 1));
    startY = std::max(0, std::min(startY, img.height - 1));

    cropWidth = std::max(1, cropWidth);
    cropHeight = std::max(1, cropHeight);

    if (startX + cropWidth > img.width) {
        cropWidth = img.width - startX;
    }

    if (startY + cropHeight > img.height) {
        cropHeight = img.height - startY;
    }

    Image result(cropWidth, cropHeight);

    for (int x = 0; x < cropWidth; x++) {
        for (int y = 0; y < cropHeight; y++) {
            for (int c = 0; c < 3; c++) {
                result(x, y, c) = img(startX + x, startY + y, c);
            }
        }
    }

    img = result;
}

static unsigned char bilinearChannel(const Image &img, double srcX, double srcY, int c)
{
    int x1 = static_cast<int>(std::floor(srcX));
    int y1 = static_cast<int>(std::floor(srcY));

    int x2 = std::min(x1 + 1, img.width - 1);
    int y2 = std::min(y1 + 1, img.height - 1);

    x1 = std::max(0, std::min(x1, img.width - 1));
    y1 = std::max(0, std::min(y1, img.height - 1));

    double dx = srcX - x1;
    double dy = srcY - y1;

    double p11 = img(x1, y1, c);
    double p21 = img(x2, y1, c);
    double p12 = img(x1, y2, c);
    double p22 = img(x2, y2, c);

    double top = p11 * (1.0 - dx) + p21 * dx;
    double bottom = p12 * (1.0 - dx) + p22 * dx;
    double value = top * (1.0 - dy) + bottom * dy;

    return clampColor(static_cast<int>(std::round(value)));
}

static void applyResize(Image &img, int newWidth, int newHeight)
{
    newWidth = std::max(1, newWidth);
    newHeight = std::max(1, newHeight);

    Image result(newWidth, newHeight);

    double scaleX = static_cast<double>(img.width) / static_cast<double>(newWidth);
    double scaleY = static_cast<double>(img.height) / static_cast<double>(newHeight);

    for (int x = 0; x < newWidth; x++) {
        for (int y = 0; y < newHeight; y++) {
            double oldX = (x + 0.5) * scaleX - 0.5;
            double oldY = (y + 0.5) * scaleY - 0.5;

            oldX = std::max(0.0, std::min(oldX, static_cast<double>(img.width - 1)));
            oldY = std::max(0.0, std::min(oldY, static_cast<double>(img.height - 1)));

            for (int c = 0; c < 3; c++) {
                result(x, y, c) = bilinearChannel(img, oldX, oldY, c);
            }
        }
    }

    img = result;
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
    try {
        QString localPath = toLocalPath(inputPath);
        QString outputPath = makeOutputPath(localPath, filterName);

        Image img(localPath.toStdString());

        if (filterName == "Grayscale") {
            applyGrayscale(img);
        }
        else if (filterName == "Black & White") {
            applyBlackAndWhite(img);
        }
        else if (filterName == "Invert") {
            applyInvert(img);
        }
        else if (filterName == "Flip Horizontal") {
            applyHorizontalFlip(img);
        }
        else if (filterName == "Flip Vertical") {
            applyVerticalFlip(img);
        }
        else if (filterName == "Frame") {
            int r = p2;
            int g = p3;
            int b = p4;

            if (r < 0 || r > 255) r = 241;
            if (g < 0 || g > 255) g = 91;
            if (b < 0 || b > 255) b = 255;

            applyFrame(img, static_cast<int>(strength), r, g, b);
        }
        else if (filterName == "Edge Detection") {
            applyEdges(img);
        }
        else if (filterName == "Rotate 90") {
            applyRotate(img, 90);
        }
        else if (filterName == "Rotate 180") {
            applyRotate(img, 180);
        }
        else if (filterName == "Rotate 270") {
            applyRotate(img, 270);
        }
        else if (filterName == "Brightness") {
            applyBrightness(img, strength);
        }
        else if (filterName == "Blur") {
            applyBlur(img, static_cast<int>(strength));
        }
        else if (filterName == "Purple Tone") {
            applyPurpleFilter(img, strength);
        }
        else if (filterName == "Sunlight") {
            applySunlight(img, strength);
        }
        else if (filterName == "TV Effect") {
            applyTVFilter(img, strength);
        }
        else if (filterName == "Crop") {
            applyCrop(img, p1, p2, p3, p4);
        }
        else if (filterName == "Resize") {
            applyResize(img, p1, p2);
        }

        bool saved = img.saveImage(outputPath.toStdString());

        if (!saved) {
            qDebug() << "Failed to create preview image:" << outputPath;
            return inputPath;
        }

        qDebug() << "Temporary preview saved:" << outputPath;

        return QUrl::fromLocalFile(outputPath).toString();
    }
    catch (const std::exception &error) {
        qDebug() << "applyFilterAdvanced error:" << error.what();
        return inputPath;
    }
}

QString ImageProcessor::mergeImages(const QString &baseImagePath, const QString &secondImagePath, double alpha)
{
    try {
        QString basePath = toLocalPath(baseImagePath);
        QString secondPath = toLocalPath(secondImagePath);

        alpha = std::max(0.0, std::min(1.0, alpha));

        QString outputPath = makeOutputPath(basePath, "Merge");

        Image base(basePath.toStdString());
        Image second(secondPath.toStdString());

        Image result(base.width, base.height);

        for (int x = 0; x < base.width; x++) {
            for (int y = 0; y < base.height; y++) {
                int sx = static_cast<int>((static_cast<double>(x) / base.width) * second.width);
                int sy = static_cast<int>((static_cast<double>(y) / base.height) * second.height);

                sx = std::min(std::max(0, sx), second.width - 1);
                sy = std::min(std::max(0, sy), second.height - 1);

                for (int c = 0; c < 3; c++) {
                    int value = static_cast<int>(
                        (1.0 - alpha) * base(x, y, c) +
                        alpha * second(sx, sy, c)
                        );

                    result(x, y, c) = clampColor(value);
                }
            }
        }

        bool saved = result.saveImage(outputPath.toStdString());

        if (!saved) {
            qDebug() << "Failed to create merged preview image:" << outputPath;
            return baseImagePath;
        }

        qDebug() << "Temporary merged preview saved:" << outputPath;

        return QUrl::fromLocalFile(outputPath).toString();
    }
    catch (const std::exception &error) {
        qDebug() << "mergeImages error:" << error.what();
        return baseImagePath;
    }
}

bool ImageProcessor::exportImage(const QString &sourcePath, const QString &destinationPath)
{
    try {
        QString localSourcePath = toLocalPath(sourcePath);
        QString localDestinationPath = toLocalPath(destinationPath);

        if (localSourcePath.isEmpty() || localDestinationPath.isEmpty()) {
            qDebug() << "Export failed: empty path";
            return false;
        }

        Image img(localSourcePath.toStdString());

        bool saved = img.saveImage(localDestinationPath.toStdString());

        if (!saved) {
            qDebug() << "Export failed:" << localDestinationPath;
            return false;
        }

        qDebug() << "Exported image to:" << localDestinationPath;
        return true;
    }
    catch (const std::exception &error) {
        qDebug() << "exportImage error:" << error.what();
        return false;
    }
}

QString ImageProcessor::loadSampleImage(const QString &resourcePath, const QString &outputName)
{
    try {
        QString tempRoot = QStandardPaths::writableLocation(QStandardPaths::TempLocation);

        if (tempRoot.isEmpty()) {
            tempRoot = QDir::tempPath();
        }

        QDir dir(tempRoot);
        QString sampleDir = dir.absoluteFilePath("Pixora_Samples");

        QDir sampleOutputDir;
        sampleOutputDir.mkpath(sampleDir);

        QString safeName = outputName;
        safeName.replace(" ", "_");
        safeName.replace("/", "_");
        safeName.replace("\\", "_");

        QString outputPath = QDir(sampleDir).absoluteFilePath(safeName);

        QFile input(resourcePath);

        if (!input.exists()) {
            qDebug() << "Sample resource not found:" << resourcePath;
            return "";
        }

        if (!input.open(QIODevice::ReadOnly)) {
            qDebug() << "Could not open sample resource:" << resourcePath;
            return "";
        }

        QFile output(outputPath);

        if (!output.open(QIODevice::WriteOnly)) {
            qDebug() << "Could not write sample file:" << outputPath;
            return "";
        }

        output.write(input.readAll());
        output.close();
        input.close();

        return QUrl::fromLocalFile(outputPath).toString();
    }
    catch (const std::exception &error) {
        qDebug() << "loadSampleImage error:" << error.what();
        return "";
    }
}

QString ImageProcessor::applyPreset(const QString &inputPath, const QString &presetName)
{
    try {
        QString localPath = toLocalPath(inputPath);
        QString outputPath = makeOutputPath(localPath, presetName);

        Image img(localPath.toStdString());

        if (presetName == "Warm Cinematic") {
            applySunlight(img, 1.35);
            applyBrightness(img, 1.08);
        }
        else if (presetName == "Vintage TV") {
            applyTVFilter(img, 1.4);
            applyBrightness(img, 0.92);
        }
        else if (presetName == "Soft Purple") {
            applyPurpleFilter(img, 0.85);
            applyBlur(img, 2);
        }
        else if (presetName == "High Contrast B&W") {
            applyBlackAndWhite(img);
        }
        else {
            qDebug() << "Unknown preset:" << presetName;
            return inputPath;
        }

        bool saved = img.saveImage(outputPath.toStdString());

        if (!saved) {
            qDebug() << "Failed to save preset image:" << outputPath;
            return inputPath;
        }

        return QUrl::fromLocalFile(outputPath).toString();
    }
    catch (const std::exception &error) {
        qDebug() << "applyPreset error:" << error.what();
        return inputPath;
    }
}

#include <iostream>
#include <vector>
#include <cstdlib>
#include <cmath>
#include <algorithm>
#include <string>
#include "Image_Class.h"

using namespace std;

Image img;
string currentFilename;
vector<Image> history;
int currentidx = -1;

// To load image from user input
void LI()
{
    cout << "Enter image name with extension: ";
    cin >> currentFilename;

    if (img.loadNewImage(currentFilename))
        cout << "Loading is done" << endl;
    else
        cout << "Failed to load image: " << currentFilename << endl;
}

// To save image in a file
void SI()
{
    cout << "Do you want to save it in a new file? Y/N\n";
    char k;
    cin >> k;

    if (k == 'Y' || k == 'y')
    {
        cout << "Enter the new image name with extension: ";
        string filename;
        cin >> filename;
        img.saveImage(filename);
    }
    else
    {
        img.saveImage(currentFilename);
    }

    cout << "Saved Successfully" << endl;
}

// Grayscale Conversion Filter
void GrayScale()
{
    for (int i = 0; i < img.width; i++)
    {
        for (int j = 0; j < img.height; j++)
        {
            int avg = 0;

            for (int k = 0; k < 3; k++)
            {
                avg += img(i, j, k);
            }

            avg /= 3;

            for (int k = 0; k < 3; k++)
            {
                img(i, j, k) = avg;
            }
        }
    }

    cout << "Grayscale filter applied successfully.\n";
}

// Black and White Filter
void BlackAndWhite()
{
    int mid = 128;

    for (int y = 0; y < img.height; y++)
    {
        for (int x = 0; x < img.width; x++)
        {
            int r = img.getPixel(x, y, 0);
            int g = img.getPixel(x, y, 1);
            int b = img.getPixel(x, y, 2);

            int gray = (r + g + b) / 3;
            int value = (gray < mid) ? 0 : 255;

            img.setPixel(x, y, 0, value);
            img.setPixel(x, y, 1, value);
            img.setPixel(x, y, 2, value);
        }
    }

    cout << "Black and White filter applied successfully.\n";
}

// Invert Image Filter
void Invert()
{
    for (int i = 0; i < img.width; i++)
    {
        for (int j = 0; j < img.height; j++)
        {
            for (int m = 0; m < 3; m++)
            {
                img(i, j, m) = 255 - img(i, j, m);
            }
        }
    }

    cout << "Invert filter applied successfully.\n";
}

// Merge Images Filter
void Merge()
{
    string image_2;
    cout << "image_2's name ?" << endl;
    cin >> image_2;

    Image img_2(image_2);

    double alpha;
    cout << "choose alpha between 0.0 and 1.0" << endl;
    cin >> alpha;

    if (alpha < 0)
        alpha = 0;
    if (alpha > 1)
        alpha = 1;

    int w = min(img.width, img_2.width);
    int h = min(img.height, img_2.height);

    Image common(w, h);

    for (int i = 0; i < w; i++)
    {
        for (int j = 0; j < h; j++)
        {
            for (int k = 0; k < 3; k++)
            {
                common(i, j, k) = (1 - alpha) * img(i, j, k) + img_2(i, j, k) * alpha;
            }
        }
    }

    img = common;

    cout << "merge with common area done" << endl;
    cout << "merge filter applied successfully.\n";
}

// Flip Image Filter Horizontal
void HorizontalFlip()
{
    for (int y = 0; y < img.height; y++)
    {
        for (int x = 0; x < img.width / 2; x++)
        {
            for (int c = 0; c < 3; c++)
            {
                unsigned char t = img.getPixel(x, y, c);
                img.setPixel(x, y, c, img.getPixel(img.width - x - 1, y, c));
                img.setPixel(img.width - x - 1, y, c, t);
            }
        }
    }

    cout << "Flip filter applied successfully.\n";
}

// Flip Image Filter Vertical
void VerticallFlip()
{
    for (int y = 0; y < img.height / 2; y++)
    {
        for (int x = 0; x < img.width; x++)
        {
            for (int c = 0; c < 3; c++)
            {
                unsigned char t = img.getPixel(x, y, c);
                img.setPixel(x, y, c, img.getPixel(x, img.height - y - 1, c));
                img.setPixel(x, img.height - y - 1, c, t);
            }
        }
    }

    cout << "Flip filter applied successfully.\n";
}

// Adding a Frame to the Picture Filter
void Frame(int thickness, int R, int G, int B)
{
    for (int i = 0; i < img.width; i++)
    {
        for (int j = 0; j < img.height; j++)
        {
            if (i <= thickness || i >= img.width - thickness || j <= thickness || j >= img.height - thickness)
            {
                img(i, j, 0) = R;
                img(i, j, 1) = G;
                img(i, j, 2) = B;
            }
        }
    }

    cout << "Frame filter applied successfully.\n";
}

// Detect Edges Filter
void Edges()
{
    GrayScale();

    Image FinalImg(img.width, img.height);

    for (int i = 1; i < img.width - 1; i++)
    {
        for (int j = 1; j < img.height - 1; j++)
        {
            int g00 = img(i - 1, j - 1, 0);
            int g01 = img(i - 1, j, 0);
            int g02 = img(i - 1, j + 1, 0);
            int g10 = img(i, j - 1, 0);
            int g12 = img(i, j + 1, 0);
            int g20 = img(i + 1, j - 1, 0);
            int g21 = img(i + 1, j, 0);
            int g22 = img(i + 1, j + 1, 0);

            int x = (g00) + (-g02) + (2 * g10) + (-2 * g12) + (g20) + (-g22);
            int y = (g00) + (2 * g01) + (g02) + (-g20) + (-2 * g21) + (-g22);

            int mag = sqrt((x * x) + (y * y));

            if (mag > 100)
                mag = 255;
            else
                mag = 0;

            mag = 255 - mag;

            for (int k = 0; k < 3; k++)
                FinalImg(i, j, k) = mag;
        }
    }

    img = FinalImg;

    cout << "filter done successfully.\n";
}

// Resize Filter
void Resize()
{
    cout << "Choose resize mode:\n";
    cout << "1. Enter new dimensions\n";
    cout << "2. Enter scale ratio\n";

    int mode;
    int W, H;
    cin >> mode;

    if (mode == 1)
    {
        cout << "Enter new dimensions (Width, Height): ";
        cin >> W >> H;
    }
    else if (mode == 2)
    {
        double ratio;
        cout << "Enter scale ratio: ";
        cin >> ratio;

        W = img.width * ratio;
        H = img.height * ratio;
    }
    else
    {
        cout << "Invalid choice\n";
        return;
    }

    if (W <= 0 || H <= 0)
    {
        cout << "Invalid dimensions\n";
        return;
    }

    Image resized(W, H);
    resized.channels = img.channels;

    double widthRatio = (double)img.width / W;
    double heightRatio = (double)img.height / H;

    for (int i = 0; i < W; i++)
    {
        for (int j = 0; j < H; j++)
        {
            int oldi = i * widthRatio;
            int oldj = j * heightRatio;

            for (int c = 0; c < img.channels; ++c)
            {
                resized(i, j, c) = img(oldi, oldj, c);
            }
        }
    }

    img = resized;

    cout << "Resize filter applied successfully.\n";
}

// Rotate Filter
void Rotate(int angle)
{
    Image img2;

    if (angle == 90 || angle == 270)
        img2 = Image(img.height, img.width);
    else if (angle == 180)
        img2 = Image(img.width, img.height);
    else
    {
        cout << "Invalid angle!" << endl;
        return;
    }

    if (angle == 90)
    {
        for (int i = 0; i < img.width; i++)
        {
            for (int j = 0; j < img.height; j++)
            {
                for (int k = 0; k < 3; k++)
                {
                    img2(img.height - 1 - j, i, k) = img(i, j, k);
                }
            }
        }
    }
    else if (angle == 180)
    {
        for (int i = 0; i < img.width; i++)
        {
            for (int j = 0; j < img.height; j++)
            {
                for (int k = 0; k < 3; k++)
                {
                    img2(img.width - 1 - i, img.height - 1 - j, k) = img(i, j, k);
                }
            }
        }
    }
    else if (angle == 270)
    {
        for (int i = 0; i < img.width; i++)
        {
            for (int j = 0; j < img.height; j++)
            {
                for (int k = 0; k < 3; k++)
                {
                    img2(j, img.width - 1 - i, k) = img(i, j, k);
                }
            }
        }
    }

    img = img2;

    cout << "Rotation applied successfully.\n";
}

// Brightness Filter
void Brightness()
{
    double brightness;

    cout << "Enter brightness from 0.0 to 2.0\n";
    cout << "(1.0 = original, <1 darker, >1 lighter)\n";
    cin >> brightness;

    if (brightness > 2.0)
        brightness = 2.0;

    if (brightness < 0.0)
        brightness = 0.0;

    Image Final_img(img.width, img.height);

    for (int i = 0; i < img.width; ++i)
    {
        for (int j = 0; j < img.height; ++j)
        {
            for (int k = 0; k < 3; ++k)
            {
                double NewImg = (double)img(i, j, k) * brightness;

                if (NewImg > 255.0)
                    NewImg = 255.0;

                if (NewImg < 0.0)
                    NewImg = 0.0;

                Final_img(i, j, k) = NewImg;
            }
        }
    }

    img = Final_img;

    cout << "Brightness filter applied successfully.\n";
}

// Crop Filter
void Crop()
{
    int x1, x2, y1, y2;

    cout << "Enter the beginning of the cropped image (x1, y1): \n";
    cin >> x1 >> y1;

    cout << "Enter the end of the cropped image (x2, y2): \n";
    cin >> x2 >> y2;

    if (x1 < 0 || y1 < 0 || x2 > img.width || y2 > img.height || x1 >= x2 || y1 >= y2)
    {
        cout << "Invalid coordinates!\n";
        return;
    }

    int W = x2 - x1;
    int H = y2 - y1;

    Image cropped(W, H);

    for (int y = 0; y < H; y++)
    {
        for (int x = 0; x < W; x++)
        {
            for (int c = 0; c < 3; c++)
            {
                cropped(x, y, c) = img(x + x1, y + y1, c);
            }
        }
    }

    img = cropped;

    cout << "Crop filter applied successfully.\n";
}

// Blur Filter
void blur(int times)
{
    Image img2 = img;

    for (int repeat = 0; repeat < times; repeat++)
    {
        for (int i = 2; i < img.width - 2; i++)
        {
            for (int j = 2; j < img.height - 2; j++)
            {
                for (int k = 0; k < img.channels; k++)
                {
                    int sum = 0;

                    for (int c = -2; c <= 2; c++)
                    {
                        for (int w = -2; w <= 2; w++)
                        {
                            sum += img2(i + c, j + w, k);
                        }
                    }

                    img(i, j, k) = sum / 25;
                }
            }
        }

        img2 = img;
    }

    cout << "Blur filter applied successfully.\n";
}

// Sunlight Filter
void Sunlight()
{
    double brightness = 0.83;
    double contrast = 1.1;
    double saturation = 1.18;

    double warmR = 1.52;
    double warmG = 1.38;
    double warmB = 0.94;

    for (int i = 0; i < img.width; i++)
    {
        for (int j = 0; j < img.height; j++)
        {
            double avg = (img(i, j, 0) + img(i, j, 1) + img(i, j, 2)) / 3.0;

            for (int k = 0; k < 3; k++)
            {
                double val = img(i, j, k);

                val = (val - 128.0) * contrast + 128.0;
                val *= brightness;
                val = avg + (val - avg) * saturation;

                if (k == 0)
                    val *= warmR;
                else if (k == 1)
                    val *= warmG;
                else
                    val *= warmB;

                if (val < 0.0)
                    val = 0.0;
                else if (val > 255.0)
                    val = 255.0;

                img(i, j, k) = val;
            }
        }
    }

    cout << "Sunlight filter applied successfully.\n";
}

// TV Filter
void TVFilter()
{
    Image new_img(img.width, img.height);

    for (int i = 0; i < img.height; ++i)
    {
        for (int j = 0; j < img.width; ++j)
        {
            for (int c = 0; c < 3; ++c)
            {
                int px = img(j, i, c);

                if (i % 4 == 0)
                {
                    px = static_cast<int>(px * 0.6);
                }

                int noise = rand() % 30 - 15;
                px += noise;

                if (px < 0)
                    px = 0;

                if (px > 255)
                    px = 255;

                new_img(j, i, c) = static_cast<unsigned char>(px);
            }
        }
    }

    img = new_img;

    cout << "TV filter applied successfully.\n";
}

// Purple Filter
void purpleFilter()
{
    for (int i = 0; i < img.width; i++)
    {
        for (int j = 0; j < img.height; j++)
        {
            img(i, j, 0) = min(255, int(img(i, j, 0) * 1.3));
            img(i, j, 1) = int(img(i, j, 1) * 0.8);
            img(i, j, 2) = min(255, int(img(i, j, 2) * 1.3));
        }
    }

    cout << "Purple filter applied successfully.\n";
}

// Save current state
void State()
{
    if (currentidx < (int)history.size() - 1)
    {
        history.erase(history.begin() + currentidx + 1, history.end());
    }

    history.push_back(img);

    if (history.size() > 10)
    {
        history.erase(history.begin());
    }

    currentidx = history.size() - 1;
}

// Undo
void Undo()
{
    if (currentidx > 0)
    {
        currentidx--;
        img = history[currentidx];
        cout << "Undo done.\n";
    }
    else
    {
        cout << "No more undo available.\n";
    }
}

// Redo
void Redo()
{
    if (currentidx < (int)history.size() - 1)
    {
        currentidx++;
        img = history[currentidx];
        cout << "Redo done.\n";
    }
    else
    {
        cout << "No more redo available.\n";
    }
}

int main()
{
    int choose;
    bool con = true;

    cout << "Hello, please load an Image to start.\n";

    try
    {
        LI();
        State();
    }
    catch (const exception& e)
    {
        cout << "Error: " << e.what() << endl;
        cout << "Please make sure you write the image path correctly, for example: images/arrow.jpg\n";
        return 0;
    }

    while (con)
    {
        cout << "\nChoose a number from the menu\n";
        cout << "1 for load image\n";
        cout << "2 for save image\n";
        cout << "3 for apply Grayscale filter\n";
        cout << "4 for apply Black and White filter\n";
        cout << "5 for apply Invert Image filter\n";
        cout << "6 for apply Merge Images filter\n";
        cout << "7 for apply Flip Image filter\n";
        cout << "8 for apply Frame filter\n";
        cout << "9 for apply Darken and Lighten Image filter\n";
        cout << "10 for apply Crop Images filter\n";
        cout << "11 for apply Rotate Image filter\n";
        cout << "12 for apply Resize Images filter\n";
        cout << "13 for apply Detect Image Edges filter\n";
        cout << "14 for apply Blur Images filter\n";
        cout << "15 for apply Sunlight filter\n";
        cout << "16 for apply Purple Images filter\n";
        cout << "17 for apply TV Images filter\n";
        cout << "18 for Undo\n";
        cout << "19 for Redo\n";
        cout << "20 for exit\n";
        cout << "What is your choice: ";

        cin >> choose;

        try
        {
            switch (choose)
            {
            case 1:
            {
                cout << "Do you want to save the image before leaving? Y/N\n";
                char save;
                cin >> save;

                if (save == 'Y' || save == 'y')
                    SI();

                LI();
                State();
                break;
            }

            case 2:
            {
                SI();
                break;
            }

            case 3:
            {
                GrayScale();
                State();
                break;
            }

            case 4:
            {
                BlackAndWhite();
                State();
                break;
            }

            case 5:
            {
                Invert();
                State();
                break;
            }

            case 6:
            {
                Merge();
                State();
                break;
            }

            case 7:
            {
                cout << "1. Horizontal\n2. Vertical\n";
                int ans;
                cin >> ans;

                if (ans == 1)
                {
                    HorizontalFlip();
                    State();
                }
                else if (ans == 2)
                {
                    VerticallFlip();
                    State();
                }
                else
                {
                    cout << "Invalid number! Flipping is failed\n";
                }

                break;
            }

            case 8:
            {
                int thickness;
                int R, G, B;

                cout << "Enter the thickness of the frame: ";
                cin >> thickness;

                cout << "Enter frame color(R-G-B): ";
                cin >> R >> G >> B;

                Frame(thickness, R, G, B);
                State();
                break;
            }

            case 9:
            {
                Brightness();
                State();
                break;
            }

            case 10:
            {
                Crop();
                State();
                break;
            }

            case 11:
            {
                int angle;

                cout << "Enter rotation angle (90, 180, 270): ";
                cin >> angle;

                Rotate(angle);
                State();
                break;
            }

            case 12:
            {
                Resize();
                State();
                break;
            }

            case 13:
            {
                Edges();
                State();
                break;
            }

            case 14:
            {
                int times;

                cout << "Enter blur strength: ";
                cin >> times;

                blur(times);
                State();
                break;
            }

            case 15:
            {
                Sunlight();
                State();
                break;
            }

            case 16:
            {
                purpleFilter();
                State();
                break;
            }

            case 17:
            {
                TVFilter();
                State();
                break;
            }

            case 18:
            {
                Undo();
                break;
            }

            case 19:
            {
                Redo();
                break;
            }

            case 20:
            {
                cout << "Do you want to save the image before leaving? Y/N\n";
                char save1;
                cin >> save1;

                if (save1 == 'Y' || save1 == 'y')
                    SI();

                con = false;
                break;
            }

            default:
            {
                cout << "Wrong Answer, please focus then try again\n";
                break;
            }
            }
        }
        catch (const exception& e)
        {
            cout << "Error: " << e.what() << endl;
        }
    }

    return 0;
}
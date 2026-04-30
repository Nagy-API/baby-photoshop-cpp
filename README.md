# Baby Photoshop — C++ Image Processing App

Baby Photoshop is a mini Photoshop-style image processing application built with C++.

The project allows users to load an image, apply different image processing filters, and save the edited result. It was developed as an academic team project to practice C++ programming, image manipulation, file handling, and pixel-level processing.

## Features

The application supports 15 image filters:

- Grayscale filter
- Black and white filter
- Invert filter
- Merge two images
- Horizontal and vertical flip
- Add frame
- Edge detection
- Resize image
- Rotate image by 90, 180, or 270 degrees
- Brightness adjustment
- Crop image
- Blur filter
- Sunlight filter
- TV effect filter
- Purple tone filter

## Tech Stack

- C++
- Image processing
- Pixel manipulation
- File handling
- STB image library
- Object-oriented programming basics

## Project Files

- `BabyPhotoshop.cpp` — Main application source code.
- `Image_Class.h` — Image class used for loading, saving, and manipulating images.
- `stb_image.h` — Header library used for image loading.
- `stb_image_write.h` — Header library used for image saving.

## How to Run

1. Clone the repository:

```bash
git clone https://github.com/Nagy-API/baby-photoshop-cpp.git
```

2. Open the project folder:

```bash
cd baby-photoshop-cpp
```

3. Compile the C++ file:

```bash
g++ BabyPhotoshop.cpp -o BabyPhotoshop
```

4. Run the program:

```bash
./BabyPhotoshop
```

On Windows, you can run:

```bash
BabyPhotoshop.exe
```

## Usage

1. Place the image you want to edit in the same folder as the program.
2. Run the program.
3. Enter the image filename with its extension, for example:

```text
image.jpg
```

4. Choose one of the available filters from the menu.
5. Save the edited image with a new filename or overwrite the original image.

## Skills Demonstrated

- C++ programming
- Image processing fundamentals
- Working with RGB pixel values
- Applying mathematical transformations to images
- File input and output
- Menu-based console applications
- Problem solving
- Team collaboration

## Notes

This project was created for academic learning purposes.

The image helper class and STB headers are included to support image loading and saving.

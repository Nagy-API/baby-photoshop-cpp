# Pixora — Academic Qt/C++ Image Processing Studio

Pixora is an academic image processing project built with **C++**, **Qt 6**, and **Qt Quick/QML**.

The project is a mini Photoshop-style desktop application designed to demonstrate core image processing concepts such as pixel manipulation, filtering, geometric transformations, image blending, cropping, resizing, and exporting edited images.

Although Pixora is built as an academic project, it also focuses on clean user experience through a modern cosmic-themed interface, animated intro screen, sample images, presets, history thumbnails, and compare mode.

---

## Project Overview

Pixora allows users to load an image, apply different image processing filters, preview the result, compare the original image with the edited version, and export the final output.

The project combines:

- Academic image processing concepts
- C++ backend logic
- Qt Quick/QML frontend design
- File loading and exporting
- Interactive desktop application workflow

---

## Preview

> Add screenshots or a short demo GIF here.

Suggested screenshots to include:

- Intro screen
- Main interface
- Filter result
- Crop tool
- Compare mode
- Export dialog

Example assets location:

```text
assets/
├── splash_pixora.png
├── ui_reference.png
└── samples/
```

---

## Features

### Image Loading and Exporting

- Load images from local storage.
- Export edited images.
- Supported export formats:
  - PNG
  - JPG
  - BMP
- Unsaved-changes confirmation before closing or opening another image.

---

### Image Processing Filters

Pixora includes multiple filters and transformations:

- Grayscale
- Black & White threshold
- Invert colors
- Brightness adjustment
- Blur
- Purple tone
- Sunlight / warm tone
- TV effect
- Edge detection
- Frame / border
- Flip horizontal
- Flip vertical
- Rotate 90 degrees
- Rotate 180 degrees
- Rotate 270 degrees
- Crop
- Resize
- Merge images

---

### Editing Workflow

- Apply filters step by step.
- Stack multiple edits on the same image.
- Undo edits.
- Redo edits.
- Reset image back to the original.
- View edit history using thumbnails.
- Compare original and edited image using compare mode.

---

### UI and User Experience

- Modern cosmic-themed UI.
- Animated splash screen / intro.
- Filter descriptions in the inspector panel.
- Demo Mode with built-in sample images.
- Presets for quick editing styles.
- Custom frame color picker.
- Keyboard shortcuts:
  - `Ctrl + O` — Open image
  - `Ctrl + S` — Save image
  - `Ctrl + Z` — Undo
  - `Ctrl + Y` — Redo

---

## Presets

Pixora includes ready-made presets:

- Warm Cinematic
- Vintage TV
- Soft Purple
- High Contrast B&W

Each preset applies a predefined image processing style to quickly demonstrate combined filter effects.

---

## Demo Mode

The project includes sample images so users can try the application immediately without searching for external images.

```text
assets/samples/
├── sample_toys.jpg
├── sample_samurai.jpg
└── sample_sunset.jpg
```

---

## Tech Stack

- C++
- Qt 6
- Qt Quick / QML
- CMake
- stb_image
- stb_image_write
- Custom image processing logic

---

## Project Structure

```text
pixora-image-editor/
├── CMakeLists.txt
├── Image_Class.h
├── imageprocessor.cpp
├── imageprocessor.h
├── main.cpp
├── main.qml
├── README.md
├── .gitignore
├── assets/
│   ├── moon_real.jpg
│   ├── rocket_3d.jpg
│   ├── splash_pixora.png
│   ├── ui_reference.png
│   └── samples/
│       ├── sample_toys.jpg
│       ├── sample_samurai.jpg
│       └── sample_sunset.jpg
└── libs/
    ├── Image_Class.h
    ├── stb_image.h
    └── stb_image_write.h
```

---

## How the Project Works

Pixora separates the project into two main parts:

### 1. Frontend — QML

The frontend is built using Qt Quick/QML.

`main.qml` handles:

- Application layout
- Buttons
- Dialogs
- Sliders
- Filter selection
- Inspector panel
- History thumbnails
- Compare mode UI
- Splash screen animation

### 2. Backend — C++

The backend is built using C++.

`imageprocessor.h` exposes image processing functions to QML.

`imageprocessor.cpp` handles:

- Loading images
- Applying filters
- Pixel-level processing
- Image transformations
- Image merging
- Exporting results

### 3. Application Entry Point

`main.cpp` connects the C++ backend with the QML frontend and starts the Qt application.

---

## Academic Purpose

This project was developed as an academic image processing application.

It demonstrates practical understanding of:

- RGB pixel manipulation
- Image filtering
- Thresholding
- Brightness adjustment
- Blurring
- Edge detection
- Image transformation
- Cropping and resizing
- Image blending
- GUI development using Qt
- C++ and QML integration

The goal is not only to build a working image editor, but also to understand how image processing operations work internally.

---

## Build Requirements

Before running the project, make sure you have:

- Qt 6 installed
- Qt Creator
- CMake
- MinGW or another supported C++ compiler

---

## How to Run

1. Clone the repository:

```bash
git clone https://github.com/Nagy-API/baby-photoshop-cpp.git
```

2. Open the project folder in Qt Creator.

3. Select a Qt 6 kit.

4. Configure the CMake project.

5. Build the project.

6. Run the application.

---

## Usage

1. Open Pixora.
2. Choose an image from your device or use Demo Mode.
3. Select a filter from the left panel.
4. Adjust the intensity slider if the selected filter supports it.
5. Click **Apply Filter**.
6. Use history thumbnails to move between edit steps.
7. Use Compare mode to compare the original and edited image.
8. Export the final result as PNG, JPG, or BMP.

---

## Important Notes

- Do not upload the `build/` folder to GitHub.
- Do not upload Qt Creator temporary files such as `.user` files.
- The project should be opened from the root folder that contains `CMakeLists.txt`.
- The assets folder must stay in the project because the UI and demo mode depend on it.

---

## Suggested `.gitignore`

```gitignore
build/
.qtcreator/
*.user
*.autosave
*.tmp
.DS_Store
Thumbs.db
CMakeFiles/
CMakeCache.txt
cmake_install.cmake
Makefile
*.exe
*.obj
*.o
*.dll
```

---

## Future Improvements

Possible improvements for future versions:

- Add QThread for heavy image processing operations.
- Add real-time low-resolution preview while moving sliders.
- Add more filters such as contrast, saturation, sepia, and sharpen.
- Add drag-and-drop image loading.
- Add zoom and pan controls.
- Add before/after split-view export.
- Package the project as a Windows installer.

---

## Learning Outcomes

Through this project, the following skills are practiced:

- Building desktop applications with Qt
- Designing interfaces using QML
- Connecting QML with C++
- Working with image files
- Implementing image filters manually
- Managing project assets
- Structuring a C++ GUI project
- Preparing a project for GitHub and portfolio presentation

---

## Repository Topics

Recommended GitHub topics:

```text
cpp
qt
qml
image-processing
computer-vision
desktop-app
qt-quick
filters
photo-editor
pixel-manipulation
stb-image
academic-project
```

---

## Author

Created by **Pixora's Team** as an academic C++ / Qt image processing project.

---

## License

This project is for academic and learning purposes.

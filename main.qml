import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Window {
    id: root
    width: 1380
    height: 820
    minimumWidth: 1180
    minimumHeight: 720
    visible: true
    visibility: Window.Maximized
    title: "Pixora"
    color: "#090B1F"

    property color bgTop: "#090B1F"
    property color bgMid: "#170F3F"
    property color bgBottom: "#0E1A42"

    property color panelMain: "#141A46"
    property color panelSoft: "#1B2159"
    property color panelDeep: "#0D1437"
    property color panelCard: "#11183F"
    property color panelDark: "#0A1130"

    property color borderMain: "#5A63D8"
    property color borderSoft: "#314089"
    property color accentPink: "#F15BFF"
    property color accentPinkStrong: "#D946EF"
    property color accentCyan: "#6EE7FF"
    property color accentBlue: "#60A5FA"
    property color accentLavender: "#B48CFF"
    property color accentViolet: "#8B5CF6"

    property color textMain: "#F8F7FF"
    property color textSoft: "#D2D3F7"
    property color textMuted: "#9BA0D0"
    property color textDim: "#767CB2"
    property color selectedDarkText: "#24133F"

    property color successColor: "#73F0C4"
    property color warningColor: "#FFD166"
    property color selectedFrameColor: "#F15BFF"
    property color selectedDarkFrameText: "#24133F"

    property string brandHeroSource: "qrc:/assets/splash_pixora.png"
    property string introMoonSource: "qrc:/assets/moon_real.jpg"

    property string selectedImagePath: ""
    property string processedImagePath: ""
    property string mergeImagePath: ""
    property string currentFilter: "Brightness"
    property string statusMessage: "Choose an image to start"

    property string pendingSamplePath: ""
    property string pendingSampleName: ""

    property bool hasUnsavedChanges: false
    property bool closeAfterSaveDecision: false
    property bool openImageAfterSaveDecision: false
    property bool openSampleAfterSaveDecision: false
    property bool cropOverlayVisible: currentFilter === "Crop" && selectedImagePath !== ""
    property bool isProcessing: false
    property bool compareMode: false
    property bool toastVisible: false

    property string toastMessage: ""
    property string exportFormat: "png"

    property double filterStrength: defaultStrengthForFilter(currentFilter)
    property double compareValue: 0.5

    property var history: []
    property int historyIndex: -1

    property var filtersModel: [
        "Grayscale",
        "Black & White",
        "Invert",
        "Merge Images",
        "Flip Horizontal",
        "Flip Vertical",
        "Frame",
        "Edge Detection",
        "Rotate 90",
        "Rotate 180",
        "Rotate 270",
        "Crop",
        "Resize",
        "Brightness",
        "Blur",
        "Purple Tone",
        "Sunlight",
        "TV Effect"
    ]

    property var frameColors: [
        { name: "Pink", color: "#F15BFF" },
        { name: "Cyan", color: "#6EE7FF" },
        { name: "Purple", color: "#8B5CF6" },
        { name: "Orange", color: "#FF9F43" },
        { name: "White", color: "#F8F7FF" },
        { name: "Lime", color: "#73F0C4" }
    ]

    Shortcut { sequence: "Ctrl+O"; onActivated: requestOpenImage() }
    Shortcut { sequence: "Ctrl+S"; onActivated: saveCurrentImage() }
    Shortcut { sequence: "Ctrl+Z"; onActivated: undo() }
    Shortcut { sequence: "Ctrl+Y"; onActivated: redo() }

    onClosing: function(close) {
        if (hasUnsavedChanges) {
            close.accepted = false
            closeAfterSaveDecision = true
            openImageAfterSaveDecision = false
            openSampleAfterSaveDecision = false
            finalUnsavedDialog.open()
        }
    }

    Timer {
        id: applyTimer
        interval: 1
        repeat: false
        onTriggered: performApplyCurrentFilter()
    }

    Timer {
        id: presetTimer
        interval: 1
        repeat: false
        property string presetName: ""

        onTriggered: {
            var result = imageProcessor.applyPreset(activeImagePath(), presetName)

            if (result === "") {
                isProcessing = false
                statusMessage = "Preset failed."
                showToast("Preset failed")
                return
            }

            pushHistory(result)
            isProcessing = false
            statusMessage = "Preset applied: " + presetName
            showToast("Preset applied: " + presetName)
        }
    }

    Timer {
        id: toastTimer
        interval: 2200
        repeat: false
        onTriggered: toastVisible = false
    }

    function activeImagePath() {
        if (historyIndex >= 0 && historyIndex < history.length)
            return history[historyIndex]

        return selectedImagePath
    }

    function defaultStrengthForFilter(filterName) {
        if (filterName === "Brightness") return 1.20
        if (filterName === "Blur") return 5
        if (filterName === "Frame") return 28
        if (filterName === "Purple Tone") return 0.85
        if (filterName === "Sunlight") return 1.0
        if (filterName === "TV Effect") return 0.8
        if (filterName === "Merge Images") return 0.5
        if (filterName === "Black & White") return 1.0
        return 1.0
    }

    function minStrengthForFilter(filterName) {
        if (filterName === "Brightness") return 0.2
        if (filterName === "Blur") return 1
        if (filterName === "Frame") return 2
        if (filterName === "Purple Tone") return 0.2
        if (filterName === "Sunlight") return 0.2
        if (filterName === "TV Effect") return 0.2
        if (filterName === "Merge Images") return 0.0
        if (filterName === "Black & White") return 0.4
        return 1.0
    }

    function maxStrengthForFilter(filterName) {
        if (filterName === "Brightness") return 2.0
        if (filterName === "Blur") return 18
        if (filterName === "Frame") return 90
        if (filterName === "Purple Tone") return 2.0
        if (filterName === "Sunlight") return 2.0
        if (filterName === "TV Effect") return 2.0
        if (filterName === "Merge Images") return 1.0
        if (filterName === "Black & White") return 1.6
        return 1.0
    }

    function stepSizeForFilter(filterName) {
        if (filterName === "Blur") return 1
        if (filterName === "Frame") return 1
        if (filterName === "Merge Images") return 0.05
        return 0.05
    }

    function hasStrengthControl(filterName) {
        return filterName === "Brightness"
            || filterName === "Blur"
            || filterName === "Frame"
            || filterName === "Purple Tone"
            || filterName === "Sunlight"
            || filterName === "TV Effect"
            || filterName === "Merge Images"
            || filterName === "Black & White"
    }

    function displayStrengthValue(filterName, value) {
        if (filterName === "Blur") return Math.round(value).toString()
        if (filterName === "Frame") return Math.round(value).toString() + " px"
        if (filterName === "Merge Images") return Math.round(value * 100).toString() + "%"
        return value.toFixed(2) + "x"
    }

    function filterDescription(filterName) {
        if (filterName === "Grayscale") return "Converts RGB pixels into grayscale intensity."
        if (filterName === "Black & White") return "Pure black/white threshold effect, not soft grayscale."
        if (filterName === "Invert") return "Reverses each RGB channel."
        if (filterName === "Merge Images") return "Blends a second image with the current image."
        if (filterName === "Flip Horizontal") return "Mirrors the image from left to right."
        if (filterName === "Flip Vertical") return "Mirrors the image from top to bottom."
        if (filterName === "Frame") return "Adds a colored border around the image."
        if (filterName === "Edge Detection") return "Detects strong pixel changes using gradient-like logic."
        if (filterName === "Rotate 90") return "Rotates the image clockwise by 90 degrees."
        if (filterName === "Rotate 180") return "Rotates the image by 180 degrees."
        if (filterName === "Rotate 270") return "Rotates the image clockwise by 270 degrees."
        if (filterName === "Crop") return "Cuts a selected rectangular area from the image."
        if (filterName === "Resize") return "Changes the real pixel dimensions of the image."
        if (filterName === "Brightness") return "Makes the image brighter or darker."
        if (filterName === "Blur") return "Softens the image using a blur effect."
        if (filterName === "Purple Tone") return "Adds a purple tint by adjusting RGB channels."
        if (filterName === "Sunlight") return "Warms the image with red and yellow light tones."
        if (filterName === "TV Effect") return "Adds scanlines and noise for a retro screen look."
        return "Select a filter to see its description."
    }

    function parseFieldValue(field, fallbackValue) {
        var value = parseInt(field.text)
        if (isNaN(value) || value < 0)
            return fallbackValue
        return value
    }

    function colorTo255R(c) { return Math.round(c.r * 255) }
    function colorTo255G(c) { return Math.round(c.g * 255) }
    function colorTo255B(c) { return Math.round(c.b * 255) }

    function pushHistory(path) {
        if (path === "" || path === undefined)
            return

        var newHistory = history.slice(0)

        if (historyIndex < newHistory.length - 1)
            newHistory = newHistory.slice(0, historyIndex + 1)

        newHistory.push(path)
        history = newHistory
        historyIndex = history.length - 1
        processedImagePath = path
        hasUnsavedChanges = true
        compareMode = false
    }

    function undo() {
        if (isProcessing)
            return

        if (historyIndex > 0) {
            historyIndex--
            processedImagePath = history[historyIndex]
            statusMessage = "Undo applied."
            hasUnsavedChanges = true
            compareMode = false
            showToast("Undo applied")
        } else if (historyIndex === 0) {
            historyIndex = -1
            processedImagePath = ""
            compareMode = false
            statusMessage = "Back to original image."
            hasUnsavedChanges = false
            showToast("Back to original image")
        }
    }

    function redo() {
        if (isProcessing)
            return

        if (historyIndex < history.length - 1) {
            historyIndex++
            processedImagePath = history[historyIndex]
            statusMessage = "Redo applied."
            hasUnsavedChanges = true
            compareMode = false
            showToast("Redo applied")
        }
    }

    function resetAll() {
        processedImagePath = ""
        history = []
        historyIndex = -1
        hasUnsavedChanges = false
        compareMode = false
        statusMessage = "Returned to original image."
        showToast("Returned to original image")
    }

    function showToast(message) {
        toastMessage = message
        toastVisible = true
        toastTimer.restart()
    }

    function chooseFilter(filterName) {
        if (isProcessing)
            return

        currentFilter = filterName
        filterStrength = defaultStrengthForFilter(filterName)
        compareMode = false
        statusMessage = "Selected filter: " + filterName

        if (filterName === "Merge Images" && mergeImagePath === "")
            mergeDialog.open()

        if (filterName === "Crop")
            Qt.callLater(resetCropBox)
    }

    function requestOpenImage() {
        if (isProcessing)
            return

        if (hasUnsavedChanges) {
            openImageAfterSaveDecision = true
            closeAfterSaveDecision = false
            openSampleAfterSaveDecision = false
            finalUnsavedDialog.open()
        } else {
            imageDialog.open()
        }
    }

    function saveCurrentImage() {
        if (activeImagePath() === "") {
            showToast("Nothing to save yet")
            return
        }

        exportDialog.open()
    }

    function openSaveDialogWithFormat() {
        saveDialog.defaultSuffix = exportFormat
        saveDialog.nameFilters = [
            "Selected format (*." + exportFormat + ")",
            "PNG image (*.png)",
            "JPEG image (*.jpg *.jpeg)",
            "Bitmap image (*.bmp)"
        ]
        saveDialog.open()
    }

    function toggleCompare() {
        if (selectedImagePath === "" || history.length === 0) {
            showToast("Apply at least one edit first")
            return
        }

        compareMode = !compareMode
        statusMessage = compareMode ? "Compare mode enabled." : "Compare mode disabled."
    }

    function loadSampleDirect(resourcePath, outputName) {
        var result = imageProcessor.loadSampleImage(resourcePath, outputName)

        if (result === "") {
            showToast("Failed to load sample image")
            return
        }

        selectedImagePath = result
        processedImagePath = ""
        mergeImagePath = ""
        history = []
        historyIndex = -1
        hasUnsavedChanges = false
        compareMode = false
        statusMessage = "Sample loaded. Choose a filter."
        showToast("Sample loaded")
        Qt.callLater(resetCropBox)
    }

    function loadSample(resourcePath, outputName) {
        if (isProcessing)
            return

        if (hasUnsavedChanges) {
            pendingSamplePath = resourcePath
            pendingSampleName = outputName
            openSampleAfterSaveDecision = true
            openImageAfterSaveDecision = false
            closeAfterSaveDecision = false
            finalUnsavedDialog.open()
            return
        }

        loadSampleDirect(resourcePath, outputName)
    }

    function applyPresetByName(presetName) {
        if (selectedImagePath === "" || isProcessing) {
            showToast("Choose an image first")
            return
        }

        isProcessing = true
        compareMode = false
        statusMessage = "Applying preset: " + presetName + "..."
        presetTimer.presetName = presetName
        presetTimer.restart()
    }

    function applyCurrentFilter() {
        if (selectedImagePath === "") {
            showToast("Choose an image first")
            return
        }

        if (isProcessing)
            return

        isProcessing = true
        compareMode = false
        statusMessage = "Processing " + currentFilter + "..."
        applyTimer.restart()
    }

    function performApplyCurrentFilter() {
        if (currentFilter === "Merge Images") {
            if (mergeImagePath === "") {
                isProcessing = false
                showToast("Choose second image first")
                mergeDialog.open()
                return
            }

            var mergedResult = imageProcessor.mergeImages(activeImagePath(), mergeImagePath, filterStrength)

            if (mergedResult === "") {
                isProcessing = false
                showToast("Merge failed")
                statusMessage = "Merge failed."
                return
            }

            pushHistory(mergedResult)
            isProcessing = false
            statusMessage = "Merge applied successfully."
            showToast("Merge applied successfully")
            return
        }

        var p1 = 0
        var p2 = 0
        var p3 = 0
        var p4 = 0

        if (currentFilter === "Frame") {
            p1 = Math.round(filterStrength)
            p2 = colorTo255R(selectedFrameColor)
            p3 = colorTo255G(selectedFrameColor)
            p4 = colorTo255B(selectedFrameColor)
        }

        if (currentFilter === "Resize") {
            p1 = parseFieldValue(resizeWidthInput, 800)
            p2 = parseFieldValue(resizeHeightInput, 600)
        }

        if (currentFilter === "Crop") {
            p1 = parseFieldValue(cropXInput, 0)
            p2 = parseFieldValue(cropYInput, 0)
            p3 = parseFieldValue(cropWidthInput, 500)
            p4 = parseFieldValue(cropHeightInput, 500)
        }

        var result = imageProcessor.applyFilterAdvanced(
            activeImagePath(),
            currentFilter,
            filterStrength,
            p1,
            p2,
            p3,
            p4
        )

        if (result === "") {
            isProcessing = false
            statusMessage = currentFilter + " failed."
            showToast(currentFilter + " failed")
            return
        }

        pushHistory(result)
        isProcessing = false

        if (currentFilter === "Resize") {
            statusMessage = "Resize applied to " + p1 + " × " + p2
            showToast("Resize applied: " + p1 + " × " + p2)
        } else if (currentFilter === "Crop") {
            statusMessage = "Crop applied successfully."
            showToast("Crop applied successfully")
        } else if (currentFilter === "Frame") {
            statusMessage = "Frame applied successfully."
            showToast("Frame applied successfully")
        } else {
            statusMessage = currentFilter + " applied successfully."
            showToast(currentFilter + " applied successfully")
        }
    }

    function updateCropFieldsFromBox() {
        if (!editedPreview.visible || editedPreview.sourceSize.width <= 0 || editedPreview.sourceSize.height <= 0)
            return

        var paintedW = editedPreview.paintedWidth
        var paintedH = editedPreview.paintedHeight
        var left = (imageStage.width - paintedW) / 2
        var top = (imageStage.height - paintedH) / 2

        var x = Math.max(0, cropBox.x - left)
        var y = Math.max(0, cropBox.y - top)
        var w = Math.min(cropBox.width, paintedW - x)
        var h = Math.min(cropBox.height, paintedH - y)

        var sourceW = editedPreview.sourceSize.width
        var sourceH = editedPreview.sourceSize.height

        cropXInput.text = Math.round((x / paintedW) * sourceW).toString()
        cropYInput.text = Math.round((y / paintedH) * sourceH).toString()
        cropWidthInput.text = Math.round((w / paintedW) * sourceW).toString()
        cropHeightInput.text = Math.round((h / paintedH) * sourceH).toString()
    }

    function resetCropBox() {
        if (!cropOverlayVisible)
            return

        cropBox.width = Math.min(360, imageStage.width * 0.55)
        cropBox.height = Math.min(260, imageStage.height * 0.55)
        cropBox.x = (imageStage.width - cropBox.width) / 2
        cropBox.y = (imageStage.height - cropBox.height) / 2
        updateCropFieldsFromBox()
    }

    component PixoraSlider : Slider {
        id: control
        implicitHeight: 32
        padding: 0

        background: Rectangle {
            x: control.leftPadding
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: control.availableWidth
            height: 9
            radius: 5
            color: "#22194A"
            border.color: "#48307C"
            border.width: 1

            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                radius: 5
                gradient: Gradient {
                    GradientStop { position: 0.0; color: accentViolet }
                    GradientStop { position: 0.5; color: accentPinkStrong }
                    GradientStop { position: 1.0; color: accentCyan }
                }
            }
        }

        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + control.availableHeight / 2 - height / 2
            width: 22
            height: 22
            radius: 11
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#F8E7FF" }
                GradientStop { position: 1.0; color: accentPink }
            }
            border.color: accentCyan
            border.width: 3

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: 4
                color: selectedDarkText
            }
        }
    }

    component VerticalPixoraScrollBar : ScrollBar {
        id: bar
        policy: ScrollBar.AsNeeded
        active: true
        interactive: true
        width: 18
        padding: 2
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        background: Rectangle {
            radius: 9
            color: "#11163A"
            border.color: "#34428A"
            border.width: 1
            opacity: 0.96
        }

        contentItem: Rectangle {
            implicitWidth: 14
            radius: 7
            color: bar.pressed ? accentPinkStrong : "#A855F7"
            border.color: "#F4D8FF"
            border.width: 1
            opacity: bar.size < 1.0 ? 1.0 : 0.0
        }
    }

    component HorizontalPixoraScrollBar : ScrollBar {
        id: bar
        policy: ScrollBar.AsNeeded
        active: true
        interactive: true
        height: 14
        padding: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        background: Rectangle {
            radius: 7
            color: "#11163A"
            border.color: "#34428A"
            border.width: 1
            opacity: 0.96
        }

        contentItem: Rectangle {
            implicitHeight: 10
            radius: 5
            color: bar.pressed ? accentPinkStrong : "#A855F7"
            border.color: "#F4D8FF"
            border.width: 1
            opacity: bar.size < 1.0 ? 1.0 : 0.0
        }
    }

    component PixoraButton : Rectangle {
        property string textValue: ""
        property bool active: false
        property bool enabledButton: true
        signal clicked()

        Layout.preferredWidth: 98
        Layout.preferredHeight: 42
        radius: 14
        opacity: enabledButton ? 1.0 : 0.42

        gradient: Gradient {
            GradientStop { position: 0.0; color: enabledButton ? (active ? "#B35BFF" : "#1A2359") : "#202743" }
            GradientStop { position: 1.0; color: enabledButton ? (active ? "#F15BFF" : "#16204E") : "#202743" }
        }

        border.color: active ? accentPink : "#33407A"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 8

            Rectangle {
                width: 12
                height: 12
                radius: 6
                color: active ? "#F4D8FF" : accentLavender
                opacity: 0.9
            }

            Text {
                text: textValue
                color: active ? selectedDarkText : textMain
                font.pixelSize: 14
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: enabledButton
            cursorShape: enabledButton ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    component PixoraPillButton : Rectangle {
        property string textValue: ""
        property bool active: false
        property bool enabledButton: true
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 40
        radius: 14
        opacity: enabledButton ? 1.0 : 0.45

        gradient: Gradient {
            GradientStop { position: 0.0; color: active ? "#B35BFF" : "#1A2359" }
            GradientStop { position: 1.0; color: active ? "#F15BFF" : "#16204E" }
        }

        border.color: active ? accentPink : "#33407A"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: textValue
            color: active ? selectedDarkText : textMain
            font.pixelSize: 13
            font.bold: true
            width: parent.width - 18
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        MouseArea {
            anchors.fill: parent
            enabled: enabledButton
            cursorShape: enabledButton ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: parent.clicked()
        }
    }

    component SectionCard : Rectangle {
        Layout.fillWidth: true
        radius: 17
        color: Qt.rgba(0.06, 0.08, 0.22, 0.94)
        border.color: "#2C326D"
        border.width: 1
    }

    component InputField : TextField {
        color: textMain
        selectedTextColor: selectedDarkText
        selectionColor: accentPink
        placeholderTextColor: textDim
        font.pixelSize: 13
        background: Rectangle {
            radius: 10
            color: panelDeep
            border.color: borderSoft
            border.width: 1
        }
    }

    component FilterTile : Rectangle {
        property string filterName: ""
        property bool selected: currentFilter === filterName

        Layout.fillWidth: true
        Layout.preferredHeight: 52
        radius: 15
        border.width: 1
        border.color: selected ? accentPink : "#2F356F"

        gradient: Gradient {
            GradientStop { position: 0.0; color: selected ? "#2D1C64" : "#151B49" }
            GradientStop { position: 1.0; color: selected ? "#402075" : "#10163A" }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 10
                color: selected ? Qt.rgba(0.95, 0.35, 1.0, 0.23) : Qt.rgba(0.55, 0.45, 1.0, 0.08)
                border.color: selected ? accentPink : "#3D4383"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: filterName === "Merge Images" ? "⧉"
                         : filterName === "Crop" ? "⌗"
                         : filterName === "Resize" ? "□"
                         : filterName === "Frame" ? "▣"
                         : filterName === "Blur" ? "◌"
                         : filterName === "Brightness" ? "☀"
                         : "✦"
                    color: selected ? "#FFFFFF" : accentCyan
                    font.pixelSize: 15
                }
            }

            Text {
                Layout.fillWidth: true
                text: filterName
                color: textMain
                font.pixelSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                text: "›"
                color: selected ? "#F5D0FF" : accentLavender
                font.pixelSize: 24
                font.bold: true
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !isProcessing
            cursorShape: Qt.PointingHandCursor
            onClicked: chooseFilter(filterName)
        }
    }

    FileDialog {
        id: imageDialog
        title: "Choose an image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]

        onAccepted: {
            selectedImagePath = selectedFile
            processedImagePath = ""
            mergeImagePath = ""
            history = []
            historyIndex = -1
            hasUnsavedChanges = false
            compareMode = false
            statusMessage = "Image loaded. Choose a filter."
            showToast("Image loaded")
            Qt.callLater(resetCropBox)
        }
    }

    FileDialog {
        id: mergeDialog
        title: "Choose a second image for merge"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.bmp)"]

        onAccepted: {
            mergeImagePath = selectedFile
            statusMessage = "Second image selected."
            showToast("Second image selected")
        }
    }

    FileDialog {
        id: saveDialog
        title: "Save edited image"
        fileMode: FileDialog.SaveFile
        defaultSuffix: exportFormat
        nameFilters: ["PNG image (*.png)", "JPEG image (*.jpg *.jpeg)", "Bitmap image (*.bmp)"]

        onAccepted: {
            var saved = imageProcessor.exportImage(activeImagePath(), selectedFile)

            if (saved) {
                hasUnsavedChanges = false
                statusMessage = "Image saved successfully."
                showToast("Image saved successfully")

                if (openImageAfterSaveDecision) {
                    openImageAfterSaveDecision = false
                    imageDialog.open()
                }

                if (openSampleAfterSaveDecision) {
                    openSampleAfterSaveDecision = false
                    loadSampleDirect(pendingSamplePath, pendingSampleName)
                }

                if (closeAfterSaveDecision) {
                    closeAfterSaveDecision = false
                    Qt.quit()
                }
            } else {
                showToast("Save failed")
            }
        }
    }

    ColorDialog {
        id: frameColorDialog
        title: "Choose frame color"
        selectedColor: selectedFrameColor

        onAccepted: {
            selectedFrameColor = selectedColor
            showToast("Frame color selected")
        }
    }

    Dialog {
        id: exportDialog
        modal: true
        standardButtons: Dialog.NoButton
        width: Math.min(680, root.width - 80)
        height: 285
        padding: 0
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        background: Rectangle {
            radius: 26
            color: "#121645"
            border.color: accentPink
            border.width: 1
            clip: true

            Rectangle {
                width: 280
                height: 280
                radius: 140
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -120
                anchors.topMargin: -135
                color: accentPink
                opacity: 0.09
            }

            Rectangle {
                width: 220
                height: 220
                radius: 110
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: -120
                anchors.bottomMargin: -110
                color: accentCyan
                opacity: 0.04
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 18

            Text {
                text: "Export Image"
                color: textMain
                font.pixelSize: 28
                font.bold: true
                Layout.fillWidth: true
            }

            Text {
                text: "Choose the final format, then select where to save your edited image."
                color: textSoft
                font.pixelSize: 15
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                PixoraPillButton {
                    textValue: "PNG"
                    active: exportFormat === "png"
                    Layout.preferredHeight: 48
                    onClicked: exportFormat = "png"
                }

                PixoraPillButton {
                    textValue: "JPG"
                    active: exportFormat === "jpg"
                    Layout.preferredHeight: 48
                    onClicked: exportFormat = "jpg"
                }

                PixoraPillButton {
                    textValue: "BMP"
                    active: exportFormat === "bmp"
                    Layout.preferredHeight: 48
                    onClicked: exportFormat = "bmp"
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                PixoraPillButton {
                    textValue: "Continue"
                    active: true
                    Layout.preferredHeight: 48
                    onClicked: {
                        exportDialog.close()
                        openSaveDialogWithFormat()
                    }
                }

                PixoraPillButton {
                    textValue: "Cancel"
                    Layout.preferredHeight: 48
                    onClicked: exportDialog.close()
                }
            }
        }
    }

    Dialog {
        id: finalUnsavedDialog
        modal: true
        standardButtons: Dialog.NoButton
        width: 640
        height: 240
        padding: 0
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        background: Rectangle {
            radius: 22
            color: panelMain
            border.color: accentPink
            border.width: 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#17184B" }
                GradientStop { position: 1.0; color: "#0B1030" }
            }
        }

        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            Text {
                text: "Unsaved Changes"
                color: textMain
                font.pixelSize: 28
                font.bold: true
            }

            Text {
                Layout.fillWidth: true
                text: openImageAfterSaveDecision
                    ? "Do you want to save the current result before opening a new image?"
                    : (openSampleAfterSaveDecision
                       ? "Do you want to save the current result before loading a sample?"
                       : "Do you want to save the current result before closing Pixora?")
                color: textSoft
                font.pixelSize: 16
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                PixoraPillButton {
                    textValue: "Save"
                    active: true
                    onClicked: {
                        finalUnsavedDialog.close()
                        saveCurrentImage()
                    }
                }

                PixoraPillButton {
                    textValue: "Don't Save"
                    onClicked: {
                        hasUnsavedChanges = false
                        finalUnsavedDialog.close()

                        if (openImageAfterSaveDecision) {
                            openImageAfterSaveDecision = false
                            imageDialog.open()
                        }

                        if (openSampleAfterSaveDecision) {
                            openSampleAfterSaveDecision = false
                            loadSampleDirect(pendingSamplePath, pendingSampleName)
                        }

                        if (closeAfterSaveDecision) {
                            closeAfterSaveDecision = false
                            Qt.quit()
                        }
                    }
                }

                PixoraPillButton {
                    textValue: "Cancel"
                    onClicked: {
                        openImageAfterSaveDecision = false
                        openSampleAfterSaveDecision = false
                        closeAfterSaveDecision = false
                        finalUnsavedDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: aboutDialog
        modal: true
        standardButtons: Dialog.NoButton
        width: 760
        height: 430
        padding: 0
        x: (root.width - width) / 2
        y: (root.height - height) / 2

        background: Rectangle {
            radius: 24
            color: panelMain
            border.color: accentPink
            border.width: 1

            Image {
                anchors.fill: parent
                source: brandHeroSource
                fillMode: Image.PreserveAspectCrop
                opacity: 0.22
            }

            Rectangle {
                anchors.fill: parent
                radius: 24
                color: Qt.rgba(0.04, 0.05, 0.16, 0.78)
            }
        }

        contentItem: Item {
            anchors.fill: parent

            RowLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 24

                Rectangle {
                    Layout.preferredWidth: 285
                    Layout.fillHeight: true
                    radius: 18
                    color: panelDeep
                    border.color: borderSoft
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: 8
                        source: brandHeroSource
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 8
                        radius: 14
                        color: Qt.rgba(0.03, 0.04, 0.15, 0.20)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    Item { Layout.preferredHeight: 8 }

                    Text {
                        text: "Pixora"
                        color: accentPink
                        font.pixelSize: 54
                        font.bold: true
                    }

                    Text {
                        text: "Cosmic Image Processing Studio"
                        color: "#E4D4FF"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: accentPink
                        opacity: 0.45
                    }

                    Text {
                        text: "Version 1.0.0"
                        color: textMain
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Text {
                        text: "Build 2026"
                        color: textSoft
                        font.pixelSize: 14
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Pixora is a cosmic image editing studio built with Qt Quick. It includes filter stacking, crop, resize, merge, compare mode, presets, sample images, export, and history thumbnails."
                        color: textSoft
                        font.pixelSize: 15
                        wrapMode: Text.WordWrap
                        lineHeight: 1.25
                    }

                    Item { Layout.fillHeight: true }

                    PixoraPillButton {
                        Layout.preferredWidth: 170
                        textValue: "Close"
                        active: true
                        onClicked: aboutDialog.close()
                    }
                }
            }

            Text {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 16
                text: "×"
                color: textMain
                font.pixelSize: 30
                font.bold: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: aboutDialog.close()
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent

        gradient: Gradient {
            GradientStop { position: 0.0; color: bgTop }
            GradientStop { position: 0.48; color: bgMid }
            GradientStop { position: 1.0; color: bgBottom }
        }

        Image {
            anchors.fill: parent
            source: "qrc:/assets/ui_reference.png"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.10
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.03, 0.04, 0.12, 0.70)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 26
            radius: 28
            color: Qt.rgba(0.03, 0.04, 0.13, 0.82)
            border.color: Qt.rgba(241 / 255, 91 / 255, 255 / 255, 0.38)
            border.width: 1

            Rectangle {
                anchors.fill: parent
                anchors.margins: 14
                radius: 23
                color: "transparent"
                border.color: Qt.rgba(110 / 255, 231 / 255, 255 / 255, 0.18)
                border.width: 1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 76
                    radius: 18
                    color: Qt.rgba(0.07, 0.09, 0.25, 0.88)
                    border.color: borderSoft
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 198
                            Layout.preferredHeight: 58
                            radius: 16
                            color: "#161A48"
                            border.color: accentPink
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Pixora"
                                    color: textMain
                                    font.pixelSize: 29
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Cosmic Image Processing Studio"
                                    color: "#E7D2FF"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }

                        PixoraButton { textValue: "Open"; enabledButton: !isProcessing; onClicked: requestOpenImage() }
                        PixoraButton { textValue: "Save"; enabledButton: selectedImagePath !== "" && !isProcessing; onClicked: saveCurrentImage() }
                        PixoraButton { textValue: "Undo"; enabledButton: selectedImagePath !== "" && !isProcessing && historyIndex >= 0; onClicked: undo() }
                        PixoraButton { textValue: "Redo"; enabledButton: !isProcessing && historyIndex < history.length - 1; onClicked: redo() }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 42
                            radius: 13
                            color: Qt.rgba(1, 1, 1, 0.045)
                            border.color: "#2F356F"
                            border.width: 1

                            Row {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: "100%"
                                    color: textMain
                                    font.pixelSize: 14
                                    font.bold: true
                                }

                                Text {
                                    text: "▾"
                                    color: accentLavender
                                    font.pixelSize: 13
                                }
                            }
                        }

                        PixoraButton {
                            textValue: compareMode ? "Comparing" : "Compare"
                            active: compareMode
                            enabledButton: selectedImagePath !== "" && history.length > 0 && !isProcessing
                            onClicked: toggleCompare()
                        }

                        PixoraButton { textValue: "Reset"; enabledButton: selectedImagePath !== "" && !isProcessing; onClicked: resetAll() }
                        PixoraButton { textValue: "About"; onClicked: aboutDialog.open() }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 14

                    Rectangle {
                        Layout.preferredWidth: 250
                        Layout.fillHeight: true
                        radius: 18
                        color: Qt.rgba(0.07, 0.09, 0.25, 0.88)
                        border.color: borderSoft
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 12

                            Text {
                                text: "Filters"
                                color: textMain
                                font.pixelSize: 21
                                font.bold: true
                            }

                            ScrollView {
                                id: filtersScroll
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                leftPadding: 26
                                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                                ScrollBar.vertical: VerticalPixoraScrollBar {}

                                ColumnLayout {
                                    width: filtersScroll.availableWidth - 8
                                    spacing: 10

                                    Repeater {
                                        model: filtersModel
                                        delegate: FilterTile { filterName: modelData }
                                    }
                                }
                            }

                            Text {
                                visible: hasStrengthControl(currentFilter)
                                text: "Intensity"
                                color: textSoft
                                font.pixelSize: 12
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: hasStrengthControl(currentFilter)
                                spacing: 10

                                PixoraSlider {
                                    id: intensitySlider
                                    Layout.fillWidth: true
                                    from: minStrengthForFilter(currentFilter)
                                    to: maxStrengthForFilter(currentFilter)
                                    stepSize: stepSizeForFilter(currentFilter)
                                    value: filterStrength

                                    onValueChanged: {
                                        if (Math.abs(filterStrength - value) > 0.0001)
                                            filterStrength = value
                                    }
                                }

                                Text {
                                    text: displayStrengthValue(currentFilter, filterStrength)
                                    color: "#EBD4FF"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                            }

                            PixoraPillButton {
                                textValue: isProcessing ? "Processing..." : "Apply Filter"
                                active: true
                                enabledButton: selectedImagePath !== "" && !isProcessing
                                onClicked: applyCurrentFilter()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: Qt.rgba(0.04, 0.05, 0.16, 0.86)
                        border.color: borderSoft
                        border.width: 1
                        clip: true

                        Item {
                            id: imageStage
                            anchors.fill: parent
                            anchors.margins: 20

                            Rectangle {
                                anchors.fill: parent
                                radius: 18
                                color: "#070B22"
                                border.color: "#20285E"
                                border.width: 1
                            }

                            Image {
                                id: editedPreview
                                anchors.fill: parent
                                anchors.margins: 10
                                source: activeImagePath()
                                fillMode: Image.PreserveAspectFit
                                visible: selectedImagePath !== ""
                                asynchronous: true
                                cache: false

                                onStatusChanged: {
                                    if (status === Image.Ready && currentFilter === "Crop")
                                        Qt.callLater(resetCropBox)
                                }
                            }

                            Item {
                                visible: compareMode && selectedImagePath !== "" && history.length > 0
                                x: 0
                                y: 0
                                width: imageStage.width * compareValue
                                height: imageStage.height
                                clip: true
                                z: 5

                                Image {
                                    anchors.fill: parent
                                    source: selectedImagePath
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    cache: false
                                }
                            }

                            Rectangle {
                                visible: compareMode && selectedImagePath !== "" && history.length > 0
                                width: 3
                                height: imageStage.height
                                x: imageStage.width * compareValue
                                color: accentPink
                                z: 6
                            }

                            Rectangle {
                                id: cropBox
                                visible: cropOverlayVisible && !compareMode
                                x: 130
                                y: 100
                                width: 360
                                height: 260
                                color: "transparent"
                                border.color: accentPink
                                border.width: 3
                                z: 20

                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(0.85, 0.36, 1.0, 0.13)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    drag.target: cropBox
                                    cursorShape: Qt.SizeAllCursor

                                    onPositionChanged: {
                                        cropBox.x = Math.max(0, Math.min(cropBox.x, imageStage.width - cropBox.width))
                                        cropBox.y = Math.max(0, Math.min(cropBox.y, imageStage.height - cropBox.height))
                                        updateCropFieldsFromBox()
                                    }

                                    onReleased: updateCropFieldsFromBox()
                                }

                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 6
                                    color: accentPink
                                    border.color: accentCyan
                                    border.width: 2
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.SizeFDiagCursor

                                        property real startMouseX
                                        property real startMouseY
                                        property real startW
                                        property real startH

                                        onPressed: {
                                            startMouseX = mouse.x
                                            startMouseY = mouse.y
                                            startW = cropBox.width
                                            startH = cropBox.height
                                        }

                                        onPositionChanged: {
                                            cropBox.width = Math.max(60, Math.min(startW + mouse.x - startMouseX, imageStage.width - cropBox.x))
                                            cropBox.height = Math.max(60, Math.min(startH + mouse.y - startMouseY, imageStage.height - cropBox.y))
                                            updateCropFieldsFromBox()
                                        }

                                        onReleased: updateCropFieldsFromBox()
                                    }
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 14
                                visible: selectedImagePath === ""

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Drop your image here"
                                    color: textMain
                                    font.pixelSize: 38
                                    font.bold: true
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Start editing with Pixora samples or your own images"
                                    color: textSoft
                                    font.pixelSize: 15
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 220
                                    height: 52
                                    radius: 16
                                    border.color: "#F2C8FF"
                                    border.width: 1

                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: accentViolet }
                                        GradientStop { position: 1.0; color: accentPink }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Choose Image"
                                        color: selectedDarkText
                                        font.pixelSize: 15
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: requestOpenImage()
                                    }
                                }
                            }

                            Rectangle {
                                visible: compareMode && selectedImagePath !== "" && history.length > 0
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 12
                                height: 58
                                radius: 16
                                color: Qt.rgba(0.05, 0.07, 0.20, 0.90)
                                border.color: accentPink
                                border.width: 1
                                z: 25

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Text {
                                        text: "Original"
                                        color: textSoft
                                        font.pixelSize: 13
                                        font.bold: true
                                    }

                                    PixoraSlider {
                                        id: compareSlider
                                        Layout.fillWidth: true
                                        from: 0.0
                                        to: 1.0
                                        stepSize: 0.01
                                        value: compareValue

                                        onValueChanged: {
                                            if (Math.abs(compareValue - value) > 0.0001)
                                                compareValue = value
                                        }
                                    }

                                    Text {
                                        text: "Edited"
                                        color: textSoft
                                        font.pixelSize: 13
                                        font.bold: true
                                    }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: isProcessing
                                color: Qt.rgba(0, 0, 0, 0.58)
                                z: 40

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    BusyIndicator {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        running: isProcessing
                                        width: 56
                                        height: 56
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "Processing " + currentFilter + "..."
                                        color: textMain
                                        font.pixelSize: 17
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 350
                        Layout.fillHeight: true
                        radius: 18
                        color: Qt.rgba(0.07, 0.09, 0.25, 0.88)
                        border.color: borderSoft
                        border.width: 1

                        ScrollView {
                            id: inspectorScroll
                            anchors.fill: parent
                            anchors.margins: 14
                            clip: true
                            leftPadding: 26
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            ScrollBar.vertical: VerticalPixoraScrollBar {}

                            ColumnLayout {
                                width: inspectorScroll.availableWidth - 8
                                spacing: 14

                                Text {
                                    text: "Inspector"
                                    color: textMain
                                    font.pixelSize: 21
                                    font.bold: true
                                }

                                SectionCard {
                                    Layout.preferredHeight: 142

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        Text {
                                            text: "Current Filter"
                                            color: textSoft
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: currentFilter
                                            color: textMain
                                            font.pixelSize: 25
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: filterDescription(currentFilter)
                                            color: textSoft
                                            font.pixelSize: 12
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                SectionCard {
                                    visible: currentFilter === "Frame"
                                    Layout.preferredHeight: currentFilter === "Frame" ? 146 : 0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 10

                                        Text {
                                            text: "Frame Color"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Repeater {
                                                model: frameColors

                                                delegate: Rectangle {
                                                    Layout.preferredWidth: 28
                                                    Layout.preferredHeight: 28
                                                    radius: 14
                                                    color: modelData.color
                                                    border.width: 2
                                                    border.color: selectedFrameColor.toString().toLowerCase() === modelData.color.toLowerCase()
                                                        ? "#FFFFFF"
                                                        : "transparent"

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: selectedFrameColor = modelData.color
                                                    }
                                                }
                                            }
                                        }

                                        PixoraPillButton {
                                            textValue: "Custom Color"
                                            onClicked: frameColorDialog.open()
                                        }
                                    }
                                }

                                SectionCard {
                                    visible: currentFilter === "Resize"
                                    Layout.preferredHeight: currentFilter === "Resize" ? 185 : 0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 10

                                        Text {
                                            text: "Resize"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "Width"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: resizeWidthInput
                                                    Layout.fillWidth: true
                                                    text: "800"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "Height"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: resizeHeightInput
                                                    Layout.fillWidth: true
                                                    text: "600"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }
                                        }

                                        PixoraPillButton {
                                            textValue: "Reset Size"
                                            onClicked: {
                                                resizeWidthInput.text = "800"
                                                resizeHeightInput.text = "600"
                                            }
                                        }
                                    }
                                }

                                SectionCard {
                                    visible: currentFilter === "Crop"
                                    Layout.preferredHeight: currentFilter === "Crop" ? 262 : 0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 10

                                        Text {
                                            text: "Crop Area"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Move the crop box on the image or type values manually."
                                            color: textSoft
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "X Position"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: cropXInput
                                                    Layout.fillWidth: true
                                                    text: "0"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "Y Position"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: cropYInput
                                                    Layout.fillWidth: true
                                                    text: "0"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "Width"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: cropWidthInput
                                                    Layout.fillWidth: true
                                                    text: "500"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 4

                                                Text { text: "Height"; color: textSoft; font.pixelSize: 11 }

                                                InputField {
                                                    id: cropHeightInput
                                                    Layout.fillWidth: true
                                                    text: "500"
                                                    inputMethodHints: Qt.ImhDigitsOnly
                                                }
                                            }
                                        }

                                        PixoraPillButton {
                                            textValue: "Reset Crop"
                                            onClicked: resetCropBox()
                                        }
                                    }
                                }

                                SectionCard {
                                    visible: currentFilter === "Merge Images"
                                    Layout.preferredHeight: currentFilter === "Merge Images" ? 132 : 0

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        Text {
                                            text: "Merge Setup"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            text: mergeImagePath === "" ? "No second image selected" : "Second image ready"
                                            color: mergeImagePath === "" ? textSoft : successColor
                                            font.pixelSize: 12
                                        }

                                        PixoraPillButton {
                                            textValue: mergeImagePath === "" ? "Choose Second Image" : "Change Second Image"
                                            active: mergeImagePath === ""
                                            onClicked: mergeDialog.open()
                                        }
                                    }
                                }

                                SectionCard {
                                    Layout.preferredHeight: 150

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        Text {
                                            text: "Demo Mode"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            PixoraPillButton {
                                                textValue: "Toys"
                                                onClicked: loadSample(":/assets/samples/sample_toys.jpg", "sample_toys.jpg")
                                            }

                                            PixoraPillButton {
                                                textValue: "Samurai"
                                                onClicked: loadSample(":/assets/samples/sample_samurai.jpg", "sample_samurai.jpg")
                                            }

                                            PixoraPillButton {
                                                textValue: "Sunset"
                                                onClicked: loadSample(":/assets/samples/sample_sunset.jpg", "sample_sunset.jpg")
                                            }
                                        }
                                    }
                                }

                                SectionCard {
                                    Layout.preferredHeight: 190

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        Text {
                                            text: "Presets"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            PixoraPillButton {
                                                textValue: "Warm"
                                                onClicked: applyPresetByName("Warm Cinematic")
                                            }

                                            PixoraPillButton {
                                                textValue: "Vintage TV"
                                                onClicked: applyPresetByName("Vintage TV")
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            PixoraPillButton {
                                                textValue: "Purple"
                                                onClicked: applyPresetByName("Soft Purple")
                                            }

                                            PixoraPillButton {
                                                textValue: "B&W"
                                                onClicked: applyPresetByName("High Contrast B&W")
                                            }
                                        }
                                    }
                                }

                                SectionCard {
                                    Layout.preferredHeight: 165

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        Text {
                                            text: "History"
                                            color: textMain
                                            font.pixelSize: 15
                                            font.bold: true
                                        }

                                        Text {
                                            visible: history.length === 0
                                            text: "No edits yet."
                                            color: textMuted
                                            font.pixelSize: 12
                                        }

                                        Flickable {
                                            id: historyFlick
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            contentWidth: historyRow.width
                                            contentHeight: height
                                            clip: true
                                            visible: history.length > 0
                                            boundsBehavior: Flickable.StopAtBounds

                                            Row {
                                                id: historyRow
                                                spacing: 8

                                                Repeater {
                                                    model: history

                                                    delegate: Rectangle {
                                                        width: 82
                                                        height: 62
                                                        radius: 10
                                                        color: index === historyIndex ? "#2B2F76" : "#111735"
                                                        border.color: index === historyIndex ? accentPink : "#33407A"
                                                        border.width: 1
                                                        clip: true

                                                        Image {
                                                            anchors.fill: parent
                                                            anchors.margins: 4
                                                            source: modelData
                                                            fillMode: Image.PreserveAspectCrop
                                                            asynchronous: true
                                                            cache: false
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor

                                                            onClicked: {
                                                                historyIndex = index
                                                                processedImagePath = modelData
                                                                compareMode = false
                                                                statusMessage = "Moved to history step " + (index + 1)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            ScrollBar.horizontal: HorizontalPixoraScrollBar {}
                                        }
                                    }
                                }

                                SectionCard {
                                    Layout.preferredHeight: 110

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 6

                                        Text {
                                            Layout.fillWidth: true
                                            text: processedImagePath === "" ? "Working on original image" : "Stack mode active"
                                            color: processedImagePath === "" ? textSoft : successColor
                                            font.pixelSize: 13
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: history.length + " edit(s) in history"
                                            color: textMuted
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            text: hasUnsavedChanges ? "Unsaved changes" : "Saved / no changes"
                                            color: hasUnsavedChanges ? warningColor : textSoft
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 10

                        Text {
                            text: selectedImagePath === "" ? "No image loaded" : "Image loaded"
                            color: textSoft
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            color: "#33407A"
                        }

                        Text {
                            Layout.fillWidth: true
                            text: statusMessage
                            color: accentCyan
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Ctrl+O / Ctrl+S / Ctrl+Z / Ctrl+Y"
                            color: textMuted
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        Rectangle {
            visible: toastVisible
            width: Math.min(560, toastText.implicitWidth + 44)
            height: 52
            radius: 18

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#25153F" }
                GradientStop { position: 1.0; color: "#1C245A" }
            }

            border.color: accentPink
            border.width: 1
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 34
            z: 50

            Text {
                id: toastText
                anchors.centerIn: parent
                text: toastMessage
                color: textMain
                font.pixelSize: 14
                font.bold: true
            }
        }

        Rectangle {
            id: splash
            anchors.fill: parent
            z: 999
            opacity: 1
            visible: opacity > 0
            color: "#070019"

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#040010" }
                GradientStop { position: 0.30; color: "#13003A" }
                GradientStop { position: 0.70; color: "#080B2D" }
                GradientStop { position: 1.0; color: "#02020B" }
            }

            Rectangle {
                id: nebulaLeft
                width: root.width * 0.70
                height: root.height * 0.78
                radius: width / 2
                x: -width * 0.22
                y: root.height * 0.10
                color: "#8B5CF6"
                opacity: 0.10
                z: 1
            }

            Rectangle {
                id: nebulaRight
                width: root.width * 0.54
                height: root.height * 0.66
                radius: width / 2
                x: root.width * 0.64
                y: root.height * 0.04
                color: "#6EE7FF"
                opacity: 0.055
                z: 1
            }

            Rectangle {
                id: pinkNebula
                width: root.width * 0.52
                height: root.height * 0.32
                radius: height / 2
                x: root.width * 0.25
                y: root.height * 0.61
                rotation: -16
                color: "#F15BFF"
                opacity: 0.075
                z: 1
            }

            Repeater {
                model: 150

                Rectangle {
                    width: index % 11 === 0 ? 3 : 2
                    height: width
                    radius: width / 2
                    color: index % 6 === 0 ? "#F7D9FF" : (index % 4 === 0 ? "#6EE7FF" : "#FFFFFF")
                    opacity: index % 8 === 0 ? 0.48 : 0.19
                    x: (index * 91) % root.width
                    y: (index * 53) % root.height
                    z: 2

                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: splash.visible
                        NumberAnimation { to: 0.05; duration: 720 + (index % 6) * 120; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: index % 8 === 0 ? 0.48 : 0.19; duration: 720 + (index % 6) * 120; easing.type: Easing.InOutQuad }
                    }
                }
            }

            Item {
                id: orbitSystem
                anchors.centerIn: parent
                width: 760
                height: 760
                opacity: 0
                scale: 0.76
                z: 4

                Rectangle {
                    anchors.centerIn: parent
                    width: 690
                    height: 690
                    radius: 345
                    color: "transparent"
                    border.color: Qt.rgba(168 / 255, 85 / 255, 247 / 255, 0.22)
                    border.width: 2
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 545
                    height: 545
                    radius: 272
                    color: "transparent"
                    border.color: Qt.rgba(241 / 255, 91 / 255, 255 / 255, 0.16)
                    border.width: 2
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 415
                    height: 415
                    radius: 207
                    color: "transparent"
                    border.color: Qt.rgba(110 / 255, 231 / 255, 255 / 255, 0.12)
                    border.width: 2
                }

                Rectangle {
                    id: orbitSpark
                    width: 14
                    height: 14
                    radius: 7
                    x: parent.width / 2 - width / 2
                    y: 11
                    color: accentCyan
                    opacity: 0.75

                    Rectangle {
                        anchors.centerIn: parent
                        width: 40
                        height: 40
                        radius: 20
                        color: accentCyan
                        opacity: 0.14
                    }
                }

                RotationAnimation on rotation {
                    from: 0
                    to: 360
                    duration: 18000
                    loops: Animation.Infinite
                    running: splash.visible
                }
            }

            Rectangle {
                id: centerPlanetGlow
                anchors.centerIn: parent
                width: 510
                height: 510
                radius: 255
                color: "#A78BFA"
                opacity: 0
                scale: 0.72
                z: 5
            }

            Item {
                id: meteorBehind
                width: 560
                height: 120
                opacity: 0
                z: 5
                x: -620
                y: root.height * 0.24
                rotation: 13

                Rectangle {
                    id: meteorTrailOuter
                    anchors.verticalCenter: parent.verticalCenter
                    x: 8
                    width: 400
                    height: 54
                    radius: 27
                    opacity: 0.58
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00FFFFFF" }
                        GradientStop { position: 0.22; color: "#1457D8FF" }
                        GradientStop { position: 0.48; color: "#4DA855F7" }
                        GradientStop { position: 0.75; color: "#95F15BFF" }
                        GradientStop { position: 1.0; color: "#00FFFFFF" }
                    }
                }

                Rectangle {
                    id: meteorTrailMid
                    anchors.verticalCenter: parent.verticalCenter
                    x: 105
                    width: 280
                    height: 24
                    radius: 12
                    opacity: 0.85
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00FFFFFF" }
                        GradientStop { position: 0.35; color: "#8C6EE7FF" }
                        GradientStop { position: 0.70; color: "#D8F15BFF" }
                        GradientStop { position: 1.0; color: "#FFFEE2B8" }
                    }
                }

                Rectangle {
                    id: meteorTrailCore
                    anchors.verticalCenter: parent.verticalCenter
                    x: 175
                    width: 175
                    height: 10
                    radius: 5
                    opacity: 0.95
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00FFFFFF" }
                        GradientStop { position: 0.55; color: "#D1F3D8FF" }
                        GradientStop { position: 1.0; color: "#FFFFFFFF" }
                    }
                }

                Repeater {
                    model: 4
                    delegate: Rectangle {
                        width: 10 - index
                        height: width
                        radius: width / 2
                        x: 250 - index * 36
                        y: parent.height / 2 - height / 2 + (index % 2 === 0 ? -8 : 8)
                        color: index % 2 === 0 ? "#FFD7FA" : "#C3F4FF"
                        opacity: 0.45 - index * 0.08
                    }
                }

                Rectangle {
                    id: meteorHeadGlow
                    x: 365
                    y: parent.height / 2 - 34
                    width: 82
                    height: 82
                    radius: 41
                    color: "#FFD8A3"
                    opacity: 0.22
                }

                Rectangle {
                    id: meteorHeadFire
                    x: 388
                    y: parent.height / 2 - 25
                    width: 48
                    height: 48
                    radius: 24
                    color: "#FFB347"
                    opacity: 0.95
                }

                Rectangle {
                    id: meteorBody
                    x: 402
                    y: parent.height / 2 - 17
                    width: 56
                    height: 34
                    radius: 17
                    rotation: -18
                    color: "#FFF3E0"
                    border.color: "#FFD6A5"
                    border.width: 1
                }

                Rectangle {
                    x: 416
                    y: parent.height / 2 - 7
                    width: 16
                    height: 16
                    radius: 8
                    color: "#C97B39"
                    opacity: 0.42
                }
            }

            Item {
                id: centerPlanet
                anchors.centerIn: parent
                width: 410
                height: 410
                opacity: 0
                scale: 0.70
                z: 6

                Rectangle {
                    id: moonBase
                    anchors.fill: parent
                    radius: width / 2
                    clip: true

                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#F2F0F9" }
                        GradientStop { position: 0.35; color: "#DDD9E8" }
                        GradientStop { position: 0.70; color: "#B8B1C8" }
                        GradientStop { position: 1.0; color: "#8E879F" }
                    }

                    border.color: Qt.rgba(1, 1, 1, 0.14)
                    border.width: 1

                    Rectangle {
                        x: -20
                        y: -20
                        width: 260
                        height: 260
                        radius: 130
                        color: "#FFFFFF"
                        opacity: 0.14
                    }

                    Rectangle {
                        x: 215
                        y: 170
                        width: 280
                        height: 280
                        radius: 140
                        color: "#544E63"
                        opacity: 0.20
                    }

                    Rectangle {
                        x: 72
                        y: 66
                        width: 86
                        height: 66
                        radius: 33
                        color: "#B8B1C7"
                        opacity: 0.55
                        border.color: "#9B93AC"
                        border.width: 1
                    }

                    Rectangle {
                        x: 85
                        y: 79
                        width: 40
                        height: 30
                        radius: 15
                        color: "#9A92AA"
                        opacity: 0.34
                    }

                    Rectangle {
                        x: 186
                        y: 90
                        width: 72
                        height: 56
                        radius: 28
                        color: "#B7B0C7"
                        opacity: 0.48
                        border.color: "#9C95AD"
                        border.width: 1
                    }

                    Rectangle {
                        x: 199
                        y: 102
                        width: 30
                        height: 24
                        radius: 12
                        color: "#968FA6"
                        opacity: 0.30
                    }

                    Rectangle {
                        x: 268
                        y: 152
                        width: 92
                        height: 72
                        radius: 36
                        color: "#B0A9C0"
                        opacity: 0.46
                        border.color: "#9790A8"
                        border.width: 1
                    }

                    Rectangle {
                        x: 278
                        y: 164
                        width: 38
                        height: 30
                        radius: 15
                        color: "#938BA2"
                        opacity: 0.28
                    }

                    Rectangle {
                        x: 126
                        y: 188
                        width: 78
                        height: 62
                        radius: 31
                        color: "#BDB6CC"
                        opacity: 0.44
                        border.color: "#9A93AB"
                        border.width: 1
                    }

                    Rectangle {
                        x: 240
                        y: 252
                        width: 62
                        height: 48
                        radius: 24
                        color: "#B7B0C6"
                        opacity: 0.40
                        border.color: "#9C94AB"
                        border.width: 1
                    }

                    Rectangle {
                        x: 96
                        y: 274
                        width: 92
                        height: 70
                        radius: 35
                        color: "#B2ABC1"
                        opacity: 0.42
                        border.color: "#9C95AD"
                        border.width: 1
                    }

                    Rectangle {
                        x: 314
                        y: 274
                        width: 42
                        height: 42
                        radius: 21
                        color: "#8C859B"
                        opacity: 0.48
                    }

                    Rectangle {
                        x: 168
                        y: 140
                        width: 132
                        height: 112
                        radius: 56
                        color: "#C8C2D5"
                        opacity: 0.18
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#00FFFFFF" }
                            GradientStop { position: 0.55; color: "#00FFFFFF" }
                            GradientStop { position: 1.0; color: "#3B3A49" }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#2BFFFFFF" }
                            GradientStop { position: 0.25; color: "#12FFFFFF" }
                            GradientStop { position: 1.0; color: "#00000000" }
                        }
                    }
                }
            }

            Rectangle {
                id: diagonalBeam
                width: root.width * 0.72
                height: 72
                radius: 36
                x: -width
                y: root.height * 0.55
                rotation: -18
                opacity: 0
                z: 7

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.00; color: "#00FFFFFF" }
                    GradientStop { position: 0.26; color: "#1D6EE7FF" }
                    GradientStop { position: 0.50; color: "#72F15BFF" }
                    GradientStop { position: 0.78; color: "#2BB48CFF" }
                    GradientStop { position: 1.00; color: "#00FFFFFF" }
                }
            }

            Rectangle {
                id: scanLine
                width: 4
                height: root.height * 0.64
                radius: 2
                x: root.width * 0.18
                y: root.height * 0.18
                opacity: 0
                z: 9

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#006EE7FF" }
                    GradientStop { position: 0.48; color: "#F15BFF" }
                    GradientStop { position: 1.0; color: "#006EE7FF" }
                }
            }

            Item {
                id: logoGroup
                anchors.centerIn: parent
                width: 760
                height: 230
                opacity: 0
                scale: 0.90
                z: 12

                Text {
                    id: logoGlow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    text: "Pixora"
                    color: accentPink
                    opacity: 0.30
                    font.pixelSize: 112
                    font.bold: true
                    scale: 1.06
                }

                Text {
                    id: logoTitle
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    text: "Pixora"
                    color: accentPink
                    font.pixelSize: 112
                    font.bold: true
                }

                Text {
                    id: logoSub
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: logoTitle.bottom
                    anchors.topMargin: 6
                    text: "Cosmic Image Processing Studio"
                    color: "#E7D2FF"
                    font.pixelSize: 27
                    font.bold: true
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: logoSub.bottom
                    anchors.topMargin: 22
                    width: 440
                    height: 2
                    radius: 1
                    opacity: 0.78

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00F15BFF" }
                        GradientStop { position: 0.5; color: "#F15BFF" }
                        GradientStop { position: 1.0; color: "#006EE7FF" }
                    }
                }
            }

            Rectangle {
                id: finalCard
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 58
                width: 440
                height: 58
                radius: 20
                color: Qt.rgba(0.06, 0.07, 0.22, 0.72)
                border.color: Qt.rgba(241 / 255, 91 / 255, 255 / 255, 0.55)
                border.width: 1
                opacity: 0
                scale: 0.92
                z: 13

                Text {
                    anchors.centerIn: parent
                    text: "Create Beyond Limits"
                    color: textMain
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            SequentialAnimation {
                running: true

                PauseAnimation { duration: 320 }

                ParallelAnimation {
                    NumberAnimation { target: orbitSystem; property: "opacity"; from: 0; to: 1; duration: 1100; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: orbitSystem; property: "scale"; from: 0.76; to: 1.0; duration: 1300; easing.type: Easing.OutBack }
                    NumberAnimation { target: centerPlanet; property: "opacity"; from: 0; to: 1; duration: 980; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: centerPlanet; property: "scale"; from: 0.70; to: 1.0; duration: 1280; easing.type: Easing.OutBack }
                    NumberAnimation { target: centerPlanetGlow; property: "opacity"; from: 0; to: 0.18; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: centerPlanetGlow; property: "scale"; from: 0.72; to: 1.08; duration: 1320; easing.type: Easing.OutCubic }
                }

                PauseAnimation { duration: 500 }

                ParallelAnimation {
                    NumberAnimation { target: meteorBehind; property: "opacity"; from: 0; to: 0.96; duration: 260; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: meteorBehind; property: "x"; from: -620; to: root.width + 170; duration: 3600; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: meteorBehind; property: "y"; from: root.height * 0.24; to: root.height * 0.39; duration: 3600; easing.type: Easing.InOutQuad }

                    NumberAnimation { target: diagonalBeam; property: "opacity"; from: 0; to: 0.46; duration: 520; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: diagonalBeam; property: "x"; from: -diagonalBeam.width; to: root.width * 0.15; duration: 2300; easing.type: Easing.InOutCubic }

                    NumberAnimation { target: scanLine; property: "opacity"; from: 0; to: 0.70; duration: 360; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: scanLine; property: "x"; from: root.width * 0.17; to: root.width * 0.80; duration: 2200; easing.type: Easing.InOutCubic }

                    SequentialAnimation {
                        NumberAnimation { target: centerPlanetGlow; property: "opacity"; from: 0.18; to: 0.34; duration: 720; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: centerPlanetGlow; property: "opacity"; from: 0.34; to: 0.22; duration: 1120; easing.type: Easing.InOutQuad }
                    }
                }

                ParallelAnimation {
                    NumberAnimation { target: meteorBehind; property: "opacity"; from: 0.96; to: 0.0; duration: 350; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: diagonalBeam; property: "opacity"; from: 0.46; to: 0.10; duration: 650; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: scanLine; property: "opacity"; from: 0.70; to: 0.0; duration: 620; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: logoGroup; property: "opacity"; from: 0; to: 1; duration: 850; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: logoGroup; property: "scale"; from: 0.90; to: 1.0; duration: 980; easing.type: Easing.OutBack }
                    NumberAnimation { target: logoGroup; property: "y"; from: root.height / 2 - logoGroup.height / 2 + 26; to: root.height / 2 - logoGroup.height / 2; duration: 980; easing.type: Easing.OutCubic }
                }

                PauseAnimation { duration: 350 }

                ParallelAnimation {
                    NumberAnimation { target: finalCard; property: "opacity"; from: 0; to: 1; duration: 760; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: finalCard; property: "scale"; from: 0.92; to: 1.0; duration: 820; easing.type: Easing.OutBack }
                }

                PauseAnimation { duration: 4800 }

                ParallelAnimation {
                    NumberAnimation { target: splash; property: "opacity"; from: 1; to: 0; duration: 1000; easing.type: Easing.InOutQuad }
                    NumberAnimation { target: diagonalBeam; property: "opacity"; from: 0.10; to: 0; duration: 620; easing.type: Easing.InOutQuad }
                }
            }
        }
    }
}

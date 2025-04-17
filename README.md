# Document Scanner POC

A Flutter application that uses the device camera to detect document edges, capture images, and apply perspective correction to create scanned document images.

## Features

- Real-time document edge detection using ML Kit
- Camera preview with document boundary visualization
- Automatic perspective correction for captured documents
- Image saving to device storage
- Provider-based state management
- Responsive UI for all device orientations

## Prerequisites

- Flutter SDK (latest stable version)
- Android Studio/Xcode (for development)
- Physical device with camera (recommended for testing)

## Installation

1. Clone the repository:
   git clone https://github.com/chandrumurugan/Doc_scanner_POC.git
   cd doc-scanner-poc
2. Install dependencies:
   flutter pub get
3. Run the app:
   flutter run


## Architecture

Key Components

CameraProvider:

- Manages camera initialization and lifecycle

- Handles document detection and image processing

- Maintains application state using ChangeNotifier

CameraScreen:

- Main UI component with camera preview

- Displays detected document boundaries

- Handles user interactions

EdgePainter:

- Custom painter for document boundary visualization

- Handles coordinate transformations for different device orientations

Image Processing:

- Perspective correction using bilinear interpolation

- Coordinate conversion between preview and image space

- Image saving to device storage



## State Management
The app uses Provider for state management with the following key states:

- Camera initialization status

- Document detection results

- Image processing status

- Captured image path

## Usage

Launch the app: The camera will initialize automatically

Position document: Hold your document in front of the camera

Detect edges: The app will automatically detect document boundaries (shown in green)

Capture image: Tap the camera button to capture and process the document

View result: The processed document will be displayed

Return to scanner: Tap the refresh button to scan another document

## Technical Details
Document Detection
Uses Google's ML Kit Object Detection

Configured for single document detection

Returns bounding box coordinates of detected document

Image Processing
Coordinate Conversion:

Converts preview coordinates to original image coordinates

Accounts for device orientation and aspect ratio differences

Perspective Correction:

Uses bilinear interpolation to transform the document

Corrects for perspective distortion

Produces a flat, rectangular output image


🧪 Possible Improvements
✏️ Allow manual adjustment of corners

📄 Export scanned image as PDF

🌐 Add multi-language support

☁️ Save to cloud (Firebase, Drive)

🤖 Detect more than one document

📤 Implement sharing via email, WhatsApp, etc.

👨‍💻 Author
Made with ❤️ by chandru murugan
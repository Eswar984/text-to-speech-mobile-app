# Developing a Mobile App for Text-to-Speech Synthesis

A mobile Text-to-Speech (TTS) application that converts written text into spoken audio using **FastSpeech 2** and **HiFi-GAN**. The application uses Flutter for its mobile interface and a Python FastAPI backend for speech generation.

## Project Overview

The objective of this project is to develop a mobile application that allows users to enter text and listen to its spoken output.

The application integrates deep-learning-based speech synthesis with a mobile interface. FastSpeech 2 generates a mel-spectrogram from the input text, and HiFi-GAN converts the mel-spectrogram into an audio waveform.

The generated audio is returned by the backend and played through the Flutter application.

## Main Features

- Enter text for speech synthesis.
- Generate speech using FastSpeech 2 and HiFi-GAN.
- Communicate with the Python backend through an HTTP API.
- Play the generated speech in the mobile application.
- Pause, resume, and stop audio playback.
- Run the speech-generation backend locally.

## System Architecture

```text
          User
           |
           v
    Flutter Mobile App
           |
           | HTTP POST
           v
       FastAPI Backend
           |
           v
       Input Text
           |
           v
       FastSpeech 2
           |
           v
    Mel-Spectrogram
           |
           v
         HiFi-GAN
           |
           v
      Generated WAV
           |
           v
     Flutter Audio Player
           |
           v
       Spoken Output
```

## Technologies Used

| Component | Technology |
|---|---|
| Mobile application | Flutter |
| Programming language | Dart |
| Backend framework | FastAPI |
| Backend language | Python |
| Acoustic model | FastSpeech 2 |
| Vocoder | HiFi-GAN |
| Deep learning framework | PyTorch |
| API server | Uvicorn |
| Development platform | macOS |
| Mobile testing | Android Emulator |

## Project Structure

```text
TextToSpeechProject/
│
├── backend/
│   ├── main.py
│   └── .gitignore
│
├── local_tts/
│   └── inference.py
│
├── mobile_app/
│   ├── lib/
│   │   └── main.dart
│   ├── android/
│   ├── ios/
│   ├── test/
│   ├── pubspec.yaml
│   └── README.md
│
├── .gitignore
└── README.md
```

The model checkpoints and local model dependencies are intentionally excluded from this GitHub repository because of their large file sizes.

## Requirements

Install or configure the following before running the project:

- Python
- Flutter SDK
- Android Studio and an Android Emulator
- Git
- Required Python packages and model dependencies
- FastSpeech 2 and HiFi-GAN model checkpoints

## Model Files

The application uses pretrained FastSpeech 2 and HiFi-GAN checkpoints.

The expected checkpoint locations in the development environment are:

**FastSpeech 2**

```text
local_models/fastspeech2_ljspeech/checkpoint/epoch-0125_step-0097902_loss-1.074404/pytorch_model.bin
```

**HiFi-GAN**

```text
local_models/hifigan_ljspeech/checkpoints/step-0560000_loss-51.2373.pt
```

These model files are not included in the repository. They must be obtained separately and placed in the expected locations before running local inference.

The local Amphion model implementation is also excluded from the repository and must be available in `local_Amphion/`.

## Running the Project

The following commands describe the tested local development setup.

### 1. Start the FastAPI Backend

Open Terminal 1.

Navigate to the project directory:

```bash
cd ~/TextToSpeechProject
```

Activate the Python environment:

```bash
source local_tts_env/bin/activate
```

Start the backend:

```bash
PYTHONPATH="$PWD/local_Amphion" python -m uvicorn main:app --reload --app-dir backend --host 0.0.0.0 --port 8000
```

The backend will be available at:

```text
http://127.0.0.1:8000
```

API documentation:

```text
http://127.0.0.1:8000/docs
```

### 2. Test the Backend

Open the API documentation in a browser:

```text
http://127.0.0.1:8000/docs
```

Locate the `/synthesize` endpoint and use it to test text-to-speech generation.

The backend exposes the speech synthesis endpoint:

```text
POST /synthesize
```

A successful request generates speech audio.

### 3. Run the Flutter Mobile Application

Open Terminal 2.

Navigate to the Flutter application directory:

```bash
cd ~/TextToSpeechProject/mobile_app
```

Get the Flutter dependencies:

```bash
flutter pub get
```

Start an Android Emulator and run:

```bash
flutter run
```

Keep the backend running while using the mobile application.

**Android Emulator API address:**

```text
http://10.0.2.2:8000
```

The Android Emulator uses `10.0.2.2` to access the host computer's localhost.

## Mentor Demonstration Procedure

The following sequence can be used to demonstrate the working application:

1. Open the project in VS Code.
2. Start the Python virtual environment.
3. Run the FastAPI backend.
4. Confirm that the backend is running.
5. Start the Android Emulator.
6. Launch the Flutter mobile application.
7. Enter a sentence in the text input field.
8. Start speech generation.
9. Wait for the backend to generate the audio.
10. Play the generated speech.
11. Demonstrate the pause, resume, and stop controls.

## Testing and Results

The project has been tested using the local FastAPI backend and Flutter Android application.

The following functionality has been successfully demonstrated:

- Backend speech synthesis using FastSpeech 2 and HiFi-GAN.
- Successful API response from the `/synthesize` endpoint.
- Flutter application launch on Android Emulator.
- Text submission from the mobile application.
- Speech generation and audio playback.
- Pause, resume, and stop playback controls.
- Successful speech generation and playback after restarting the application.

## Limitations

- Speech generation requires the local backend to be running.
- Model checkpoints and model implementation dependencies must be installed separately.
- Speech generation performance depends on the host computer's hardware.
- The current repository does not include the large pretrained model files.

## Future Enhancements

- Support for additional languages and voices.
- Improved speech-generation performance.
- Deployment of the backend to a cloud server.
- Improved mobile application interface.
- Additional speech customization options.

## Author

**Eswar K**

B.Tech Final-Year Project

**Project Title:** Developing a Mobile App for Text-to-Speech Synthesis

## GitHub Repository

[https://github.com/Eswar984/text-to-speech-mobile-app](https://github.com/Eswar984/text-to-speech-mobile-app)
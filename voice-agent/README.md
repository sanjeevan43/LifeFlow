# Voice Input System

A production-ready Python application that captures voice input, processes it using Google's Web Speech API (Free), and executes commands effortlessly.

## Prerequisites

- **Python 3.8+**
- **Microphone**: Ensure it is set as the default recording device.
- **Internet Connection**: Required for speech recognition.

## Setup

1.  **Install Dependencies**

    ```bash
    pip install -r requirements.txt
    ```

    *Note for Windows users:* If you encounter issues installing `pyaudio`, you may need to install it with `pipwin`:
    ```bash
    pip install pipwin
    pipwin install pyaudio
    ```

## Usage

Run the assistant:

```bash
python voice_assistant.py
```

### Features & Commands

The assistant listens continuously. You can say:

- **Apps**: "Open Notepad", "Launch VS Code", "Open Whatsapp"
- **Browsing**: "Open youtube.com", "Search for Flutter tutorials"
- **System**: "What is my battery?", "Show task manager"
- **Utilities**: "What is the time?", "Tell me a joke"
- **Exit**: "Stop", "Exit", "Bye"

## Troubleshooting

-   **Microphone Error**: Ensure your microphone is connected and not being used exclusively by another app.
-   **"My connection to the speech service is down"**: Check your internet connection.
-   **Audio Quality**: If recognition is poor, move to a quieter environment.

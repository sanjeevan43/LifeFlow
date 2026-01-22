
import speech_recognition as sr
import pyttsx3
import os
import subprocess
import webbrowser
import threading
import time
import psutil
import pyjokes
import winsound
from datetime import datetime
import customtkinter as ctk


# Configuration for CustomTkinter
ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

import pyautogui

class UltimateVoiceAssistant:
    def __init__(self, on_speech_start=None, on_speech_end=None, on_log=None):
        self.recognizer = sr.Recognizer()
        self.engine = pyttsx3.init()
        self.is_running = False
        self.on_speech_start = on_speech_start
        self.on_speech_end = on_speech_end
        self.on_log = on_log
        
        # Safety for automation
        pyautogui.FAILSAFE = True
        
        self.setup_voice()
        self.command_aliases = self._get_app_aliases()

    # ... [Previous setup_voice, _get_app_aliases, log, speak, play_sound methods remain same] ...

    def listen_once(self):
        with sr.Microphone() as source:
            if self.on_speech_start: self.on_speech_start()
            self.play_sound("start")
            
            try:
                self.recognizer.adjust_for_ambient_noise(source, duration=0.5)
                audio = self.recognizer.listen(source, timeout=5, phrase_time_limit=8)
                
                if self.on_speech_end: self.on_speech_end()
                self.play_sound("stop")
                
                text = self.recognizer.recognize_google(audio)
                self.log(text, "user")
                return text.lower()
            except Exception as e:
                # self.log(f"Error: {e}", "system") 
                return None
            finally:
                 if self.on_speech_end: self.on_speech_end()

    def process_command(self, text):
        if not text: return

        if any(w in text for w in ["exit", "quit", "stop", "shut down", "bye"]):
            self.speak("Goodbye!")
            self.is_running = False
            return

        # --- WAKE WORD / GREETING ---
        if "hello" in text or "hi nanba" in text:
            self.speak("Hello Nanba, I am ready to help you.")
            return

        # --- ADVANCED AUTOMATION ---
        
        # 1. "Call [Person]" -> Open Phone/App, Search, Click Call
        if "call" in text:
            name = text.replace("call", "").strip()
            self.speak(f"Calling {name} on WhatsApp")
            # Automation Sequence
            self.open_app("whatsapp")
            time.sleep(2) # Wait for open
            pyautogui.hotkey('ctrl', 'f') # Search
            time.sleep(0.5)
            pyautogui.write(name)
            time.sleep(1)
            pyautogui.press('enter') # Select chat
            time.sleep(1)
            # Find call button or shortcut (WhatsApp Web/Desktop often ctrl+alt+shift+c or tab nav)
            # For robustness, we'll assume we are in chat and maybe just "voice call"
            # pyautogui.click(x=..., y=...) # Coordinates depend on screen, tricky without visual AI
            self.speak(f"Opened chat for {name}. Please press call button.") 
            return

        # 2. "Message [Person] [Content]"
        if "message" in text or "send" in text:
            # Simple parsing logic
            try:
                if "to" in text:
                    parts = text.split("to", 1)
                    content = parts[0].replace("message", "").replace("send", "").strip()
                    name = parts[1].strip()
                else:
                    name = "Unknown" # Fallback
                    content = text
                
                self.speak(f"Messaging {name}")
                self.open_app("whatsapp")
                time.sleep(2)
                pyautogui.hotkey('ctrl', 'f')
                pyautogui.write(name)
                time.sleep(1)
                pyautogui.press('enter')
                time.sleep(1)
                pyautogui.write(content)
                pyautogui.press('enter')
                self.speak("Message sent.")
            except:
                self.speak("I couldn't send the message.")
            return

        # 3. "Type [Content]" (Dictation mode)
        if "type" in text or "write" in text:
            content = text.replace("type", "").replace("write", "").strip()
            self.speak("Typing...")
            pyautogui.write(content + " ")
            return

        # 4. "Press [Key]"
        if "press enter" in text:
            pyautogui.press('enter')
            return
        
        # ... [Previous Basic Commands] ...
        if "open" in text:
            # Browser check
            if "google.com" in text or "youtube.com" in text:
                for w in text.split():
                    if "." in w and not w.startswith("open"):
                        self.speak(f"Opening {w}")
                        webbrowser.open(f"https://{w}")
                        return
            parts = text.split(' ', 1)
            if len(parts) > 1:
                self.open_app(parts[1])
            return
            
        # Fallback
        # self.speak("I didn't understand.")



class VoiceAgentApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Hi Nanba Voice")
        self.geometry("400x650")
        self.resizable(False, False)
        
        # --- Theme & Colors ---
        # Dark blue-gray background for a 'Midnight' feel
        self.configure(fg_color="#0F172A") 

        # --- Variables ---
        self.is_listening = False
        self.thread = None

        # --- UI Layout ---
        # Main Container
        self.main_frame = ctk.CTkFrame(self, fg_color="transparent")
        self.main_frame.pack(fill="both", expand=True, padx=20, pady=20)

        # Header
        self.header = ctk.CTkLabel(
            self.main_frame, 
            text="Hi Nanba Voice", 
            font=("Outfit", 28, "bold"),
            text_color="#F8FAFC"
        )
        self.header.pack(pady=(10, 5))

        self.status_label = ctk.CTkLabel(
            self.main_frame, 
            text="Offline", 
            font=("Outfit", 16),
            text_color="#94A3B8"
        )
        self.status_label.pack(pady=(0, 20))

        # Chat Area - Sleek dark container
        self.chat_frame = ctk.CTkTextbox(
            self.main_frame, 
            width=360, 
            height=400, 
            state="disabled",
            fg_color="#1E293B",
            text_color="#E2E8F0",
            font=("Roboto", 14),
            corner_radius=15,
            border_width=1,
            border_color="#334155"
        )
        self.chat_frame.pack(pady=10)

        # Control Button - Vibrant Gradient-like Teal
        self.btn_toggle = ctk.CTkButton(
            self.main_frame, 
            text="Start Listening", 
            command=self.toggle_listening,
            width=220,
            height=55,
            font=("Outfit", 18, "bold"),
            fg_color="#0EA5E9", # Sky Blue/Teal
            hover_color="#0284C7",
            corner_radius=25,
            border_width=0
        )
        self.btn_toggle.pack(pady=30)

        # Footer
        self.footer = ctk.CTkLabel(
            self.main_frame, 
            text="Powered by LifeFlow AI", 
            font=("Outfit", 12),
            text_color="#64748B"
        )
        self.footer.pack(side="bottom", pady=0)

        # Initialize Logic
        self.agent = UltimateVoiceAssistant(
            on_speech_start=self.handle_speech_start,
            on_speech_end=self.handle_speech_end,
            on_log=self.append_log
        )

    def append_log(self, text, sender):
        timestamp = datetime.now().strftime("%H:%M")
        
        self.chat_frame.configure(state="normal")
        if sender == "user":
            # Right aligned / different color for user? 
            # Simplified for text box: User is Cyan, Agent is White
            self.chat_frame.insert("end", f"\n[You]: {text}\n")
        else:
            self.chat_frame.insert("end", f"\n[Agent]: {text}\n")
        self.chat_frame.configure(state="disabled")
        self.chat_frame.see("end")

    def handle_speech_start(self):
        self.status_label.configure(text="Listening...", text_color="#38BDF8") # Light Blue
        self.update()

    def handle_speech_end(self):
        self.status_label.configure(text="Processing...", text_color="#FBBF24") # Amber
        self.update()

    def toggle_listening(self):
        if not self.is_listening:
            self.is_listening = True
            self.agent.is_running = True
            
            # Change to Stop state (Rosé / Red-Pink)
            self.btn_toggle.configure(
                text="Stop Listening", 
                fg_color="#F43F5E", 
                hover_color="#E11D48"
            )
            self.status_label.configure(text="Ready", text_color="#4ADE80") # Green
            
            # Start Thread
            self.thread = threading.Thread(target=self.run_loop, daemon=True)
            self.thread.start()
        else:
            self.is_listening = False
            self.agent.is_running = False
            
            # Back to Start state
            self.btn_toggle.configure(
                text="Start Listening", 
                fg_color="#0EA5E9", 
                hover_color="#0284C7"
            )
            self.status_label.configure(text="Stopped", text_color="#94A3B8")

    def run_loop(self):
        self.agent.speak("Hi Nanba, I am Online.")
        while self.is_listening and self.agent.is_running:
            # We call listen_once which blocks for a few seconds
            text = self.agent.listen_once()
            if text:
                self.agent.process_command(text)
            
            # Small sleep to prevent tight loop if recognition fails instantly
            time.sleep(0.5)

if __name__ == "__main__":
    app = VoiceAgentApp()
    app.mainloop()


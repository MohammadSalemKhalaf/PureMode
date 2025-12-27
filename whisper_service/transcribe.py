import sys
import json
import os
import whisper

# تأكد أن ffmpeg في الـ PATH حتى لو ما وصله من Node
FFMPEG_BIN = r"C:\Users\engta\Downloads\ffmpeg-8.0.1-essentials_build\ffmpeg-8.0.1-essentials_build\bin"
os.environ["PATH"] = FFMPEG_BIN + os.pathsep + os.environ.get("PATH", "")
def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "audio path is required"}))
        return

    audio_path = sys.argv[1]

    model = whisper.load_model("small")  # يدعم عربي + إنجليزي
    result = model.transcribe(audio_path, language=None)
    text = (result.get("text") or "").strip()

    # نستخدم ASCII فقط لتجنب مشكلة الترميز في الويندوز
    print(json.dumps({"text": text}, ensure_ascii=True))

if __name__ == "__main__":
    main()
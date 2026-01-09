from fastapi import FastAPI, File, UploadFile
from fastapi.responses import JSONResponse
from deepface import DeepFace
import uvicorn
import tempfile

app = FastAPI()


@app.post("/analyze_image")
async def analyze_image(file: UploadFile = File(...)):
    """استقبال صورة وجه وتحليل تعابير الوجه وإرجاع happy/sad/neutral"""
    try:
        # حفظ مؤقت للصورة على القرص
        suffix = "." + (file.filename.split(".")[-1] if "." in file.filename else "jpg")
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await file.read())
            tmp_path = tmp.name

        # تحليل تعابير الوجه باستخدام DeepFace
        result = DeepFace.analyze(img_path=tmp_path, actions=["emotion"], enforce_detection=False)

        # DeepFace عادة يرجع dict فيه dominant_emotion
        if isinstance(result, list):
            result = result[0]

        emotion = result.get("dominant_emotion", "neutral")

        # تبسيط النتيجة إلى happy / sad / neutral فقط
        if emotion in ["happy"]:
            mood = "happy"
        elif emotion in ["sad", "angry", "fear", "disgust"]:
            mood = "sad"
        else:
            mood = "neutral"

        return JSONResponse({"emotion": mood, "raw_emotion": emotion})

    except Exception as e:
        # في حال أي خطأ، نرجّع neutral حتى لا ينهار النظام
        return JSONResponse({"emotion": "neutral", "error": str(e)}, status_code=200)


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)


# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import posture
from routers import realtime

app = FastAPI(
    title="FitFusion AI Service",
    description="Posture detection and exercise analysis",
    version="1.0.0"
)

# Allow requests from Node backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(
    posture.router,
    prefix="/posture",
    tags=["Posture Detection"]
)

app.include_router(
    realtime.router,
    prefix="/realtime",
    tags=["Real-time Detection"]
)

@app.get("/")
async def root():
    return {"status": "FitFusion AI Service running ✅"}

@app.get("/health")
async def health():
    return {"status": "ok", "service": "fitfusion-ai"}
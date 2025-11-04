from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import platform
import os

app = FastAPI(title="Multi-Arch Backend API")

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Welcome to Multi-Arch Backend API",
        "version": "1.0.0"
    }

@app.get("/api/info")
async def get_info():
    """Get system information including architecture"""
    return {
        "architecture": platform.machine(),
        "system": platform.system(),
        "platform": platform.platform(),
        "python_version": platform.python_version(),
        "processor": platform.processor(),
    }

@app.get("/api/hello/{name}")
async def hello(name: str):
    """Simple greeting endpoint"""
    return {
        "message": f"Hello {name}!",
        "architecture": platform.machine()
    }

@app.get("/api/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "architecture": platform.machine()}

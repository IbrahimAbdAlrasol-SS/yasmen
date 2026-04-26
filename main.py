from fastapi import FastAPI, BackgroundTasks, WebSocket, WebSocketDisconnect
from fastapi.responses import FileResponse
import asyncio
from pydantic import BaseModel
import uvicorn
import socket
from scanner import run_nmap_scan, run_custom_port_scan

app = FastAPI(title="Nmap Advanced Dashboard")

@app.get("/")
async def dashboard():
    return FileResponse("templates/index.html")

@app.get("/api/local_ip")
async def get_local_ip():
    """هذا الرابط يعيد عنوان الـ IP المحلي لجهاز لينكس الذي يستضيف الموقع"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except Exception:
        local_ip = "127.0.0.1"
    return {"local_ip": local_ip}

# لتخزين نتائج الفحص مؤقتاً في الذاكرة
scan_results = {}

class ScanRequest(BaseModel):
    target_ip: str
    scan_type: str = "basic"

class CustomScanRequest(BaseModel):
    target_ip: str
    port: str
    script_name: str

async def execute_and_store_scan(scan_id: str, target_ip: str, scan_type: str):
    # تشغيل الفحص وحفظ النتيجة في القاموس
    result = await run_nmap_scan(target_ip, scan_type)
    scan_results[scan_id] = result

async def execute_and_store_custom_scan(scan_id: str, target_ip: str, port: str, script_name: str):
    result = await run_custom_port_scan(target_ip, port, script_name)
    scan_results[scan_id] = result

@app.post("/api/scan")
async def start_scan(request: ScanRequest, background_tasks: BackgroundTasks):
    """
    هذا الرابط يستقبل الـ IP ويبدأ الفحص في الخلفية فوراً
    """
    scan_id = request.target_ip 
    
    # وضع حالة مبدئية
    scan_results[scan_id] = {"status": "running"}
    
    # إرسال المهمة للعمل في الخلفية
    background_tasks.add_task(execute_and_store_scan, scan_id, request.target_ip, request.scan_type)
    
    return {"message": "Scan started in background", "scan_id": scan_id}

@app.post("/api/custom_scan")
async def start_custom_scan(request: CustomScanRequest, background_tasks: BackgroundTasks):
    scan_id = f"custom_{request.target_ip}_{request.port}_{request.script_name}"
    scan_results[scan_id] = {"status": "running"}
    background_tasks.add_task(execute_and_store_custom_scan, scan_id, request.target_ip, request.port, request.script_name)
    return {"message": "Custom scan started", "scan_id": scan_id}

@app.websocket("/ws/scan_status/{scan_id}")
async def websocket_endpoint(websocket: WebSocket, scan_id: str):
    """
    اتصال WebSocket لتوفير نتائج الفحص في الوقت الفعلي (Real-Time)
    ومنع مشاكل الـ Timeout في الفحوصات الطويلة (أكثر من 10 دقائق)
    """
    await websocket.accept()
    try:
        while True:
            result = scan_results.get(scan_id)
            if not result:
                await websocket.send_json({"status": "not_found"})
                break
            
            if result.get("status") != "running":
                await websocket.send_json(result)
                await asyncio.sleep(1)
                break
            
            await websocket.send_json({"status": "running"})
            await asyncio.sleep(2)
    except WebSocketDisconnect:
        pass

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)

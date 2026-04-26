import asyncio
import xmltodict
import json
import os
import re
import platform

def is_valid_target(target: str) -> bool:
    # حماية من ثغرات حقن الأوامر (Command Injection)
    # نسمح فقط بالأرقام والحروف والنقاط لضمان أنه IP أو دومين
    pattern = re.compile(r"^[a-zA-Z0-9\.\-]+$")
    return bool(pattern.match(target))

async def run_nmap_scan(target_ip: str, scan_type: str = "basic"):
    """
    تقوم هذه الدالة بتشغيل nmap بشكل غير متزامن (Async)
    """
    if not is_valid_target(target_ip):
        return {"status": "error", "message": "تم إيقاف الفحص: صيغة الـ IP غير صالحة. (تم منع محاولة حقن أوامر)"}

    # إذا كان النظام لينكس سنستخدم sudo، إذا كان ويندوز سنستخدم nmap العادي للتجريبي
    nmap_base = "sudo nmap" if os.name == "posix" else "nmap"

    if scan_type == "basic":
        # فحص سريع للمنافذ واكتشاف نظام التشغيل مع إضافة -Pn لتخطي فحص البينج
        args = "-T4 -F -O -Pn -oX -"
    elif scan_type == "vuln":
        # فحص الثغرات باستخدام سكربتات Nmap مع إضافة -Pn
        args = "-sV --script vulners -Pn -oX -"
    else:
        args = "-Pn -oX -"

    # Auto-detect OS: Use sudo for Linux, direct command for Windows
    if platform.system() == "Windows":
        cmd = f"nmap {args} {target_ip}"
    else:
        cmd = f"sudo nmap {args} {target_ip}"

    print(f"[*] Starting scan on {target_ip} with command: {cmd}")

    try:
        # تشغيل الأمر في الخلفية
        process = await asyncio.create_subprocess_shell(
            cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        # انتظار انتهاء الفحص وجلب المخرجات
        stdout, stderr = await process.communicate()

        if process.returncode != 0:
            error_msg = stderr.decode(errors='ignore')
            print(f"[!] Nmap Error: {error_msg}")
            return {"status": "error", "message": error_msg}

        # تحويل مخرجات XML إلى JSON (Dictionary) ليسهل التعامل معها
        try:
            xml_data = stdout.decode('utf-8', errors='ignore')
            json_data = xmltodict.parse(xml_data)
            return {"status": "success", "data": json_data}
        except Exception as e:
            return {"status": "error", "message": f"Failed to parse XML: {str(e)}"}
    except Exception as e:
        return {"status": "error", "message": f"Execution failed (هل Nmap مثبت لديك في الويندوز؟): {str(e)}"}

async def run_custom_port_scan(target_ip: str, port: str, script_name: str):
    """تشغيل أوامر Nmap مخصصة على بورت معين بناءً على طلب المستخدم من الواجهة"""
    if not is_valid_target(target_ip) or not port.isdigit():
        return {"status": "error", "message": "تم إيقاف الفحص: مدخلات غير صالحة."}

    # قائمة بالسكربتات الآمنة التي يمكن للمستخدم تجربتها مع إضافة -Pn
    allowed_scripts = {
        "http-title": "--script http-title -Pn",
        "http-enum": "--script http-enum -Pn",
        "ftp-anon": "--script ftp-anon -Pn",
        "ssl-enum-ciphers": "--script ssl-enum-ciphers -Pn",
        "vuln": "--script vuln -Pn",
        "aggressive": "-A -Pn"
    }
    
    script_arg = allowed_scripts.get(script_name, "-sV -Pn")
    if platform.system() == "Windows":
        cmd = f"nmap -p {port} {script_arg} -oX - {target_ip}"
    else:
        cmd = f"sudo nmap -p {port} {script_arg} -oX - {target_ip}"
        
    print(f"[*] Running custom script on {target_ip}:{port} -> {cmd}")

    try:
        process = await asyncio.create_subprocess_shell(
            cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        stdout, stderr = await process.communicate()
        if process.returncode != 0:
            return {"status": "error", "message": stderr.decode(errors='ignore')}
        
        try:
            xml_data = stdout.decode('utf-8', errors='ignore')
            json_data = xmltodict.parse(xml_data)
            return {"status": "success", "data": json_data}
        except Exception as e:
            return {"status": "error", "message": f"Failed to parse XML: {str(e)}"}
    except Exception as e:
        return {"status": "error", "message": f"Execution failed: {str(e)}"}


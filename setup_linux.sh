#!/bin/bash
# سكريبت إعداد المشروع على بيئة لينكس (Ubuntu/Debian)

echo "[*] Installing Nmap and Python prerequisites..."
sudo apt update
sudo apt install -y nmap python3 python3-pip python3-venv

echo "[*] Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "[*] Configuring sudoers for Nmap (No Password required for the web server)..."
# جلب اسم المستخدم الحالي الذي سيشغل السيرفر
CURRENT_USER=$USER
# إضافة قاعدة للسماح بتشغيل nmap بصلاحيات الروت دون المطالبة بباسورد
echo "$CURRENT_USER ALL=(root) NOPASSWD: /usr/bin/nmap" | sudo tee /etc/sudoers.d/nmap_web_dashboard

echo "[*] Setup complete! 🚀"
echo "You can now run the server using:"
echo "source venv/bin/activate"
echo "python main.py"

# ============================================================
#  AghaBanafshi X-UI Railway
#  Dockerfile — همه فایل‌ها را خودش می‌سازد
# ============================================================

FROM alireza7/x-ui:latest

USER root

# نصب Nginx و ابزارهای لازم
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        gettext-base \
        curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ============================================================
#  ساخت nginx.conf.template
# ============================================================
RUN cat > /etc/nginx/nginx.conf.template << 'NGINXEOF'
worker_processes 1;
events { worker_connections 1024; }

http {
    server {
        listen ${PORT};
        server_name _;

        location /managepanel/ {
            proxy_pass http://127.0.0.1:54321/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        location /cdn {
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
    }
}
NGINXEOF

# ============================================================
#  ساخت start.sh
# ============================================================
RUN cat > /start.sh << 'STARTEOF'
#!/bin/bash
set -e

echo "=============================================="
echo "  AghaBanafshi X-UI Railway - Starting..."
echo "=============================================="

# 1) ساخت پوشه قالب ساب
mkdir -p /etc/x-ui/sub_templates

# 2) نوشتن قالب اختصاصی صفحه ساب
cat > /etc/x-ui/sub_templates/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AghaBanafshi X-UI Railway | اشتراک من</title>
    <link href="https://fonts.googleapis.com/css2?family=Vazirmatn:wght@300;400;500;700;900&display=swap" rel="stylesheet">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Vazirmatn', Tahoma, sans-serif;
            background: radial-gradient(circle at 20% 20%, #2e1065 0%, #1e1b4b 40%, #0f0a1f 100%);
            min-height: 100vh; display: flex; align-items: center; justify-content: center;
            padding: 20px; color: #ede9fe; position: relative; overflow-x: hidden;
        }
        body::before {
            content: ''; position: fixed; top: -100px; left: -100px;
            width: 400px; height: 400px;
            background: radial-gradient(circle, rgba(139, 92, 246, 0.3) 0%, transparent 70%);
            border-radius: 50%; filter: blur(60px); z-index: 0;
            animation: float 8s ease-in-out infinite;
        }
        body::after {
            content: ''; position: fixed; bottom: -100px; right: -100px;
            width: 450px; height: 450px;
            background: radial-gradient(circle, rgba(168, 85, 247, 0.25) 0%, transparent 70%);
            border-radius: 50%; filter: blur(80px); z-index: 0;
            animation: float 10s ease-in-out infinite reverse;
        }
        @keyframes float {
            0%, 100% { transform: translate(0, 0); }
            50% { transform: translate(30px, 30px); }
        }
        .card {
            position: relative; z-index: 1;
            background: linear-gradient(145deg, rgba(46, 16, 101, 0.75), rgba(30, 27, 75, 0.85));
            backdrop-filter: blur(25px); -webkit-backdrop-filter: blur(25px);
            border: 1px solid rgba(168, 85, 247, 0.3); border-radius: 28px;
            padding: 36px 32px; max-width: 500px; width: 100%;
            box-shadow: 0 25px 60px -15px rgba(88, 28, 135, 0.6), inset 0 1px 0 rgba(255, 255, 255, 0.05);
            animation: fadeIn 0.7s cubic-bezier(0.22, 1, 0.36, 1);
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(30px) scale(0.98); }
            to { opacity: 1; transform: translateY(0) scale(1); }
        }
        .card::before {
            content: ''; position: absolute; top: 0; left: 50%; transform: translateX(-50%);
            width: 60%; height: 3px;
            background: linear-gradient(90deg, transparent, #a855f7, #c084fc, #a855f7, transparent);
            border-radius: 3px;
        }
        .header { text-align: center; margin-bottom: 30px; }
        .brand-icon {
            display: inline-flex; align-items: center; justify-content: center;
            width: 60px; height: 60px; background: linear-gradient(135deg, #7c3aed, #a855f7);
            border-radius: 18px; margin-bottom: 16px; box-shadow: 0 8px 24px rgba(139, 92, 246, 0.5);
        }
        .brand-icon svg { width: 32px; height: 32px; fill: white; }
        .header h1 {
            font-size: 1.65rem; font-weight: 900;
            background: linear-gradient(90deg, #c084fc, #e9d5ff, #c084fc);
            -webkit-background-clip: text; -webkit-text-fill-color: transparent;
            background-clip: text; line-height: 1.4; letter-spacing: -0.5px;
        }
        .header .subtitle { font-size: 0.9rem; color: #a78bfa; margin-top: 6px; font-weight: 400; }
        .status-badge {
            display: inline-flex; align-items: center; gap: 6px;
            margin-top: 14px; padding: 7px 18px; border-radius: 999px;
            font-size: 0.85rem; font-weight: 600;
        }
        .status-active {
            background: rgba(52, 211, 153, 0.12); color: #6ee7b7;
            border: 1px solid rgba(52, 211, 153, 0.3);
            box-shadow: 0 0 20px rgba(52, 211, 153, 0.15);
        }
        .status-inactive {
            background: rgba(248, 113, 113, 0.12); color: #fca5a5;
            border: 1px solid rgba(248, 113, 113, 0.3);
        }
        .status-dot {
            width: 7px; height: 7px; border-radius: 50%;
            background: currentColor; animation: pulse 2s ease-in-out infinite;
        }
        @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }
        .stats-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-bottom: 8px; }
        .stat-box {
            background: rgba(139, 92, 246, 0.08); border: 1px solid rgba(168, 85, 247, 0.18);
            border-radius: 16px; padding: 16px; text-align: center; transition: all 0.3s ease;
        }
        .stat-box:hover {
            background: rgba(139, 92, 246, 0.15);
            border-color: rgba(168, 85, 247, 0.35);
            transform: translateY(-2px);
        }
        .stat-label { font-size: 0.8rem; color: #a78bfa; margin-bottom: 6px; font-weight: 500; }
        .stat-value { font-size: 1.1rem; font-weight: 700; color: #f3e8ff; }
        .info-row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 14px 4px; border-bottom: 1px solid rgba(168, 85, 247, 0.12);
        }
        .info-row:last-of-type { border-bottom: none; }
        .label { color: #c4b5fd; font-size: 0.92rem; display: flex; align-items: center; gap: 8px; }
        .value { font-weight: 700; font-size: 0.98rem; color: #f5f3ff; }
        .value.used { color: #fbbf24; }
        .value.remained { color: #6ee7b7; }
        .links { margin-top: 24px; display: flex; flex-direction: column; gap: 10px; }
        .links a {
            display: flex; align-items: center; justify-content: center; gap: 8px;
            background: linear-gradient(135deg, #7c3aed, #a855f7); color: white;
            text-align: center; padding: 15px; border-radius: 14px;
            text-decoration: none; font-weight: 600; font-size: 0.98rem;
            transition: all 0.3s ease; box-shadow: 0 6px 20px rgba(124, 58, 237, 0.4);
            position: relative; overflow: hidden;
        }
        .links a::before {
            content: ''; position: absolute; top: 0; left: -100%;
            width: 100%; height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255,255,255,0.2), transparent);
            transition: left 0.5s ease;
        }
        .links a:hover::before { left: 100%; }
        .links a:hover { transform: translateY(-2px); box-shadow: 0 10px 30px rgba(168, 85, 247, 0.55); }
        .divider {
            height: 1px;
            background: linear-gradient(90deg, transparent, rgba(168, 85, 247, 0.3), transparent);
            margin: 26px 0 22px 0;
        }
        .footer { text-align: center; }
        .telegram-btn {
            display: inline-flex; align-items: center; justify-content: center; gap: 10px;
            background: linear-gradient(135deg, #229ED9, #1e8bc3);
            color: white; text-decoration: none; padding: 14px 24px;
            border-radius: 14px; font-weight: 600; font-size: 0.98rem;
            transition: all 0.3s ease; box-shadow: 0 6px 20px rgba(34, 158, 217, 0.35);
            width: 100%;
        }
        .telegram-btn:hover { transform: translateY(-2px); box-shadow: 0 10px 30px rgba(34, 158, 217, 0.55); }
        .telegram-btn svg { width: 22px; height: 22px; fill: currentColor; }
        .credit { margin-top: 18px; font-size: 0.75rem; color: #7c3aed; opacity: 0.7; font-weight: 500; }
        @media (max-width: 480px) {
            .card { padding: 28px 22px; }
            .header h1 { font-size: 1.35rem; }
            .stats-grid { gap: 8px; }
            .stat-box { padding: 12px; }
            .stat-value { font-size: 0.95rem; }
        }
    </style>
</head>
<body>
<div class="card">
    <div class="header">
        <div class="brand-icon">
            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>
            </svg>
        </div>
        <h1>AghaBanafshi X-UI Railway</h1>
        <div class="subtitle">{{ .subTitle }}</div>
        <div>
            {{ if .enabled }}
                <span class="status-badge status-active"><span class="status-dot"></span>فعال</span>
            {{ else }}
                <span class="status-badge status-inactive"><span class="status-dot"></span>غیرفعال</span>
            {{ end }}
        </div>
    </div>
    <div class="stats-grid">
        <div class="stat-box">
            <div class="stat-label">📊 مصرف شده</div>
            <div class="stat-value value used">{{ .used }}</div>
        </div>
        <div class="stat-box">
            <div class="stat-label">💚 باقی‌مانده</div>
            <div class="stat-value value remained">{{ .remained }}</div>
        </div>
    </div>
    <div class="info-row">
        <span class="label">📦 کل حجم</span>
        <span class="value">{{ .total }}</span>
    </div>
    <div class="info-row">
        <span class="label">⏰ تاریخ انقضا</span>
        <span class="value">{{ .expire }}</span>
    </div>
    <div class="links">
        {{ range .links }}
            <a href="{{ . }}">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/>
                    <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/>
                </svg>
                دریافت کانفیگ
            </a>
        {{ end }}
    </div>
    <div class="divider"></div>
    <div class="footer">
        <a href="https://t.me/AghaBanafshi" target="_blank" rel="noopener noreferrer" class="telegram-btn">
            <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z"/>
            </svg>
            <span>ورود به کانال تلگرام</span>
        </a>
        <div class="credit">AghaBanafshi X-UI Railway</div>
    </div>
</div>
</body>
</html>
HTMLEOF

# 3) تنظیم مسیر قالب ساب (در صورت پشتیبانی)
/usr/local/x-ui/x-ui setting -subThemeDir /etc/x-ui/sub_templates 2>/dev/null || true

# 4) تنظیم web base path
/usr/local/x-ui/x-ui setting -webBasePath /managepanel/ 2>/dev/null || true

# 5) ساخت nginx.conf با متغیر $PORT
envsubst '${PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# 6) اجرای Nginx در پس‌زمینه
nginx -g 'daemon off;' &

# 7) اجرای x-ui در پیش‌زمینه
exec /usr/local/x-ui/x-ui
STARTEOF

RUN chmod +x /start.sh

# ============================================================
#  پورت پیش‌فرض (Railway متغیر PORT را تزریق می‌کند)
# ============================================================
EXPOSE 8080

# ============================================================
#  اجرا
# ============================================================
CMD ["/start.sh"]

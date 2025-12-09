# Teleport Setup Guide

Hướng dẫn cài đặt và cấu hình Teleport client để deploy MLflow AI Gateway lên server 10.3.49.202.

## Cài đặt Teleport Client

### Windows

#### Phương pháp 1: Chocolatey (Khuyến nghị)
```powershell
choco install teleport
```

#### Phương pháp 2: Download trực tiếp
1. Truy cập: https://goteleport.com/docs/installation/
2. Download Windows installer
3. Chạy installer và làm theo hướng dẫn

#### Phương pháp 3: Scoop
```powershell
scoop install teleport
```

### Linux/macOS

#### Phương pháp 1: Script tự động
```bash
curl https://goteleport.com/static/install.sh | bash -s 13.4.15
```

#### Phương pháp 2: Package manager

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install teleport
```

**RHEL/CentOS:**
```bash
sudo yum install teleport
```

**macOS:**
```bash
brew install teleport
```

## Kiểm tra cài đặt

```bash
# Windows PowerShell
tsh version

# Linux/macOS
tsh version
```

Kết quả mong đợi: Hiển thị version của Teleport client (ví dụ: `Teleport v13.4.15`)

## Đăng nhập vào Teleport

### Bước 1: Lấy thông tin Teleport Proxy

Liên hệ quản trị viên để lấy:
- Teleport Proxy address (ví dụ: `teleport.example.com:3080` hoặc `teleport.example.com`)
- Username và password (hoặc phương thức xác thực khác)

### Bước 2: Đăng nhập

```bash
# Windows PowerShell hoặc Linux/macOS
tsh login --proxy=<teleport-proxy-address>
```

Ví dụ:
```bash
tsh login --proxy=teleport.example.com:3080
```

Hoặc nếu dùng port mặc định (443):
```bash
tsh login --proxy=teleport.example.com
```

### Bước 3: Xác thực

Tùy thuộc vào cấu hình Teleport, bạn có thể cần:
- Nhập username và password
- Sử dụng MFA (Multi-Factor Authentication)
- Sử dụng SSO (Single Sign-On)
- Sử dụng hardware token

### Bước 4: Kiểm tra trạng thái đăng nhập

```bash
tsh status
```

Kết quả mong đợi:
```
Profile URL:  https://teleport.example.com:3080
Logged in as: your-username
Cluster:      main
Roles:        access,editor
Logout:       tsh logout
```

## Kết nối đến server

### Kiểm tra kết nối

```bash
# Test connection
tsh ssh user@10.3.49.202 "echo 'Connection successful'"
```

### SSH vào server

```bash
tsh ssh user@10.3.49.202
```

### Copy files (SCP)

```bash
# Upload file
tsh scp local-file.txt user@10.3.49.202:/remote/path/

# Download file
tsh scp user@10.3.49.202:/remote/path/file.txt ./
```

## Troubleshooting

### Lỗi: "tsh: command not found"

**Giải pháp:**
- Đảm bảo Teleport đã được cài đặt
- Kiểm tra PATH environment variable
- Restart terminal/PowerShell sau khi cài đặt

### Lỗi: "Not logged in"

**Giải pháp:**
```bash
tsh login --proxy=<teleport-proxy-address>
```

### Lỗi: "Access denied" hoặc "Permission denied"

**Giải pháp:**
- Kiểm tra bạn có quyền truy cập server 10.3.49.202
- Liên hệ quản trị viên để cấp quyền
- Kiểm tra roles được gán: `tsh status`

### Lỗi: "Cannot connect to proxy"

**Giải pháp:**
- Kiểm tra Teleport proxy address có đúng không
- Kiểm tra network connectivity đến proxy
- Kiểm tra firewall có chặn kết nối không
- Thử ping proxy: `ping <teleport-proxy-address>`

### Lỗi: "Host key verification failed"

**Giải pháp:**
```bash
# Xóa known hosts
tsh logout
tsh login --proxy=<teleport-proxy-address>
```

## Sử dụng với deployment scripts

Sau khi đã cài đặt và đăng nhập Teleport, bạn có thể sử dụng các script deployment:

### Windows PowerShell
```powershell
cd "C:\Data_Mining\AI Gateway\mlflow-gateway"
.\deploy_to_server.ps1
```

### Linux/macOS Bash
```bash
cd /path/to/mlflow-gateway
chmod +x teleport_deploy.sh
./teleport_deploy.sh [username]
```

## Tài liệu tham khảo

- [Teleport Documentation](https://goteleport.com/docs/)
- [Teleport Installation Guide](https://goteleport.com/docs/installation/)
- [Teleport SSH Guide](https://goteleport.com/docs/server-access/guides/ssh/)
- [Teleport Client Guide](https://goteleport.com/docs/server-access/guides/tsh/)

## Lưu ý bảo mật

- Không chia sẻ Teleport credentials
- Đăng xuất khi không sử dụng: `tsh logout`
- Sử dụng MFA khi có thể
- Báo cáo ngay nếu phát hiện hoạt động đáng ngờ


# 🔒 Security Notes

## API Keys và Secrets

**QUAN TRỌNG:** Không bao giờ commit API keys hoặc secrets vào Git repository!

### Files cần được gitignore:
- `.env` - Chứa API keys thực tế
- `.env.backup` - Backup của .env
- `docker-compose.yml.backup` - Backup files

### Cách sử dụng API keys đúng cách:

1. **Tạo file .env từ template:**
   ```bash
   cp env.template .env
   ```

2. **Chỉnh sửa .env và thêm API key:**
   ```bash
   nano .env
   # Thêm: OPENAI_API_KEY=sk-your-actual-key-here
   ```

3. **Đảm bảo .env được gitignore:**
   - File `.gitignore` đã có `.env`
   - Không commit file .env

4. **Khi deploy:**
   - File .env phải được tạo trên server
   - Không push .env lên Git

### Nếu vô tình commit API key:

1. **Xóa khỏi Git history:**
   ```bash
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch docker-compose.yml" \
     --prune-empty --tag-name-filter cat -- --all
   ```

2. **Hoặc sử dụng git-secrets:**
   ```bash
   git secrets --register-aws
   git secrets --scan
   ```

3. **Rotate API key ngay lập tức:**
   - Tạo API key mới từ OpenAI dashboard
   - Xóa API key cũ
   - Cập nhật .env với key mới

### Best Practices:

- ✅ Sử dụng `.env` file (đã gitignore)
- ✅ Sử dụng environment variables
- ✅ Sử dụng secret management tools (Vault, AWS Secrets Manager, etc.) cho production
- ❌ Không hardcode API keys trong code
- ❌ Không commit .env file
- ❌ Không chia sẻ API keys qua chat/email


# 🔧 Fix Git Pull Conflict

## Vấn Đề

Git pull bị lỗi vì có local changes chưa commit.

## Giải Pháp

### Cách 1: Stash local changes (Khuyến nghị)

Lưu các thay đổi local và pull code mới:

```bash
# Stash local changes
git stash

# Pull code mới
git pull

# Nếu cần, apply lại local changes
git stash pop
```

### Cách 2: Discard local changes (Nếu không cần giữ)

Xóa local changes và pull code mới:

```bash
# Xem các file đã thay đổi
git status

# Discard changes cho các file cụ thể
git checkout -- deploy_web.sh
git checkout -- setup_and_deploy.sh

# Hoặc discard tất cả changes
git reset --hard HEAD

# Pull code mới
git pull
```

### Cách 3: Commit local changes trước

Nếu muốn giữ local changes:

```bash
# Add và commit local changes
git add deploy_web.sh setup_and_deploy.sh
git commit -m "Local fixes for deployment"

# Pull code mới (sẽ tạo merge commit)
git pull

# Nếu có conflict, resolve và commit
```

## Khuyến Nghị

Vì các file trên server đã được sửa để fix environment variable issue, nên:

1. **Stash local changes** (Cách 1)
2. **Pull code mới** từ repository
3. **Chạy script fix mới** nếu có

Sau khi pull, chạy:
```bash
chmod +x fix_env_issue.sh
./fix_env_issue.sh
```


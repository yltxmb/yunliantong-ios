# 无 Mac 用 GitHub Actions 编译 iOS（云链通）

你不需要 Mac。代码推到 GitHub 后，在 **Actions** 里用苹果云 Mac 编译；有企业证书时再打 IPA。

---

## 一、准备 GitHub 仓库

仓库示例：`https://github.com/yltxmb/yunliantong-ios`

---

## 二、只上传 iOS 代码（不要传整个 d:\yk）

### 推荐：独立小文件夹 `d:\yunliantong-ios`

在 PowerShell 执行（在 `Tencentim\iOS` 目录下）：

```powershell
cd d:\yk\Tencentim\iOS
.\prepare-ios-github-folder.ps1
```

会生成 `d:\yunliantong-ios`，只含：

```text
d:\yunliantong-ios\
├── .github/workflows/
├── Tencentim/TencentCloud-TIMSDK/iOS/Demo/
├── Tencentim/iOS/README.md
└── README.md
```

### GitHub Desktop

1. **File → Add local repository** → 选 **`d:\yunliantong-ios`**（不要选 `d:\yk`）
2. 若不是 Git 仓库 → **create a repository**
3. **Publish repository** → `yltxmb/yunliantong-ios`

### 命令行（可选）

```bash
cd /d/yunliantong-ios
git init
git add .
git commit -m "YunLianTong iOS Demo + GitHub Actions"
git branch -M main
git remote add origin https://github.com/yltxmb/yunliantong-ios.git
git push -u origin main
```

---

## 三、两种 Workflow

| Workflow | 是否需要证书 | 用途 |
|----------|--------------|------|
| **iOS Build Check (No Signing)** | 否 | 验证能编译 |
| **Build YunLianTong IPA (Enterprise)** | 是 | 下载 `.ipa` |

路径（workflow 内已配置）：

```text
Tencentim/TencentCloud-TIMSDK/iOS/Demo
```

---

## 四、先跑编译检查（无需证书）

1. 仓库 **Actions**
2. **iOS Build Check (No Signing)** → **Run workflow**

---

## 五、打 IPA（需要企业签 Secrets）

| Secret | 说明 |
|--------|------|
| `IOS_P12_BASE64` | 企业 `.p12` Base64 |
| `IOS_P12_PASSWORD` | 证书密码 |
| `IOS_PROVISION_BASE64` | `.mobileprovision` Base64 |

PowerShell 生成 Base64：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("enterprise.p12")) | Set-Clipboard
```

---

## 六、常见问题

**Q：文件夹必须叫 Tencentim 吗？**  
A：是。GitHub Actions 的 `working-directory` 已写死为 `Tencentim/TencentCloud-TIMSDK/iOS/Demo`，请保持该目录结构。

**Q：Push 要传哪些？**  
A：只传 `d:\yunliantong-ios` 里的内容；不要传 `Pods/`、`build/`。

**Q：新增 Biz `.m` 后 CI 报错？**  
A：在 Demo 目录执行 `node scripts/sync_biz_pbxproj.js` 并提交 `project.pbxproj`。

---

## 七、手动重命名顶层文件夹

若本地仍是旧中文名 `腾讯IM源码`，请在资源管理器中改为 **`Tencentim`**（关闭 Cursor 后再改，避免占用）。

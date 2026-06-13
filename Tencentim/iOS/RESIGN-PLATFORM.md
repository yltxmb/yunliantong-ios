## 第三方企业签平台打 IPA（无需苹果证书）

你买的是**签名平台**（上传 IPA → 平台重签 → 发安装链接），**不需要**在 GitHub 填 `IOS_P12_BASE64` 等 Secrets。

### 流程概览

```text
GitHub Actions 打出未签名 IPA
    → 下载 YunLianTong-unsigned.ipa
    → 上传到企业签平台
    → 平台重签后给安装链接 / 二维码
```

### 1. 先 Push 最新 workflow

本地 `d:\yunliantong-ios` 已包含：

`.github/workflows/ios-yunliantong-ipa-unsigned.yml`

GitHub Desktop：**Commit** → **Push origin**

### 2. 在 GitHub 导出 IPA

1. 打开 https://github.com/yltxmb/yunliantong-ios/actions
2. 左侧选 **Export IPA for Resign Platform**
3. **Run workflow** → **Run workflow**
4. 等约 10–20 分钟，成功后点该次 run
5. 底部 **Artifacts** → 下载 **YunLianTong-IPA-unsigned**（里面是 `YunLianTong-unsigned.ipa`）

### 3. 上传到企业签平台

在平台后台：

| 项 | 建议值 |
|----|--------|
| 上传文件 | `YunLianTong-unsigned.ipa` |
| Bundle ID | `com.guanglian.tim`（与 Android 一致） |
| 应用名 | 云链通 |

各平台界面不同，找「上传 IPA / 应用托管 / 企业签」即可。

### 4. 安装

平台重签完成后会提供：

- 安装链接（Safari 打开）
- 或二维码

iPhone：**设置 → 通用 → VPN与设备管理** 信任企业证书后再打开 App。

---

## 两种 GitHub Workflow 区别

| Workflow | 用途 | 需要 Secrets |
|----------|------|--------------|
| **Export IPA for Resign Platform** | 给第三方企业签平台用 | **不需要** |
| **Build YunLianTong IPA (Enterprise)** | 自己有苹果企业证书时用 | 需要 p12 + 描述文件 |
| **iOS Build Check** | 只验证能编译 | 不需要 |

---

## 平台不接受未签名 IPA 时

少数平台要求 IPA 已用**个人 Apple 开发者账号**签过一遍。那时需要：

- 在平台或 Mac 上用 Apple ID 导出开发版 IPA，或
- 把 Apple ID / 专用密码配到 GitHub Secrets（可再单独做 workflow）

大多数国内企业签平台直接收未签名或任意 IPA 并重签。

---

## 更新 App 后

1. 改代码 → Push 到 GitHub  
2. 再跑 **Export IPA for Resign Platform**  
3. 下载新 IPA → 上传到平台（或平台支持「版本更新」）

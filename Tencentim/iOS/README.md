# 云链通 iOS（TUIKit Demo 定制版）

基于 `TencentCloud-TIMSDK/iOS/Demo`，与 Android「云链通」共用同一套 ThinkPHP 后端。

## 功能对齐

- 登录：11 位手机号 + 密码 → `POST /api/usersig.php` → 服务端下发 `sdkAppId` + `userSig`
- 注册 / 忘记密码：`/api/register.php`、`/api/reset_password.php` + 密保问题
- 4 Tab：消息 / 发现 / 通讯录 / 我（Classic + Minimalist）
- 发现：朋友圈（feed/点赞/评论/封面/互动通知）、扫一扫 → 加好友
- 我：个人资料编辑、黑名单、改密、QR、协议、退出
- 消息 Tab「+」菜单：扫一扫
- 多线路、维护模式、公告

## 本地编译（需 macOS + Xcode）

```bash
cd Tencentim/TencentCloud-TIMSDK/iOS/Demo
pod install
open TUIKitDemo.xcworkspace
# Scheme: TUIKitDemo，真机或 Generic iOS Device Archive
```

新增 `TUIKitDemo/Biz/` 源文件后，在 Demo 目录执行以下命令同步 Xcode 工程（自动写入 `project.pbxproj`）：

```bash
node scripts/sync_biz_pbxproj.js
```

## API 配置

默认与 Android `local.properties` 一致：`https://gl27.snbxj.cn`。

可在 `TUIKitDemo/Info.plist` 增加（或通过 Xcode Build Settings 注入）：

- `YLTApiBase`
- `YLTUserSigApiUrl`
- `YLTUserSigApiKey`
- `YLTAppPublicConfigUrl`
- `YLTApiLinesUrl`

## GitHub Actions 企业签 IPA

**无 Mac 完整步骤见：[GITHUB-SETUP.md](./GITHUB-SETUP.md)**

Workflow：

| 名称 | 文件 | 证书 |
|------|------|------|
| iOS Build Check | `.github/workflows/ios-yunliantong-build-check.yml` | 不需要 |
| Build YunLianTong IPA | `.github/workflows/ios-yunliantong-ipa.yml` | 需要企业签 |

Secrets（Repository Settings → Secrets and variables → Actions → Secrets）：

| Secret | 说明 |
|--------|------|
| `IOS_P12_BASE64` | 企业证书 .p12 的 base64 |
| `IOS_P12_PASSWORD` | 证书密码 |
| `IOS_PROVISION_BASE64` | 企业描述文件 .mobileprovision 的 base64 |

Variables（可选）：

| Variable | 说明 |
|----------|------|
| `IOS_BUNDLE_ID` | 默认 `com.guanglian.tim`（与 Android 包名对齐） |

触发：Actions 页手动 Run，或推送 tag `ios-v*` / `v*`。

## 源码位置

- 业务层：`TUIKitDemo/Biz/`
- 登录改造：`TUIKitDemo/Login/LoginController.m`
- Tab 改造：`TUIKitDemo/AppDelegate.m` → `getMainController_Classic`

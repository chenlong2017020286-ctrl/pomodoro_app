# Pomodoro App 🍅

可爱卡通风格的番茄钟 iOS 应用。

## 功能

- 🍅 专注 25 分钟 / ☕ 短休息 5 分钟 / 🌿 长休息 15 分钟
- ▶️ 开始 / ⏸ 暂停 / ↺ 重置
- 圆形渐变进度条 + 脉冲动画
- 番茄数统计，每 4 个番茄自动长休息
- 中英文切换
- 完成时震动 + 提示音

## 通过 GitHub Actions 编译 IPA

1. 将此项目推送到 GitHub
2. 进入 **Actions** 页面
3. 点击 **Build iOS IPA** → **Run workflow**
4. 等待编译完成（约 5-10 分钟）
5. 在 **Artifacts** 中下载 `pomodoro-ipa`
6. 解压得到 `pomodoro_app.ipa`

### 安装 IPA 到 iPhone

由于 IPA 未签名，需要以下方式之一安装：

- **AltStore / Sideloadly** — 免费侧载工具，有效期 7 天
- **Apple Developer** — 如有开发者账号，可用 `flutter build ipa` 重新签名
- **自签证书** — 通过 Xcode 手动签名后安装

## 本地开发

```bash
flutter pub get
flutter run
```

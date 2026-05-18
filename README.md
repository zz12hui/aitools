# AI Tools Tutorial (aitools)

AI 工具教程系列 — 20 页静态网站，涵盖 Claude Code、Hermes、Codex、OpenCode、OpenClaw 等 AI 编程工具的安装、配置和使用教程。

## 技术栈

- 纯静态 HTML/CSS/JS，零依赖，零构建步骤
- 深色主题，CSS 自定义属性管理配色
- 粒子背景动画、3D 卡片倾斜、滚动揭示等交互效果

## 本地运行

```bash
cd "/Volumes/data 1/local/dev"
python3 -m http.server 8080
# 访问 http://localhost:8080/aitools/
```

## 部署

通过 nginx 部署到 `4si.cc`，文档根目录 `/tmp/ai-tutorial`：

```bash
sudo nginx -t && sudo systemctl reload nginx
```

SSL 证书通过 Let's Encrypt 管理，certbot 自动续期。

## 页面结构

- `index.html` — 首页（粒子背景 + 卡片网格 + 路径导航）
- `index-nav.html` — 完整目录索引
- `01-overview.html` ~ `18-installer.html` — 20 篇教程内容页

## 添加新教程

1. 复制任意内容页作为模板
2. 按 `NN-slug.html` 命名规范
3. 更新 `<title>`、`<meta>` 标签和导航标题
4. 在 `index.html` 添加卡片链接，`index-nav.html` 添加目录条目
5. 在 `sitemap.xml` 添加 URL

## License

MIT

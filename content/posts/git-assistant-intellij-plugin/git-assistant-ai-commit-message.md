---
title: "使用 Git Assistant IntelliJ 插件中的 AI 功能来生成提交信息"
date: 2024-07-17T20:24:14+08:00
tags: [intellij]
categories: [git, intellij, plugin]
draft: false
---

Git Assistant 插件是一个强大的 IntelliJ IDEA 插件，你可以通过配置自己的 OpenAI key 来使用其中的 AI 功能。在这篇文章中，我们将介绍如何使用 Git Assistant 插件中的 AI 功能来生成提交信息。

### 安装 Git Assistant 插件

首先，你需要在 IntelliJ IDEA 中安装 Git Assistant 插件。你可以通过 IntelliJ IDEA 的插件市场搜索 `Git Assistant` 并安装它。

![screenshot-plugins-marketplace](/images/posts/git-assistant-intellij-plugin/screenshot-plugins-marketplace.png)

### 配置 Git Assistant 插件

在安装完 Git Assistant 插件后，打开 Settings -> Plugins -> Tools -> Git Assistant 后可以看到如下配置界面。

![screenshot-settings-global.png](/images/posts/git-assistant-intellij-plugin/screenshot-settings-global.png)

#### OpenAI 配置

在这里你可以配置你的 OpenAI API host 和 OpenAI API key 后点击 Verify 按钮来验证你的配置是否正确。
通过点击 Refresh 按钮来刷新你可用的模型列表。最后点击 Apply 按钮来保存你的配置。

#### Global Prompt 配置

你可以在这里配置提示工程参数，用来控制生成的 commit message 的内容。

- Locale: 语言环境
- Prompt: Basic 和 Conventional Commits 两种模式
- Output template: 在选择 Basic 模式后可以通过模版定义生成的 commit message 的格式，模版中可以使用 $message 和 $branch 两个变量。
- Commit subject limit: 生成的 commit message 的长度限制
- Truncate excessive length: 如果大模型生成的信息长度超过 Commit subject limit 是否截断
- Relegate excess to body: 如果大模型生成的信息长度超过 Commit subject limit 是否将多余的信息放到 body 中

**注意：** Global Prompt 的配置是全局的，即所有的项目都会使用这个配置。如果你要为某个项目单独配置，可以在 Settings -> Plugins -> Tools -> Git Assistant -> Prompt 中配置。

### 使用 AI 功能生成提交信息

在配置完成后，你可以在左侧的 Commit 面板中看到 💡按钮，点击它来生成提交信息。

使用 Conventional Commits 模式生成的提交信息

![screenshot-prompt-conventional-commits.png](/images/posts/git-assistant-intellij-plugin/screenshot-prompt-conventional-commits.png)

使用 Basic 和 Output template 模式生成的提交信息

![screenshot-prompt-basic-asf.png](/images/posts/git-assistant-intellij-plugin/screenshot-prompt-basic-asf.png)

开启 Truncate excessive length 和 Relegate excess to body 选项后，如果生成的提交信息长度超过限制，会自动截断并将多余的信息放到 body 中。

![screenshot-maximum-turncate.png](/images/posts/git-assistant-intellij-plugin/screenshot-maximum-turncate.png)

### 当前提交者信息展示

你可以简单的在底部状态栏右侧看到当前仓库的提交者信息。尤其当你需要在多个仓库之间切换时，这个信息会让你避免设置了错误的提交者信息。

![screenshot-gitconfig.png](/images/posts/git-assistant-intellij-plugin/screenshot-gitconfig.png)

### 结束语

你可以在 [JetBrains Marketplace](https://plugins.jetbrains.com/plugin/14896-git-assistant) 上查看 Git Assistant 插件的详细信息并留下你的宝贵建议。
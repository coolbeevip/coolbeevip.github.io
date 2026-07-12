---
title: "Zsh 我的配置"
date: 2026-07-12T13:24:14+08:00
tags: [linux,zsh,shell]
categories: [linux]
draft: false
---

这篇只解决三个问题：

- 输入命令时，根据历史记录给出自动补全提示
- 按 Tab 时，补全更多命令、参数和子命令
- 输入命令时，实时显示语法高亮

用到三个插件：

- `zsh-autosuggestions`
- `zsh-completions`
- `zsh-syntax-highlighting`

下面每个插件单独安装、单独配置。只需要哪个，就看哪个章节。

## 准备 zsh 插件目录

先创建一个统一的插件目录：

```shell
mkdir -p ~/.zsh/plugins
```

后面的插件都会安装到这个目录下。

## 安装 zsh-autosuggestions

`zsh-autosuggestions` 用来根据历史命令给出输入提示。

比如你以前执行过：

```shell
ssh -p 2222 ops@203.0.113.10
```

下次输入 `ssh` 时，终端可能会用灰色文字提示后半段命令。按右方向键可以接受提示。

安装插件：

```shell
git clone https://github.com/zsh-users/zsh-autosuggestions.git \
    ~/.zsh/plugins/zsh-autosuggestions
```

然后在 `~/.zshrc` 中加入：

```shell
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
```

如果想让提示颜色更淡一点，可以继续加入：

```shell
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
```

重新加载配置：

```shell
source ~/.zshrc
```

验证方式：

```shell
history | tail
```

找一条历史命令，输入它的前几个字符。如果后面出现灰色提示，说明插件已经生效。

## 安装 zsh-completions

`zsh-completions` 用来增强 zsh 的 Tab 补全规则。

它和 `zsh-autosuggestions` 不一样：

- `zsh-autosuggestions` 是根据历史命令给输入提示
- `zsh-completions` 是让 Tab 补全认识更多命令、参数和子命令

安装插件：

```shell
git clone https://github.com/zsh-users/zsh-completions.git \
    ~/.zsh/plugins/zsh-completions
```

然后在 `~/.zshrc` 中加入：

```shell
fpath=(~/.zsh/plugins/zsh-completions/src $fpath)

autoload -Uz compinit
compinit
```

注意：`fpath` 必须写在 `compinit` 前面。

如果你的 `~/.zshrc` 里已经有下面这两行：

```shell
autoload -Uz compinit
compinit
```

不要重复添加，只需要把 `fpath` 那一行放到它们前面：

```shell
fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
autoload -Uz compinit
compinit
```

重新加载配置：

```shell
source ~/.zshrc
```

如果补全没有变化，可能是旧的补全缓存还在。可以删除缓存后重新加载：

```shell
rm -f ~/.zcompdump*
source ~/.zshrc
```

验证方式：

```shell
git <Tab>
ssh -<Tab>
systemctl <Tab>
```

如果 Tab 后能补出更多子命令或参数，说明插件已经生效。

## 安装 zsh-syntax-highlighting

`zsh-syntax-highlighting` 用来给正在输入的命令做语法高亮。

常见效果：

- 可执行命令显示为正常颜色
- 不存在的命令显示为红色
- 字符串、路径、参数会显示不同颜色

安装插件：

```shell
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ~/.zsh/plugins/zsh-syntax-highlighting
```

然后在 `~/.zshrc` 中加入：

```shell
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
```

注意：`zsh-syntax-highlighting` 建议放在 `~/.zshrc` 的最后加载。

重新加载配置：

```shell
source ~/.zshrc
```

验证方式：

```shell
not-a-real-command
```

如果命令变成红色，说明插件已经生效。

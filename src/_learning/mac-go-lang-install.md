---
title: "MacでのGo言語インストール手順"
date: 2024-04-17T10:40:00
jobtitle: ""
linkedinurl: ""
mermaid: true
weight: 7
tags:
  - Go
  - Mac
  - Installation Guide
  - Development Environment
  - Homebrew
description: "MacにGo言語をインストールする手順を紹介。Apple Silicon（ARM64）対応の手順で、環境変数の設定や動作確認も詳しく解説しています。"
---


<https://learn.microsoft.com/ja-jp/azure/developer/go/configure-visual-studio-code>

### 1.SPHardwareDataType

```bash
~/Documents$ system_profiler -json SPHardwareDataType

{
  "SPHardwareDataType" : [
    {
      "_name" : "hardware_overview",
      "activation_lock_status" : "activation_lock_disabled",
      "boot_rom_version" : "10151.61.4",
      "chip_type" : "Apple M2",
      "machine_model" : "Mac14,7",
      "machine_name" : "MacBook Pro",
      "model_number" : "Z16T0004TJ/A",
      "number_processors" : "proc 8:4:4",
      "os_loader_version" : "10151.61.4",
      "physical_memory" : "16 GB",
      "platform_UUID" : "D26E7BC6-425E-51C2-87C5-0B902782B60D",
      "provisioning_UDID" : "00008112-000251423E78201E",
      "serial_number" : "D5XQV1FMFJ"
    }
  ]
}%      
```

### 2.Download and install

Apple macOS (ARM64) のパッケージをDLしてInstall

### 3. 環境変数に追加

```bash
# 変更前
echo $PATH

# 変更
$export PATH=$PATH:/usr/local/go/bin

# 変更後
echo $PATH
```

### 4. install 確認

```bash
$ go version
go version go1.22.2 darwin/arm64
```

### 5.以降はmicrosoftさんの手順通り実行してください

# Nginx 代理配置自動化腳本

## 簡介

本腳本用於快速生成客戶域名的 Nginx 代理配置文件，適用於企業級代理場景。通過自動化複製現有域名的配置文件模板，並修改 SSL 證書、監聽域名等關鍵參數，顯著提升配置效率。後端服務基於 PHP 實現，支持根據域名動態加載客戶定製化頁面（如 LOGO、文案等）。

---

## 功能特性

- **一鍵生成配置**：基於現有域名配置文件快速生成新配置。
- **SSL 證書自動化**：支持自動檢測並配置 `.pem`、`.cer`、`.crt` 格式的 SSL 證書。
- **安全備份**：自動備份歷史配置文件，保留最近 10 份備份，防止誤操作。
- **兼容性**：支持 CentOS 7+、Ubuntu 16.04+ 等主流 Linux 發行版。
- **DingTalk 通知集成**：配置成功後自動發送通知至 DingTalk 群（需預先配置 `dingding.sh`）。

---

## 系統要求

- **操作系統**：Linux（CentOS 7+/Ubuntu 16.04+/Alpine）
- **依賴軟件**：Nginx 1.18+、OpenSSL、Bash 4.0+
- **權限要求**：需以 `root` 或具有 `sudo` 權限的用戶運行。

---

## 安裝與配置

1. **下載腳本**
   將腳本保存至伺服器，建議存放於統一管理目錄：
```
mkdir -p /opt/scripts && cd /opt/scripts
git clone https://github.com/WillemCode/ScriptTools.git
cd ScriptTools
chmod +x nginx_config_copy.sh dingding.sh
```

2. **配置 DingTalk 通知（可選）**

   如需啟用 DingTalk 通知，需在同一目錄下提供 `dingding.sh`，並確

保其可執行權限。

---

## 使用方法

### 操作模式說明

| 模式 | 命令格式 | 描述 |
|------|----------|------|
| **模式 1** | `./nginx_config_copy.sh [pem/cer/crt]` | 僅指定 SSL 證書類型，需手動輸入新舊域名。 |
| **模式 2** | `./nginx_config_copy.sh [pem/cer/crt] [新域名] [舊域名]` | 標準配置模式，若文件存在則提示覆蓋。 |
| **模式 3** | `./nginx_config_copy.sh [pem/cer/crt] [新域名] [舊域名] force` | 強制覆蓋模式，跳過確認直接替換。 |

### 參數詳解

| 參數 | 必選 | 說明 |
|------|------|------|
| `pem/cer/crt` | 是 | SSL 證書文件後綴類型。 |
| `新域名` | 是 | 需代理的新域名（如 `www.new.com`）。 |
| `舊域名` | 是 | 參考的舊域名配置文件（如 `www.old.com`）。 |
| `force` | 否 | 強制覆蓋同名配置文件。 |

### 使用示例

**示例 1：交互式配置（模式 1）**  
```bash
./nginx_config_copy.sh pem
# 根據提示輸入新舊域名
```

**示例 2：快速生成配置（模式 2）**  
```bash
./nginx_config_copy.sh crt www.client.com www.template.com
```

**示例 3：強制覆蓋配置（模式 3）**  
```bash
./nginx_config_copy.sh cer www.client2024.com www.template.com force
```

---

## 配置文件說明

### 生成文件路徑
- **Nginx 配置**：自動檢測，默認存放於 `/etc/nginx/conf.d/`（根據實際環境可能不同）。
- **SSL 證書**：自動檢測，舊證書路徑，默認位於 `/etc/nginx/ssl/`。

### PHP 集成
生成的配置文件中，`root` 路徑與原域名一致，後端 PHP 可通過 `$_SERVER['HTTP_HOST']` 獲取當前域名，動態加載客戶定製化頁面。示例邏輯：
```php
// 根據域名加載不同客戶模板
$client = $_SERVER['HTTP_HOST'];
include("/var/www/html/clients/$client/header.php");
```

---

## 注意事項

1. **SSL 證書準備**  
   - 需提前將證書文件（`.key` 和指定後綴文件）放置於腳本檢測路徑（通常為舊域名證書目錄）。
   - 證書文件命名需為 `[域名].[後綴]`，如 `www.client.com.pem`。

2. **備份策略**  
   - 每次執行自動備份至 `~/.domainpilot/backups/`，保留最近 10 份。

3. **日誌查看**  
   - 執行日誌實時輸出至終端，錯誤信息標紅顯示。

---

## 技術支持

- **問題反饋**：請提交 Issue 至 [GitHub 倉庫](https://github.com/WillemCode/ScriptTools/issues)。

---

## 授權說明

本專案採用 [GNU General Public License (GPL)](./LICENSE) 開源發布。

這意味著：

- 你可以自由複製、修改和分發本專案的源代碼，但修改後的專案也必須繼續以 GPL 或兼容的許可證進行發布；
- 分發或發布時，需包含本專案的原始版權聲明與 GPL 協議文本，並提供完整的源代碼獲取方式。

請參閱 [LICENSE](./LICENSE) 文件獲取詳細條款。若你對 GPL 的使用及合規性有任何疑問，請查閱 [GNU 官網](https://www.gnu.org/licenses/) 或諮詢相關專業人士。

---

## Star 歷史

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/ScriptTools&type=Date)](https://www.star-history.com/#WillemCode/ScriptTools&Date)

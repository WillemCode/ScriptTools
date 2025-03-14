# Nginx プロキシ設定自動化スクリプト

## 概要

このスクリプトは、顧客のドメインの Nginx プロキシ設定ファイルを迅速に生成するために使用され、企業向けのプロキシシナリオに適しています。既存のドメイン設定テンプレートを自動でコピーし、SSL 証明書やリスニングドメインなどの重要なパラメータを変更することで、設定効率を大幅に向上させます。バックエンドサービスは PHP を使用しており、ドメイン名に基づいて顧客のカスタマイズされたページ（LOGO やテキストなど）を動的にロードすることをサポートしています。

---

## 機能

- **ワンクリック設定生成**: 既存のドメイン設定ファイルを基に新しい設定を迅速に生成。
- **SSL 証明書自動化**: `.pem`、`.cer`、`.crt` 形式の SSL 証明書を自動検出して設定。
- **セキュアバックアップ**: 自動で過去の設定ファイルをバックアップし、最近の10件を保持して誤操作を防止。
- **互換性**: CentOS 7+、Ubuntu 16.04+、Alpine などの主流の Linux ディストリビューションに対応。
- **DingTalk 通知統合**: 設定成功後、自動で DingTalk グループに通知を送信（事前に `dingding.sh` の設定が必要）。

---

## システム要件

- **オペレーティングシステム**: Linux（CentOS 7+/Ubuntu 16.04+/Alpine）
- **依存ソフトウェア**: Nginx 1.18+、OpenSSL、Bash 4.0+
- **権限要件**: `root` ユーザーまたは `sudo` 権限を持つユーザーで実行。

---

## インストールと設定

1. **スクリプトのダウンロード**
   サーバーにスクリプトを保存します。統一管理ディレクトリに保存することをお勧めします：
```
mkdir -p /opt/scripts && cd /opt/scripts
git clone https://github.com/WillemCode/ScriptTools.git
cd ScriptTools
chmod +x nginx_config_copy.sh dingding.sh
```

2. **DingTalk 通知の設定（オプション）**

   DingTalk 通知を有効にするには、同じディレクトリに `dingding.sh` を提供し、実行権限が設定されていることを確認してください。

---

## 使用方法

### 操作モードの説明

| モード | コマンド形式 | 説明 |
|--------|--------------|------|
| **モード 1** | `./nginx_config_copy.sh [pem/cer/crt]` | SSL 証明書タイプを指定し、新旧ドメイン名を手動で入力。 |
| **モード 2** | `./nginx_config_copy.sh [pem/cer/crt] [新ドメイン] [旧ドメイン]` | 標準設定モード。ファイルが存在すれば上書き確認が表示されます。 |
| **モード 3** | `./nginx_config_copy.sh [pem/cer/crt] [新ドメイン] [旧ドメイン] force` | 強制上書きモード。確認をスキップして直接置き換えます。 |

### パラメータの詳細

| パラメータ | 必須 | 説明 |
|------------|------|------|
| `pem/cer/crt` | はい | SSL 証明書ファイルの拡張子タイプ。 |
| `新ドメイン` | はい | プロキシ対象の新しいドメイン（例：`www.new.com`）。 |
| `旧ドメイン` | はい | 参照する旧ドメインの設定ファイル（例：`www.old.com`）。 |
| `force` | いいえ | 同名の設定ファイルを強制的に上書き。 |

### 使用例

**例 1：インタラクティブ設定（モード 1）**  
```bash
./nginx_config_copy.sh pem
# 新旧ドメイン名を入力してください
```

**例 2：迅速な設定生成（モード 2）**  
```bash
./nginx_config_copy.sh crt www.client.com www.template.com
```

**例 3：強制上書き設定（モード 3）**  
```bash
./nginx_config_copy.sh cer www.client2024.com www.template.com force
```

---

## 設定ファイルの説明

### 生成されるファイルのパス
- **Nginx 設定**: 自動検出され、デフォルトでは `/etc/nginx/conf.d/` に保存されます（実際の環境により異なる場合があります）。
- **SSL 証明書**: 自動検出され、旧証明書のパスはデフォルトで `/etc/nginx/ssl/` に保存されます。

### PHP 統合
生成された設定ファイル内で、`root` パスは元のドメインと一致し、バックエンド PHP は `$_SERVER['HTTP_HOST']` を通じて現在のドメインを動的に読み込みます。例：
```php
// ドメインに応じて異なる顧客テンプレートを読み込む
$client = $_SERVER['HTTP_HOST'];
include("/var/www/html/clients/$client/header.php");
```

---

## 注意事項

1. **SSL 証明書の準備**  
   - 証明書ファイル（`.key` と指定の拡張子ファイル）をスクリプトの検出パスに配置してください。
   - 証明書ファイル名は `[ドメイン].[拡張子]` の形式で、例えば `www.client.com.pem` です。

2. **バックアップ戦略**  
   - スクリプト実行時に `~/.domainpilot/backups/` に自動バックアップされ、最近の10件が保持されます。

3. **ログ表示**  
   - 実行ログはリアルタイムでターミナルに出力され、エラーメッセージは赤色で表示されます。

---

## 技術サポート

- **問題報告**: [GitHub リポジトリ](https://github.com/WillemCode/ScriptTools/issues)で問題を提出してください。

---

## ライセンス

このプロジェクトは [GNU General Public License (GPL)](./LICENSE) の下で公開されています。

これにより：

- このプロジェクトのソースコードを自由にコピー、修正、配布できますが、変更後のプロジェクトも GPL または互換性のあるライセンスで公開する必要があります；
- 配布または公開時には、元の著作権表示と GPL 契約書を含め、完全なソースコードへのアクセス方法を提供する必要があります。

詳細な条項については [LICENSE](./LICENSE) ファイルをご覧ください。GPL の使用と遵守について質問がある場合は、[GNU のウェブサイト](https://www.gnu.org/licenses/)を参照するか、専門家に相談してください。

---

## Star 歴史

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/ScriptTools&type=Date)](https://www.star-history.com/#WillemCode/ScriptTools&Date)

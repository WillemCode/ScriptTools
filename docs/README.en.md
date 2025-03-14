# Nginx Proxy Configuration Automation Script

## Introduction

This script is used to quickly generate Nginx proxy configuration files for customer domains, suitable for enterprise-level proxy scenarios. By automating the copying of existing domain configuration templates and modifying key parameters such as SSL certificates and listening domains, it significantly improves configuration efficiency. The backend service is based on PHP, and it supports dynamically loading customer-customized pages (such as LOGO, text, etc.) based on domain names.

---

## Features

- **One-Click Configuration Generation**: Quickly generate new configurations based on existing domain configuration files.
- **SSL Certificate Automation**: Automatically detects and configures `.pem`, `.cer`, and `.crt` SSL certificates.
- **Secure Backup**: Automatically backs up historical configuration files, retaining the last 10 backups to prevent errors.
- **Compatibility**: Supports CentOS 7+, Ubuntu 16.04+, and other mainstream Linux distributions.
- **DingTalk Notification Integration**: Automatically sends a notification to DingTalk groups after a successful configuration (requires prior configuration of `dingding.sh`).

---

## System Requirements

- **Operating System**: Linux (CentOS 7+/Ubuntu 16.04+/Alpine)
- **Dependencies**: Nginx 1.18+, OpenSSL, Bash 4.0+
- **Permission Requirements**: Must be run as `root` or a user with `sudo` permissions.

---

## Installation and Configuration

1. **Download the Script**
   Save the script to your server, preferably in a unified management directory:
```
mkdir -p /opt/scripts && cd /opt/scripts
git clone https://github.com/WillemCode/ScriptTools.git
cd ScriptTools
chmod +x nginx_config_copy.sh dingding.sh
```

2. **Configure DingTalk Notifications (Optional)**

   To enable DingTalk notifications, provide the `dingding.sh` script in the same directory and ensure it is executable.

---

## Usage

### Operation Mode Description

| Mode | Command Format | Description |
|------|-----------------|-------------|
| **Mode 1** | `./nginx_config_copy.sh [pem/cer/crt]` | Specify the SSL certificate type and manually enter the new and old domain names. |
| **Mode 2** | `./nginx_config_copy.sh [pem/cer/crt] [new_domain] [old_domain]` | Standard configuration mode. If the file exists, it will prompt for overwriting. |
| **Mode 3** | `./nginx_config_copy.sh [pem/cer/crt] [new_domain] [old_domain] force` | Force overwrite mode, skip confirmation and directly replace. |

### Parameter Explanation

| Parameter | Required | Description |
|-----------|----------|-------------|
| `pem/cer/crt` | Yes | SSL certificate file suffix type. |
| `new_domain` | Yes | The new domain to be proxied (e.g., `www.new.com`). |
| `old_domain` | Yes | The reference old domain configuration file (e.g., `www.old.com`). |
| `force` | No | Force overwrite of the same configuration file. |

### Example Usage

**Example 1: Interactive Configuration (Mode 1)**  
```bash
./nginx_config_copy.sh pem
# Enter new and old domain names as prompted
```

**Example 2: Quick Configuration Generation (Mode 2)**  
```bash
./nginx_config_copy.sh crt www.client.com www.template.com
```

**Example 3: Force Configuration Overwrite (Mode 3)**  
```bash
./nginx_config_copy.sh cer www.client2024.com www.template.com force
```

---

## Configuration File Description

### Generated File Paths
- **Nginx Configuration**: Automatically detected, by default stored in `/etc/nginx/conf.d/` (default, may vary based on the actual environment).
- **SSL Certificates**: Automatically detected, old certificate paths are stored by default in `/etc/nginx/ssl/`.

### PHP Integration
In the generated configuration file, the `root` path is consistent with the original domain, and the backend PHP can dynamically load customer-customized pages via `$_SERVER['HTTP_HOST']`. Example logic:
```php
// Load different customer templates based on the domain
$client = $_SERVER['HTTP_HOST'];
include("/var/www/html/clients/$client/header.php");
```

---

## Notes

1. **SSL Certificate Preparation**  
   - Ensure the certificate files (`.key` and the corresponding suffix files) are placed in the script's detection path (usually the old domain certificate directory).
   - The certificate file should be named `[domain].[suffix]`, for example, `www.client.com.pem`.

2. **Backup Strategy**  
   - Each time the script runs, it automatically backs up to `~/.domainpilot/backups/` and retains the last 10 backups.

3. **Log Viewing**  
   - Execution logs are output in real time to the terminal, with error messages highlighted in red.

---

## Technical Support

- **Issue Reporting**: Please submit issues at the [GitHub Repository](https://github.com/WillemCode/ScriptTools/issues).

---

## License

This project is released under the [GNU General Public License (GPL)](./LICENSE).

This means:

- You are free to copy, modify, and distribute the source code of this project, but the modified project must also be released under the GPL or a compatible license;
- When distributing or publishing, you must include the original copyright notice and the GPL agreement text, and provide access to the full source code.

Please refer to the [LICENSE](./LICENSE) file for detailed terms. If you have any questions about the use and compliance of the GPL, please consult [GNU's website](https://www.gnu.org/licenses/) or seek professional advice.

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=WillemCode/ScriptTools&type=Date)](https://www.star-history.com/#WillemCode/ScriptTools&Date)

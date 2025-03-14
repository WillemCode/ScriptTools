# Nginx 代理配置自动化脚本

## 简介

本脚本用于快速生成客户域名的Nginx代理配置文件，适用于企业级代理场景。通过自动化复制现有域名的配置文件模板，修改SSL证书、监听域名等关键参数，显著提升配置效率。后端服务基于PHP实现，支持根据域名动态加载客户定制化页面（如LOGO、文案等）。

---

## 功能特性

- **一键生成配置**：基于现有域名配置文件快速生成新配置。
- **SSL证书自动化**：支持自动检测并配置`.pem`、`.cer`、`.crt`格式的SSL证书。
- **安全备份**：自动备份历史配置文件，保留最近10份备份，防止误操作。
- **兼容性**：支持CentOS 7+、Ubuntu 16.04+等主流Linux发行版。
- **钉钉通知集成**：配置成功后自动发送通知至钉钉群（需预先配置`dingding.sh`）。

---

## 系统要求

- **操作系统**: Linux（CentOS 7+/Ubuntu 16.04+/Alpine）
- **依赖软件**: Nginx 1.18+、OpenSSL、Bash 4.0+
- **权限要求**: 需以`root`或具有`sudo`权限的用户运行。

---

## 安装与配置

1. **下载脚本**
   将脚本保存至服务器，建议存放于统一管理目录：
   ```````````bash
mkdir -p /opt/scripts && cd /opt/scripts
git clone https://github.com/WillemCode/ScriptTools.git
cd ScriptTools
chmod +x nginx_config_copy.sh dingding.sh
``````

#!/bin/bash
# Script Name: config_script.sh 
# Description: NGINX 自动配置. 证书更换配置.
# Author: wangjinlong
# Date: 2024-05-09
# Version: 5.7

NGINX_BIN=nginx
CURRENT_TIME=$(date "+%Y-%m-%d %T")
PROJECT_NAME="domainpilot"
PROJECT_HOME="$HOME/.${PROJECT_NAME}"
PROJECT_BACKUPS="$PROJECT_HOME/backups"

VERSION() {
    echo "Version 5.7"
    exit 1
}

# 日志函数
log_info() { echo -e "\033[34m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') INFO: $@\033[0m" 1>&2; }
log_error() { echo -e "\033[31m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') ERRO: $@\033[0m" 1>&2; }
log_warning() { echo -e "\033[33m$(date +'[%Y年 %m月 %d日 %A %H:%M:%S %Z]') WARN: $@\033[0m" 1>&2; }

check_command() {
  retu_msg=$1
  info_msg=$2
  erro_msg=$3
  if [ $retu_msg -eq 0 ]; then
    if [[ ! $info_msg == "" ]]; then
      log_info "$info_msg"
    fi
  else
    if [[ ! $erro_msg == "" ]]; then
      log_error "$erro_msg"
      exit 100
    fi
    return 100
  fi
}

USAGE() {
    echo ""
    echo "Usage: "
    echo ""
    echo "bash $0 [OPTION]... [ARG]..."  
    echo "This script does something useful with three main modes of operation."  
    echo ""  
    echo "Modes of operation:"  
    echo "  1. Mode 1: $0 [pem/cer/crt]"  
    echo "     Description: This is the first mode of operation."  
    echo "  2. Mode 2: $0 [pem/cer/crt] [new domain] [old domain]"  
    echo "     Description: This is the second mode of operation."  
    echo "  3. Mode 3: $0 [pem/cer/crt] [new domain] [old domain] [force]"  
    echo "     Description: This is the third mode of operation."  
    echo ""  
    echo "Options:"
    echo "  pem             SSL certificate file suffix is pem: www.baidu.com.pem"
    echo "  cer             SSL certificate file suffix is cer: www.baidu.com.cer"
    echo "  crt             SSL certificate file suffix is crt: www.baidu.com.crt"
    echo "  new domain      New domain names to be deployed, such as: www.new.com"
    echo "  old domain      Which domain name profile to create from, for example: www.old.com"
    echo "  force           Force overwrite deployment if file exists"
    echo ""
    echo "  -h, -help       Display this help message"
    echo "  -v, -version    Display version information"
    echo ""
    exit 1
}

confirm_input() {  
    local input=$1  
    input="$(echo "$input" | tr '[:upper:]' '[:lower:]')"  
    if [[ "$input" == "y" || "$input" == "yes" ]]; then  
        return 0
    else  
        return 1
    fi  
}  

while getopts ":hvw:" option; do
    case ${option} in
        h | -help ) # Display help message
            USAGE
            exit 1
            ;;
        v | -version ) # Display version information
            VERSION
            exit 1
            ;;
        \? ) # Invalid option
            echo "Error: Invalid option -$OPTARG"
            USAGE
            ;;
        : ) # Missing option argument
            echo "Error: Option -$OPTARG requires an argument"
            USAGE
            ;;
    esac
done
shift $((OPTIND -1))
if [[ "$#" -eq 3 ]]; then
    SSL_SUFFIX=$1
    NEW_DOMAIN=$2
    OLD_DOMAIN=$3
elif [[ "$#" -eq 4 ]]; then
    if [ $4 == "force" ]; then
        SSL_SUFFIX=$1
        NEW_DOMAIN=$2
        OLD_DOMAIN=$3
        DOMAIN_FORCE=$4
    else
        USAGE
        exit 1
    fi
elif [[ "$#" -eq 1 ]]; then
    SSL_SUFFIX=$1
else
    USAGE
    exit 1
fi



# 初始化操作系统和Nginx路径
INIT_PARAMS() {
  if [ -f /etc/os-release ]; then
      OS=$(grep 'PRETTY_NAME' /etc/os-release | awk -F '=' '{print $2}' | tr -d '"')
  elif [ -f /etc/redhat-release ]; then
      OS=$(cat /etc/redhat-release)
      # 检查是否为 CentOS 6 或 RHEL 6
      if echo "$OS" | grep -qE "release 6"; then
        echo "抱歉, 当前系统版本 ($OS) 不兼容, 请升级至更高版本. "
        exit 1
      fi
  elif [ -f /etc/alpine-release ]; then
      OS="alpine"
  else
      log_error "抱歉, 暂不支持该操作系统."
      exit 1
  fi

  $NGINX_BIN -V > /dev/null 2>&1
  if [ $? -ne 0 ]; then
      log_info "没有在PATH中找不到nginx, 正在进行查找nginx..."
      pid=$(ps -e | grep nginx | grep -v 'grep' | head -n 1 | awk '{print $1}')
      if [ -n "$pid" ]; then
          NGINX_BIN=$(readlink -f /proc/"$pid"/exe)
          # 再次验证
          $NGINX_BIN -V > /dev/null 2>&1
          if [ $? -eq 0 ]; then
              log_info "Nginx可执行文件路径: $NGINX_BIN"
          else
              log_error "没有检测到Nginx, 请确认已经安装了Nginx."
          fi
      else
        log_error "没有检测到Nginx, 请确认已经安装了Nginx."
        exit 1
      fi
  fi

  if [ -z "$NGINX_CONFIG" ]; then
    NGINX_CONFIG=$(ps -eo pid,cmd | grep nginx | grep master | grep '\-c' | awk -F '-c' '{print $2}' | sed 's/ //g')
  fi

  if [ -z "$NGINX_CONFIG"  ] || [ "$NGINX_CONFIG" = "nginx.conf" ]; then
    NGINX_CONFIG=$($NGINX_BIN -t 2>&1 | grep 'configuration' | head -n 1 | awk -F 'file' '{print $2}' | awk '{print $1}' )
  fi

  if [ -z "$NGINX_CONFIG_HOME" ]; then
    NGINX_CONFIG_HOME=$(dirname "$NGINX_CONFIG")
  fi

  if [ "$NGINX_CONFIG_HOME" = "." ]; then
    log_error "获取nginx配置文件失败."
    exit 1
  fi

}

NG_CONFIG() {
    if [ ! -f "$VHOST_PATH/$OLD_NG_CONF" ]; then
        if [[ $loop == $count ]]; then
            log_error "$OLD_NG_CONF 配置文件不存在, 退出执行."
            exit 100
        fi
    elif [ -f "${VHOST_PATH}/$NEW_NG_CONF" ]; then
        if [ -z "${DOMAIN_FORCE:-}" ]; then
            read -e -p "新的域名配置文件已存在, 是否继续 [y/n]: " TO_CON
            if confirm_input "$TO_CON"; then  
                mv -bf ${VHOST_PATH}/${NEW_NG_CONF}{,-bak_$(date '+%Y%m%d%H%M%S')}
                cp ${VHOST_PATH}/${OLD_NG_CONF} ${VHOST_PATH}/${NEW_NG_CONF}
                sed -i "/root\|proxy/!s#${OLD_DOMAIN}#${NEW_DOMAIN}#g" ${VHOST_PATH}/${NEW_NG_CONF}
            else  
                log_info "配置的新域名虚拟主机配置文件已存在."  
                return
            fi  
        fi
        mv -bf ${VHOST_PATH}/${NEW_NG_CONF}{,-bak_$(date '+%Y%m%d%H%M%S')}
        cp ${VHOST_PATH}/${OLD_NG_CONF} ${VHOST_PATH}/${NEW_NG_CONF}
        sed -i "/root\|proxy/!s#${OLD_DOMAIN}#${NEW_DOMAIN}#g" ${VHOST_PATH}/${NEW_NG_CONF} 
    else
        cp ${VHOST_PATH}/${OLD_NG_CONF} ${VHOST_PATH}/${NEW_NG_CONF}
        sed -i "/root\|proxy/!s#${OLD_DOMAIN}#${NEW_DOMAIN}#g" ${VHOST_PATH}/${NEW_NG_CONF} 
    fi
}

SSL_CONFIG() {
    COUNTER=0
    SSL_PEM_PATH=$(grep "ssl_certificate " ${VHOST_PATH}/${NEW_NG_CONF} | awk -F'[ ;]+' '{print $3}')
    SSL_PATH=$(dirname $SSL_PEM_PATH)
    SSL_FAN_NAME=$(echo ${NEW_DOMAIN#*.})
    for SSL_DOMAIN in "${NEW_DOMAIN}" "${SSL_FAN_NAME}"; do
        if [ ! -f "${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX}" ] && [ ! -f "${SSL_PATH}/${SSL_DOMAIN}.key" ]; then
            if [ -f "${SSL_DOMAIN}.${SSL_SUFFIX}" ] && [ -f "${SSL_DOMAIN}.key" ]; then
                mv ${SSL_DOMAIN}.${SSL_SUFFIX} ${SSL_PATH}
                mv ${SSL_DOMAIN}.key ${SSL_PATH}
                SSL_TYPE=$(openssl x509 -in ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX} -text -noout | awk -F'=' '/Subject: CN.*=/{print $2}')
                SSL_TIME=$(openssl x509 -in ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX} -noout -dates|grep notAfter|awk -F '=' '{print $2}')
                sed -i "s#ssl_certificate .*#ssl_certificate ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX}\;#g" ${VHOST_PATH}/${NEW_NG_CONF} 
                sed -i "s#ssl_certificate_key.*#ssl_certificate_key ${SSL_PATH}/${SSL_DOMAIN}.key\;#g" ${VHOST_PATH}/${NEW_NG_CONF} 
                log_info "检查已修改的配置项..."
                sed -n "/${NEW_DOMAIN}\|${SSL_FAN_NAME}/p" ${VHOST_PATH}/${NEW_NG_CONF}
                break
            else
                if [ "$COUNTER" -eq "1" ]; then
                    sed -i "s#ssl_certificate .*#ssl_certificate ${SSL_PATH}/${NEW_DOMAIN}.${SSL_SUFFIX}\;#g" ${VHOST_PATH}/${NEW_NG_CONF}
                    sed -i "s#ssl_certificate_key.*#ssl_certificate_key ${SSL_PATH}/${NEW_DOMAIN}.key\;#g" ${VHOST_PATH}/${NEW_NG_CONF} 
                    log_info "检查已修改的配置项..."
                    sed -n "/${NEW_DOMAIN}\|${SSL_FAN_NAME}/p" ${VHOST_PATH}/${NEW_NG_CONF}
                    log_error "当前域名的SSL证书文件不存在."
                    log_error "请将域名SSL证书文件上传到该目录: ${SSL_PATH}."
                    exit 100
                fi
            fi
        else
            if [ -f "${SSL_DOMAIN}.${SSL_SUFFIX}" ] && [ -f "${SSL_DOMAIN}.key" ]; then
                end_date=$(openssl x509 -in "${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX}" -noout -enddate | cut -d= -f2)
                end_date_formatted=$(date -d "$end_date" +"%Y-%m-%d")
                end_date_epoch=$(date -d "$end_date" +%s)
                new_data=$(openssl x509 -in "${SSL_DOMAIN}.${SSL_SUFFIX}" -noout -enddate | cut -d= -f2)
                new_data_formatted=$(date -d "$new_data" +"%Y-%m-%d")
                new_date_epoch=$(date -d "$new_data" +%s)
		if [ "$end_date_epoch" -lt "$new_date_epoch" ]; then
                    log_info "正在更新证书..."
                    log_info "当前证书到期时间: $end_date_formatted"
                    log_info "更新证书到期时间: $new_data_formatted"
                    mv ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX} ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX}_${end_date_epoch}
                    mv ${SSL_PATH}/${SSL_DOMAIN}.key ${SSL_PATH}/${SSL_DOMAIN}.key_${end_date_epoch}
                    mv ${SSL_DOMAIN}.${SSL_SUFFIX} ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX}
                    mv ${SSL_DOMAIN}.key ${SSL_PATH}/${SSL_DOMAIN}.key
                    log_info "证书已更换成功."
                    bash dingding.sh "客户证书配置" "\n 🏅 **客户SSL证书更新成功**    \n >  * 🚨 配置日期: ${CURRENT_TIME}  \n >  * 🔞 客户域名: ${NEW_DOMAIN}   \n >  * 🏆 公司域名: ${OLD_DOMAIN}    \n  ---   \n\r\n >  * 🚧 旧证书到期时间: ${end_date_formatted} \n\r\n >  * 🚀 新证书到期时间: ${new_data_formatted} \n\n --- \n ☑️ 到期记得更换哦 😯" "${NEW_DOMAIN}" >/dev/null 2>&1
                else
                    log_warning "当前需要配置证书的到期时间小于--服务器目前使用的证书, 不进行更换证书."
		fi
            fi
            SSL_TYPE=$(openssl x509 -in ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX} -text -noout | awk -F'=' '/Subject: CN.*=/{print $2}')
            SSL_TIME=$(openssl x509 -in ${SSL_PATH}/${SSL_DOMAIN}.${SSL_SUFFIX} -noout -dates|grep notAfter|awk -F '=' '{print $2}')
            break
        fi
        ((COUNTER++))
    done
}

CONFIG_DETAILS() {
    echo "
Configuration details:
------------------------------------------------------------------------------
Current configuration domain NGX CONF: ${NEW_NG_CONF}
Current configuration domain NGX PATH: ${VHOST_PATH}
Current configuration domain SSL TYPE: ${SSL_TYPE}
Current configuration domain SSL TIME: ${SSL_TIME}
Current configuration domain SSL PATH: ${SSL_PATH}
------------------------------------------------------------------------------
"
}

RELOAD_NG() {
    log_info "检查Nginx配置文件: "
    nginx -t
    if [ $? -eq 0 ]; then
        if [ -z "${DOMAIN_FORCE:-}" ]; then
            read -e -p "是否重新加载 Nginx 配置 [ yes/no ]: "  RELOAD_YN
            if confirm_input "${RELOAD_YN}"; then
                service nginx reload
                log_info "已重新加载配置文件..."
            else
                log_warning "未自动加载配置文件, 请手动重新加载 { service nginx reload } ."
            fi
        else
            service nginx reload
            log_info "已重新加载配置文件..."
        fi
    fi
}

BAK_CONFIG() {
    if [ ! -d "${PROJECT_BACKUPS}" ]; then
      mkdir -p "${PROJECT_BACKUPS}" && log_info "创建备份目录 ${PROJECT_BACKUPS} 成功."
    fi
    tar -czPf ${PROJECT_BACKUPS}/ng_vhosts_bak_$(date '+%Y%m%d%H%M%S').tar.gz ${VHOST_PATH}
    check_command $? "配置文件备份成功."  "配置文件备份失败."
    # 保留最近10个最新备份文件，其他的进行删除
    find ${PROJECT_BACKUPS} -type f -name 'ng_vhosts_bak_*.tar.gz' -printf '%T@\t%p\n' | sort -nr | cut -f2- | tail -n +11 | xargs -I {} rm -f "{}"
    check_command $? "清理备份文件成功."  "清理备份文件失败."
    # 保留最近30天最新备份文件，其他的进行删除
    # find ${PROJECT_BACKUPS} -type f -name 'ng_vhosts_bak_*.tar.gz' -mtime +30 -exec rm -f {} \;  
}

main() {
    echo ""
    if [ -z "${NEW_DOMAIN:-}" ] && [ -z "${OLD_DOMAIN:-}" ]; then
        read -e -p "Please Input New Domain :" NEW_DOMAIN
        read -e -p "Please Input Old Domain :" OLD_DOMAIN
    fi
    NEW_NG_CONF="${NEW_DOMAIN}.conf"
    OLD_NG_CONF="${OLD_DOMAIN}.conf"
    INIT_PARAMS

    # 计算匹配到的行数
    loop="0"
    count=$(grep -oP 'include\s+\K.*\*.conf' "$NGINX_CONFIG" | wc -l)

    while IFS= read -r include_path; do
        ((loop++))
        # 如果是绝对路径，则不需要修改
        if [[ "$include_path" == /* ]]; then
            full_path="$include_path"
        else
            # 如果是相对路径，进行拼接
            full_path="$NGINX_CONFIG_HOME/$include_path"
        fi
        # 去掉 *.conf 后缀，获取文件夹路径
        VHOST_PATH=$(dirname "$full_path")
        NG_CONFIG
        SSL_CONFIG
        CONFIG_DETAILS
        BAK_CONFIG
    done < <(grep -oP 'include\s+\K.*\*.conf' "$NGINX_CONFIG")
    NOTICE=$?
    if [ $NOTICE -eq 0 ]; then
        bash dingding.sh "客户NGINX代理配置" "\n 🌺 **配置成功**   \n >  * 🚨 配置日期: ${CURRENT_TIME}  \n >  * 🔞 客户域名: ${NEW_DOMAIN}   \n >  * 🏆 公司域名: ${OLD_DOMAIN}    \n  ---  \n >  * 📋 配置文件: ${NEW_NG_CONF}    \n >  * 📂 主机路径: ${VHOST_PATH}    \n >  * 🔄 到期时间: ${SSL_TIME}    \n >  * 🌐 证书路径: ${SSL_PATH}" "${NEW_DOMAIN}" >/dev/null 2>&1
        RELOAD_NG
    else
        bash dingding.sh "客户NGINX代理配置" "\n 😭 **配置失败**   \n >  * 🚨 配置日期: ${CURRENT_TIME}   \n >  * 🔞 客户域名: ${NEW_DOMAIN}    \n >  * 🏆 公司域名: ${OLD_DOMAIN}" "${NEW_DOMAIN}" >/dev/null 2>&1
    fi
}

main

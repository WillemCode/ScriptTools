#!/bin/bash

CURRENT_TIME=$(date "+%Y-%m-%d %T")
PROJECT_NAME="ScriptTools"
PROJECT_HOME="$HOME/.${PROJECT_NAME}"
DD_TIMESTAMP="${PROJECT_HOME}/timestamp.txt"
DD_TOKEN=""
DD_SECRET=""

if [[ "$#" -eq 3 ]]; then
  TITLE=$1
  MSAGE=$2
  DOMAIN=$3
else
  exit 100
fi

if [ ! -d "$PROJECT_HOME" ]; then
  mkdir -p "$PROJECT_HOME"
fi

echo "" > ${DD_TIMESTAMP}

if command -v python3 &>/dev/null; then
    python3 dingding_timestamp_python3.py $DD_SECRET >>${PROJECT_HOME}/timestamp.txt
elif command -v python2 &>/dev/null; then
    python2 dingding_timestamp_python2.py $DD_SECRET >>${PROJECT_HOME}/timestamp.txt
else
    echo "未找到 python 命令, 无法发送钉钉通知."
    exit 100
fi

time_stamp=$(tail -2 ${PROJECT_HOME}/timestamp.txt | head -1)
sign_secret=$(tail -1 ${PROJECT_HOME}/timestamp.txt)

webhook="https://oapi.dingtalk.com/robot/send?access_token=${DD_TOKEN}&timestamp=${time_stamp}&sign=${sign_secret}"

curl $webhook -H 'Content-Type: application/json' -d "
{
    'msgtype': 'actionCard',
    'actionCard': {
        'text': '### $TITLE  \n  #### [ $CURRENT_TIME ]  \n  $MSAGE',
        'singleTitle': '点击进行访问🔎',
        'singleURL': 'https://$DOMAIN'
    },
    'at': {
        'isAtAll': false
    }
}"

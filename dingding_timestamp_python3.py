# -*- coding: utf-8 -*-
import sys
import time
import hmac
import hashlib
import base64
import urllib.parse

# 获取当前时间戳（毫秒）
timestamp = str(int(round(time.time() * 1000)))

# 密钥
secret = sys.argv[1]
secret_enc = secret.encode('utf-8')

# 要签名的字符串
string_to_sign = '{}\n{}'.format(timestamp, secret).encode('utf-8')

# 创建HMAC对象并获取摘要
hmac_code = hmac.new(secret_enc, string_to_sign, digestmod=hashlib.sha256).digest()

# 对HMAC摘要进行base64编码，并进行URL安全编码
sign = urllib.parse.quote_plus(base64.b64encode(hmac_code).decode('utf-8'))

# 打印结果
print(timestamp)
print(sign)

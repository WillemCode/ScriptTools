# -*- coding: utf-8 -*-
import sys
import time  
import hmac  
import hashlib  
import base64  
import urllib  
  
# 获取当前时间戳（毫秒）  
timestamp = str(int(round(time.time() * 1000)))  
  
# 密钥  
secret = sys.argv[1] 
secret_enc = secret.encode('utf-8')  
  
# 要签名的字符串（注意：在Python 2.7中，字符串和字节串是分开的）  
# 这里我们仍然将timestamp和secret拼接，但需要注意它们都是字节串或都是字符串  
# 由于hmac.new需要字节串作为密钥和消息，我们将它们都转换为字节串  
string_to_sign = '{}\n{}'.format(timestamp, secret).encode('utf-8')  
  
# 创建HMAC对象并获取摘要  
hmac_code = hmac.new(secret_enc, string_to_sign, digestmod=hashlib.sha256).digest()  
  
# 对HMAC摘要进行base64编码，并进行URL安全编码  
# 注意：Python 2.7的urllib.quote_plus函数可以直接用于字节串，但输出将是URL编码的字节串  
# 我们需要将其解码为字符串  
sign = urllib.quote_plus(base64.b64encode(hmac_code)).decode('utf-8')  
  
# 打印结果  
print(timestamp)  
print(sign)

#!/usr/bin/env ruby

require 'qiniu'

# 构建 HTTPS 鉴权对象
Qiniu.establish_https_connection! access_key: 'Access_Key',
                                  secret_key: 'Secret_Key'

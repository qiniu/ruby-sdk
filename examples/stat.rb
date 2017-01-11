#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! :access_key => 'Access_Key',
                            :secret_key => 'Secret_Key'

# 你要测试的空间， 并且这个key在你空间中存在
bucket = 'Bucket_Name'
key = 'ruby-logo.png'

# 获取文件信息
info = Qiniu.stat(
    bucket,     # 存储空间
    key         # 资源名
)
puts info

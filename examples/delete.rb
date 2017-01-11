#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! access_key: 'Access_Key',
                            secret_key: 'Secret_Key'

# 你要测试的空间， 并且这个key在你空间中存在
bucket = 'Bucket_Name'
key = 'ruby-logo.png'

# 删除资源
success = Qiniu.delete(
    bucket,     # 存储空间
    key         # 资源名
)

puts success # 返回布尔值表示是否成功

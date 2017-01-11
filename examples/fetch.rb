#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! access_key: 'Access_Key',
                            secret_key: 'Secret_Key'

# 需要fetch操作保存到的空间名
bucket = 'xxx'
# fetch过来的url，需要外网可以访问到
target_url = 'url'
# 保存到空间的fetch操作的文件名
key = 'xxx'

# 调用fetch方法
success = Qiniu.fetch(
    bucket,
    target_url,
    key
)

puts success # 返回布尔值表示是否成功

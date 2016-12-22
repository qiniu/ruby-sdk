#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! access_key: 'Access_Key',
                            secret_key: 'Secret_Key'

# 你要测试的空间， 并且这个 key 在你空间中存在
bucket = 'Bucket_Name';
key = 'ruby-logo.png';

# 移动到的目标空间名和重命名的 key
dst_bucket = 'dst_bucket'
dst_key = 'dst_key'

# 移动文件
success = Qiniu.move(
    bucket,     # 源存储空间
    key,        # 源资源名
    dst_bucket,     # 目标存储空间
    dst_key         # 目标资源名
)

puts success # 返回布尔值表示是否成功

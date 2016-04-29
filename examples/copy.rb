#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! :access_key => 'Access_Key',
                            :secret_key => 'Secret_Key'

#你要测试的空间， 并且这个key在你空间中存在
bucket = 'Bucket_Name'
key = 'ruby-logo.png'

#复制到的目标空间名和重命名的key
dst_bucket = 'dst_bucket'
dst_key = 'dst_key'

#复制文件
code, result, response_headers = Qiniu::Storage.copy(
    bucket,     # 源存储空间
    key,        # 源资源名
    dst_bucket,     # 目标存储空间
    dst_key         # 目标资源名
)
puts code
puts result
puts response_headers
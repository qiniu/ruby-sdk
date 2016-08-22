#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! :access_key => 'Access_Key',
                            :secret_key => 'Secret_Key'

#你要测试的空间， 并且这个key在你空间中存在
bucket = 'Bucket_Name';
key = 'ruby-logo.png';

#修改MIME Type
new_mime_type = 'aaa'


#移动文件
code, result, response_headers = Qiniu::Storage.chgm(
    bucket,     # 源存储空间
    key,        # 源资源名
    new_mime_type    # 新的 MIME Type
)
#获取文件信息，可以看到已经改变了
code, result, response_headers = Qiniu::Storage.stat(
    bucket,     # 存储空间
    key         # 资源名
)

puts code
puts result
puts response_headers
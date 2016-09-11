#!/usr/bin/env ruby

require 'qiniu'

# 构建鉴权对象
Qiniu.establish_connection! :access_key => 'Access_Key',
                            :secret_key => 'Secret_Key'

#要上传的空间
bucket = 'Bucket_Name'

#上传到七牛后保存的文件名
key = 'my-ruby-logo.png'


#构建上传策略
put_policy = Qiniu::Auth::PutPolicy.new(
    bucket,      # 存储空间
    key,     # 最终资源名，可省略，即缺省为“创建”语义，设置为nil为普通上传
    3600    #token过期时间，默认为3600s
)

#生成上传 Token
uptoken = Qiniu::Auth.generate_uptoken(put_policy)

#要上传文件的本地路径
filePath = './ruby-logo.png'

#调用upload_with_token_2方法上传
code, result, response_headers = Qiniu::Storage.upload_with_token_2(
     uptoken,
     filePath,
     key,
	 nil,
	 :bucket => bucket
)

#打印上传返回的信息
puts code
puts result

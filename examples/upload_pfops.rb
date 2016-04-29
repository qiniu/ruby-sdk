#!/usr/bin/env ruby

require 'qiniu'

# 构建鉴权对象
Qiniu.establish_connection! :access_key => 'Access_Key',
                            :secret_key => 'Secret_Key'

bucket = 'Bucket_Name'

key = 'my-ruby-logo.png'

put_policy = Qiniu::Auth::PutPolicy.new(
    bucket,      # 存储空间
    key,     # 最终资源名，可省略，即缺省为“创建”语义，设置为nil为普通上传 
    3600    #token过期时间，默认为3600s
)

#转码是使用的队列名称。 
pipeline = 'abc' #设定自己账号下的pipleline

#要进行转码的转码操作。 
fops = "avthumb/mp4/s/640x360/vb/1.25m"

#可以对转码后的文件进行使用saveas参数自定义命名，当然也可以不指定文件会默认命名并保存在当间。
saveas_key = Qiniu::Utils.urlsafe_base64_encode(目标Bucket_Name:自定义文件key)
fops = fops+'|saveas/'+saveas_key

put_policy.persistent_ops= fops
put_policy.persistent_pipeline= pipeline

#生成上传 Token
uptoken = Qiniu::Auth.generate_uptoken(put_policy)

#要上传文件的本地路径
filePath = './ruby-logo.png'

#调用upload_with_token_2方法上传
code, result, response_headers = Qiniu::Storage.upload_with_token_2(
     uptoken, 
     filePath,
     key
)

#打印上传返回的信息
puts code
puts result
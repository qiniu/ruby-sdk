#!/usr/bin/env ruby

require 'qiniu'
require 'qiniu/utils'

# 构建鉴权对象
Qiniu.establish_connection! :access_key => 'AK',
                            :secret_key => 'SK'

#要转码的文件所在的空间和文件名。
bucket = 'Bucket_Name'
key = '1.mp4'

#转码所使用的队列名称。 
pipeline = 'abc'

#需要添加水印的图片UrlSafeBase64,可以参考http://developer.qiniu.com/code/v6/api/dora-api/av/video-watermark.html 
base64URL = Qiniu::Utils.urlsafe_base64_encode('http://developer.qiniu.com/resource/logo-2.jpg')  

#水印参数
fops = "avthumb/mp4/wmImage"+base64URL

#可以对转码后的文件进行使用saveas参数自定义命名，当然也可以不指定文件会默认命名并保存在当间。
saveas_key = Qiniu::Utils.urlsafe_base64_encode(目标Bucket_Name:自定义文件key)
fops = fops+'|saveas/'+saveas_key

pfops  = Qiniu::Fop::Persistance::PfopPolicy.new(
    bucket,      # 存储空间
    key,   # 最终资源名，可省略，即缺省为“创建”语义
    fops,
    'www.baidu.com'
)
pfops.pipeline=pipeline

code, result, response_headers = Qiniu::Fop::Persistance.pfop(pfops)
puts code
puts result
puts response_headers
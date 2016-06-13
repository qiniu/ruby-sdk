#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! :access_key => 'xxx',
                            :secret_key => 'xxx'

#需要fetch操作保存到的空间名
bucket = 'xxx'
#fetch过来的url，需要外网可以访问到
target_url = 'url'
#保存到空间的fetch操作的文件名
key = 'xxx'

#调用fetch方法
code, result, response_headers = Qiniu::Storage.fetch(
    bucket,      
    target_url,  
    key          
)

#打印返回的状态码以及信息
puts code
puts result
puts response_headers
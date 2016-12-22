#!/usr/bin/env ruby

require 'qiniu'

# 构建鉴权对象
Qiniu.establish_connection! access_key: 'Access_Key',
                            secret_key: 'Secret_Key'

# 你要测试的list的空间名
bucket = 'xxxx'

# 调用list接口,参数可以参考 http://developer.qiniu.com/code/v6/api/kodo-api/rs/list.html#list-specification
code, result, response_headers, s, d = Qiniu::Storage.list(Qiniu::Storage::ListPolicy.new(
    bucket,   # bucket
    100,      # limit
    'photo/', # prefix
    ''        # delimiter
))

# 打印出返回的状态码和信息
puts code
puts result
puts response_headers

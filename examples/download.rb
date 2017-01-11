#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! access_key: 'Access_Key',
                            secret_key: 'Secret_Key'

# 构建私有空间的链接
primitive_url = 'http://domain/key'
download_url = Qiniu::Auth.authorize_download_url(primitive_url)
puts download_url

# 或者
download_url = Qiniu::Auth.authorize_download_url_2('domain', 'key')
puts download_url

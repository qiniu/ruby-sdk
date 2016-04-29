#!/usr/bin/env ruby

require 'qiniu'

Qiniu.establish_connection! :access_key => 'AK',
                            :secret_key => 'SK'

#构建私有空间的链接
primitive_url = 'http://domain/key'
download_url = Qiniu::Auth.authorize_download_url(primitive_url)
puts download_url
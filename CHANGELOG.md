## CHANGE LOG

### V6.5.1

- 为 Qiniu::Auth 添加验证七牛回调请求签名合法性的函数。[https://github.com/qiniu/ruby-sdk/pull/133](https://github.com/qiniu/ruby-sdk/pull/133)

### v6.5.0

- 为 Qiniu::Auth 添加一个异常处理逻辑，在 Access Key 和 Secret Key 未正常设置（nil 值）的情况下给出正确提示。[https://github.com/qiniu/ruby-sdk/pull/126](https://github.com/qiniu/ruby-sdk/pull/126)

### v6.4.2

- gem 兼容性调整 。 [https://github.com/qiniu/ruby-sdk/pull/122](https://github.com/qiniu/ruby-sdk/pull/122)

- 上传策略参数调整 。 [https://github.com/qiniu/ruby-sdk/pull/120](https://github.com/qiniu/ruby-sdk/pull/120)

### v6.4.1

- 将 mime-types 的依赖版本升级到 2.4.3 。 [https://github.com/qiniu/ruby-sdk/pull/113](https://github.com/qiniu/ruby-sdk/pull/113)

### v6.4.0

- 为 put_with_put_policy() 添加 opts 参数，允许使用 :content_type 键指定上传文件的 mime type。 [https://github.com/qiniu/ruby-sdk/pull/111](https://github.com/qiniu/ruby-sdk/pull/111)

### v6.3.2

- 调整上传host。 [https://github.com/qiniu/ruby-sdk/pull/103](https://github.com/qiniu/ruby-sdk/pull/103)

### v6.3.1

- 为过期方法添加说明。 [https://github.com/qiniu/ruby-sdk/pull/98](https://github.com/qiniu/ruby-sdk/pull/98)
- 修改上传域名。 [https://github.com/qiniu/ruby-sdk/pull/99](https://github.com/qiniu/ruby-sdk/pull/99)
- 增加pfop参数。 [https://github.com/qiniu/ruby-sdk/pull/100](https://github.com/qiniu/ruby-sdk/pull/100)

### v6.3.0

- 添加 authorize_download_url_2 方法，对包含中文或其它 utf-8 字符的 Key 做下载授权。 [https://github.com/qiniu/ruby-sdk/pull/95](https://github.com/qiniu/ruby-sdk/pull/95)

### v6.2.4

- 调整User Agent。 [https://github.com/qiniu/ruby-sdk/pull/94](https://github.com/qiniu/ruby-sdk/pull/94)

### v6.2.3

- 为上传策略添加`persistentPipeline`参数，用于指明使用哪个命名转码队列。  [https://github.com/qiniu/ruby-sdk/pull/93](https://github.com/qiniu/ruby-sdk/pull/93)

### v6.2.2

- 为/pfop接口添加`pipeline`参数，用于指明使用哪个命名转码队列。  [https://github.com/qiniu/ruby-sdk/pull/92](https://github.com/qiniu/ruby-sdk/pull/92)
- 为authorize_download_url()添加`:fop`参数，用于生成含数据处理指令的授权下载URL。

### v6.2.1

- 去除已废弃的publish/unpublish接口。 [https://github.com/qiniu/ruby-sdk/pull/90](https://github.com/qiniu/ruby-sdk/pull/90) (#8143)

### v6.2.0

- 重写与授权相关的函数并归入Qiniu::Auth空间，原授权凭证生成类维持不变。

- 添加Qiniu::Storage::PutPolicy类和Qiniu::Storage#upload_with_put_policy方法，并推荐使用两者组合实现单文件上传。

### v6.1.0

- Qiniu::Storage所有上传接口返回第三个值raw_headers，类型为Hash，包含已解析的HTTP响应报文中的所有Header信息。

该返回值主要用于调试。当遇到难以理解或解释的错误时，请将其中的X-Log和X-Reqid两项信息[通过邮件反馈](mailto:support@qiniu.com?subject=Ruby-SDK-Bug-Report)给我们。

- 更新Qiniu::Storage所有上传接口的测试用例，打印HTTP响应Header信息。

- 删除过时的Qiniu::Storage#put_file方法和相关测试用例。

该方法调用的API已过时并逐步废弃，建议用户尽快迁移到Qiniu::Storage#upload_with_token_2方法上。

### v6.0.1

- 重新划分命名空间，存储相关归入Qiniu::Storage，数据处理相关归入Qiniu::Fop，杂项相关归入Qiniu::Misc。

### v3.4.6

- `Qiniu::RS.generate_download_token()` 方法的 `:pattern` 调整为必选项。

### v3.4.5

- `Qiniu::RS.generate_upload_token()` 方法新增 `:callback_body` 和 `return_url` 选项。
- 选项含义参考: <http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html#put-policy-callback-body>

### v3.4.2

- `Qiniu::RS.generate_upload_token()` 方法新增 `:return_body` 选项。

该选项（`:return_body`）可设置文件上传成功后，执行七牛云存储规定的回调API，并以 JSON 响应格式返回其执行结果。参考 [uploadToken 之 returnBody 说明](http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html#put-policy-return-body)。

### v3.4.1

增加为上传文件进行预转的选项，参见 [uploadToken 之 asyncOps 说明](http://docs.qiniu.com/api/v6/put.html#uploadToken-asyncOps)

- `Qiniu::RS.generate_upload_token()` 方法新增 `:async_options` 选项用于进行预转操作。

### v3.4.0

增加文件复制/移动方法，包括批量复制/移动文件

- `Qiniu::RS.copy(source_bucket, source_key, target_bucket, target_key)`
- `Qiniu::RS.move(source_bucket, source_key, target_bucket, target_key)`
- `Qiniu::RS.batch_copy [source_bucket, source_key, target_bucket, target_key], ...`
- `Qiniu::RS.batch_move [source_bucket, source_key, target_bucket, target_key], ...`

### v3.3.1

确保单元测试里边用到的测试 Bucket 全局唯一

使得10多种不通的 Ruby 宿主环境能隔离互不影响地执行单元/集成测试

Ruby 宿主环境如下

1.8.7, 1.9.2, 1.9.3, jruby-18mode, jruby-19mode, rbx-18mode, rbx-19mode, ruby-head, jruby-head, ree

详见 <https://travis-ci.org/qiniu/ruby-sdk>

### v3.3.0

私有资源下载新版实现，添加 Qiniu::RS.generate_download_token() 方法。参考 [downloadToken](http://developer.qiniu.com/docs/v6/api/reference/security/download-token.html)

详见 [Ruby SDK 使用文档之私有资源下载](http://developer.qiniu.com/docs/v6/api/overview/dn/security.html)

### v3.2.2

fixed E701 error

断点续上传根据 mkblk 返回的 host 字段进行 bput 和 mkfile ，规避由于DNS智能解析造成的分布式并行块上传会出现上下文不连贯导致的 E701 问题。

### v3.2.1

allow images uploaded auto-orient.

允许图片上传成功后自动旋转。

参考：

1. [[API] multipart/form-data 上传文件之 action 字段详解](http://docs.qiniutek.com/v3/api/io/#upload-action)
2. [[SDK] Qiniu::RS.upload_file() 方法中的参数增加了 :rotate 选项](http://docs.qiniutek.com/v3/sdk/ruby/#upload-server-side)

### v3.2.0

2012-11-06

allow files uploaded auto callback some APIs (like imageInfo, exif, etc…), and add those APIs callback results as part of the custom data for POST biz-server.

允许上传文件(图片)成功后执行回调指定的 API (比如 imageInfo, exif 接口等)，并将指定API的回调结果一并 POST 发送给客户方的业务服务器。

参考：

1. [[API] 生成上传授权凭证 uploadToken 之 escape 参数详解](http://docs.qiniutek.com/v3/api/io/#escape-expression)
2. [[SDK] Qiniu::RS.generate_upload_token() 方法中的参数增加了 :escape 选项](http://docs.qiniutek.com/v3/sdk/ruby/#generate-upload-token)

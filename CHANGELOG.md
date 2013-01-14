## CHANGE LOG

### v3.4.1

增加为上传文件进行预转的选项，参见 [uploadToken 之 asyncOps 说明](http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps)

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

私有资源下载新版实现，添加 Qiniu::RS.generate_download_token() 方法。参考 [downloadToken](http://docs.qiniutek.com/v3/api/io/#get)

详见 [Ruby SDK 使用文档之私有资源下载](http://docs.qiniutek.com/v3/sdk/ruby/#download-private-files)

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

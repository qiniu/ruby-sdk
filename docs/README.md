---
title: Ruby SDK 使用指南 | 七牛云存储
---

# Ruby SDK 使用指南

此 Ruby SDK 适用于 Ruby 1.8.x, 1.9.x, jruby, rbx, ree 版本，基于 [七牛云存储官方API](/v3/api/) 构建。使用此 SDK 构建您的网络应用程序，能让您以非常便捷地方式将数据安全地存储到七牛云存储上。无论您的网络应用是一个网站程序，还是包括从云端（服务端程序）到终端（手持设备应用）的架构的服务或应用，通过七牛云存储及其 SDK，都能让您应用程序的终端用户高速上传和下载，同时也让您的服务端更加轻盈。

七牛云存储 Ruby SDK 源码地址：[https://github.com/qiniu/ruby-sdk](https://github.com/qiniu/ruby-sdk)

**文档大纲**

- [安装](#Installation)
- [使用](#Usage)
    - [应用接入](#establish_connection!)
    - [Ruby On Rails 应用初始化设置](#ror-init)
    - [上传文件](#upload)
        - [获取用于上传文件的临时授权凭证](#generate-upload-token)
        - [服务端上传文件](#upload-server-side)
            - [断点续上传](#resumable-upload)
            - [针对 NotFound 场景处理](#upload-file-for-not-found)
        - [客户端直传文件](#upload-client-side)
    - [查看文件属性信息](#stat)
    - [获取文件下载链接（含文件属性信息）](#get)
    - [只获取文件下载链接](#download)
    - [删除指定文件](#delete)
    - [删除所有文件（单个 bucket）](#drop)
    - [批量操作](#batch)
        - [批量获取文件属性信息（含下载链接）](#batch_get)
        - [批量获取文件下载链接](#batch_download)
        - [批量删除文件](#batch_delete)
    - [创建公开外链](#publish)
    - [取消公开外链](#unpublish)
    - [Bucket（资源表）管理](#buckets)
        - [创建 Bucket](#mkbucket)
        - [列出所有 Bucket](#list-all-buckets)
        - [访问控制](#set-protected)
    - [图像处理](#op-image)
        - [查看图片属性信息](#image_info)
        - [查看图片EXIF信息](#image_exif)
        - [获取指定规格的缩略图预览地址](#image_preview_url)
        - [高级图像处理（缩略、裁剪、旋转、转化）](#image_mogrify_preview_url)
        - [高级图像处理（缩略、裁剪、旋转、转化）并持久化](#image_mogrify_save_as)
        - [高级图像处理（水印）](#image-watermarking)
            - [水印准备工作](#watermarking-pre-work)
                - [设置原图保护](#watermarking-set-protected)
                - [设置水印预览图URL分隔符](#watermarking-set-sep)
                - [设置水印预览图规格别名](#watermarking-set-style)
            - [设置水印模板](#watermarking-set-template)
            - [获取水印模板](#watermarking-get-template)

- [贡献代码](#Contributing)
- [许可证](#License)

<a name="Installation"></a>

## 安装

<a name="Usage"></a>

在您 Ruby 应用程序的 `Gemfile` 文件中，添加如下一行代码：

    gem 'qiniu-rs'

然后，在应用程序所在的目录下，可以运行 `bundle` 安装依赖包：

    $ bundle

或者，可以使用 Ruby 的包管理器 `gem` 进行安装：

    $ gem install qiniu-rs


## 使用

<a name="establish_connection!"></a>

### 应用接入

要接入七牛云存储，您需要拥有一对有效的 Access Key 和 Secret Key 用来进行签名认证。可以通过如下步骤获得：

1. [开通七牛开发者帐号](https://dev.qiniutek.com/signup)
2. [登录七牛开发者自助平台，查看 Access Key 和 Secret Key](https://dev.qiniutek.com/account/keys) 。

在获取到 Access Key 和 Secret Key 之后，您可以在您的程序中调用如下两行代码进行初始化对接：

    Qiniu::RS.establish_connection! :access_key => YOUR_APP_ACCESS_KEY,
                                    :secret_key => YOUR_APP_SECRET_KEY

<a name="ror-init"></a>

### Ruby On Rails 应用初始化设置

如果您使用的是 [Ruby on Rails](http://rubyonrails.org/) 框架，我们建议您在应用初始化启动的过程中，依次调用上述两个函数即可，操作如下：

首先，在应用初始化脚本加载的目录中新建一个文件：`YOUR_RAILS_APP/config/initializers/qiniu-rs.rb`

然后，编辑 `YOUR_RAILS_APP/config/initializers/qiniu-rs.rb` 文件内容如下：

    Qiniu::RS.establish_connection! :access_key => YOUR_APP_ACCESS_KEY,
                                    :secret_key => YOUR_APP_SECRET_KEY

这样，您就可以在您的 `RAILS_APP` 中使用七牛云存储 Ruby SDK 提供的其他任意方法了。

接下来，我们会逐一介绍此 SDK 提供的其他方法。

<a name="upload"></a>

### 上传文件

<a name="generate-upload-token"></a>

#### 获取用于上传文件的临时授权凭证

要上传一个文件，首先需要调用 SDK 提供的 `Qiniu::RS.generate_upload_token` 函数来获取一个经过授权用于临时匿名上传的 `upload_token`——经过数字签名的一组数据信息，该 `upload_token` 作为文件上传流中 `multipart/form-data` 的一部分进行传输。

`Qiniu::RS.generate_upload_token` 函数原型如下：

    Qiniu::RS.generate_upload_token :scope              => target_bucket,
                                    :expires_in         => expires_in_seconds,
                                    :callback_url       => callback_url,
                                    :callback_body_type => callback_body_type,
                                    :customer           => end_user_id,
                                    :escape             => allow_upload_callback_api

**参数**

:scope
: 必须，字符串类型（String），设定文件要上传到的目标 `bucket`

:expires_in
: 可选，数字类型，用于设置上传 URL 的有效期，单位：秒，缺省为 3600 秒，即 1 小时后该上传链接不再有效（但该上传URL在其生成之后的59分59秒都是可用的）。

:callback_url
: 可选，字符串类型（String），用于设置文件上传成功后，七牛云存储服务端要回调客户方的业务服务器地址。

:callback_body_type
: 可选，字符串类型（String），用于设置文件上传成功后，七牛云存储服务端向客户方的业务服务器发送回调请求的 `Content-Type`。

:customer
: 可选，字符串类型（String），客户方终端用户（End User）的ID，该字段可以用来标示一个文件的属主，这在一些特殊场景下（比如给终端用户上传的图片打上名字水印）非常有用。

:escape
: 可选，数字类型，可选值 0 或者 1，缺省为 0 。值为 1 表示 callback 传递的自定义数据中允许存在转义符号 `$(VarExpression)`，参考 [VarExpression](/v3/api/words/#VarExpression)。

当 `escape` 的值为 `1` 时，常见的转义语法如下：

- 若 `callbackBodyType` 为 `application/json` 时，一个典型的自定义回调数据（[CallbackParams](/v3/api/io/#CallbackParams)）为：

    `{foo: "bar", w: $(imageInfo.width), h: $(imageInfo.height), exif: $(exif)}`

- 若 `callbackBodyType` 为 `application/x-www-form-urlencoded` 时，一个典型的自定义回调数据（[CallbackParams](/v3/api/io/#CallbackParams)）为：

    `foo=bar&w=$(imageInfo.width)&h=$(imageInfo.height)&exif=$(exif)`

**返回值**

返回一个字符串类型（String）的用于上传文件用的临时授权 `upload_token`。

<a name="upload-server-side"></a>

#### 服务端上传文件

通过 `Qiniu::RS.upload_file()` 方法可在客户方的业务服务器上直接往七牛云存储上传文件。该函数规格如下：

    Qiniu::RS.upload_file :uptoken            => upload_token,
                          :file               => file_path,
                          :bucket             => bucket_name,
                          :key                => record_id,
                          :mime_type          => file_mime_type,
                          :note               => some_notes,
                          :callback_params    => callback_params,
                          :enable_crc32_check => false

**参数**

:uptoken
: 必须，字符串类型（String），调用 `Qiniu::RS.generate_upload_token` 生成的 [用于上传文件的临时授权凭证](#generate-upload-token)

:file
: 必须，字符串类型（String），本地文件可被读取的有效路径

:bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，指定将该数据属性信息存储到具体的资源表中 。

:key
: 必须，字符串类型（String），类似传统数据库里边某个表的主键ID，给每一个文件一个UUID用于进行标示。

:mime_type
: 可选，字符串类型（String），文件的 mime-type 值。如若不传入，SDK 会自行计算得出，若计算失败缺省使用 application/octet-stream 代替之。

:note
: 可选，字符串类型（String），为文件添加备注信息。

:callback_params
: 可选，String 或者 Hash 类型，文件上传成功后，七牛云存储向客户方业务服务器发送的回调参数。

:enable_crc32_check
: 可选，Boolean 类型，是否启用文件上传 crc32 校验，缺省为 false 。

**返回值**

上传成功，返回如下一个 Hash：

    {"hash"=>"FgHk-_iqpnZji6PsNr4ghsK5qEwR"}

上传失败，会抛出 `UploadFailedError` 异常。

<a name="resumable-upload"></a>

##### 断点续上传

无需任何额外改动，SDK 提供的 `Qiniu::RS.upload_file()` 方法缺省支持断点续上传。默认情况下，SDK 会自动启用断点续上传的方式来上传超过 4MB 大小的文件。您也可以在 [应用接入](/v3/sdk/ruby/#establish_connection!) 时通过修改缺省配置来设置该阀值：

    Qiniu::RS.establish_connection! :access_key      => YOUR_APP_ACCESS_KEY,
                                    :secret_key      => YOUR_APP_SECRET_KEY,
                                    :block_size      => 1024*1024*4,
                                    :chunk_size      => 1024*256,
                                    :tmpdir          => Dir.tmpdir + File::SEPARATOR + 'Qiniu-RS-Ruby-SDK',
                                    :enable_debug    => true,
                                    :auto_reconnect  => true,
                                    :max_retry_times => 3

**参数详解**

应用接入初始化时，以下配置参数均为可选：

:block_size
: 整型，指定断点续上传针对大文件所使用的分块大小，缺省为 4MB ，小于该阀值的文件不启用断点续上传。

:chunk_size
: 整型，指定断点续上传每次http请求上传的数据块大小，缺省为 256KB。该设置尽量不要超过实际使用的上行带宽，且不能超过 `:block_size` 定义的值。

:tmpdir
: 字符串类型，指定持久化保存断点续上传进度状态临时文件的目录，缺省放置于操作系统的临时目录中。

:enable_debug
: 布尔值，是否启用调试模式，缺省启用（true），启用后会打印相关日志。该参数 SDK 全局有效。

:auto_reconnect
: 布尔值，指定每次 http 若请求失败是否启用重试，缺省启用（true）。该参数 SDK 全局有效。

:max_retry_times
: 整型，指定每次 http 若请求失败最多可以重试的次数，缺省为3次。该参数 SDK 全局有效。


<a name="upload-file-for-not-found"></a>

##### 针对 NotFound 场景处理

您可以上传一个应对 HTTP 404 出错处理的文件，当您 [创建公开外链](#publish) 后，若公开的外链找不到该文件，即可使用您上传的“自定义404文件”代替之。要这么做，您只须使用 `Qiniu::RS.upload_file` 函数上传一个 `key` 为固定字符串类型的值 `errno-404` 即可。

除了使用 SDK 提供的方法，同样也可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](https://github.com/qiniu/devtools/tags) 达到同样的目的：

    qboxrsctl put <Bucket> <Key> <LocalFile>

将其中的 `<Key>` 换作  `errno-404` 即可。

注意，每个 `<Bucket>` 里边有且只有一个 `errno-404` 文件，上传多个，最后的那一个会覆盖前面所有的。

<a name="upload-client-side"></a>

#### 客户端直传文件

客户端上传流程和服务端上传类似，差别在于：客户端直传文件所需的 `upload_token` 可以选择在客户方的业务服务器端生成，也可以选择在客户方的客户端程序里边生成。选择前者，可以和客户方的业务揉合得更紧密和安全些，比如防伪造请求。

简单来讲，客户端上传流程也分为两步：

1. 获取 `upload_token`（[用于上传文件的临时授权凭证](#generate-upload-token)）
2. 将该 `upload_token` 作为文件上传流 `multipart/form-data` 中的一部分实现上传操作

如果您的网络程序是从云端（服务端程序）到终端（手持设备应用）的架构模型，且终端用户有使用您移动端App上传文件（比如照片或视频）的需求，可以把您服务器得到的此 `upload_token` 返回给手持设备端的App，然后您的移动 App 可以使用 [七牛云存储 Objective-SDK （iOS）](http://docs.qiniutek.com/v3/sdk/objc/) 或 [七牛云存储 Android-SDK](http://docs.qiniutek.com/v3/sdk/android/) 的相关上传函数或参照 [七牛云存储API之文件上传](http://docs.qiniutek.com/v3/api/io/#upload) 直传文件。这样，您的终端用户即可把数据（比如图片或视频）直接上传到七牛云存储服务器上无须经由您的服务端中转，而且在上传之前，七牛云存储做了智能加速，终端用户上传数据始终是离他物理距离最近的存储节点。当终端用户上传成功后，七牛云存储服务端会向您指定的 `callback_url` 发送回调数据。如果 `callback_url` 所在的服务处理完毕后输出 `JSON` 格式的数据，七牛云存储服务端会将该回调请求所得的响应信息原封不动地返回给终端应用程序。


<a name="stat"></a>

### 查看文件属性信息

    Qiniu::RS.stat(bucket, key)

可以通过 SDK 提供的 `Qiniu::RS.stat` 函数，来查看某个已上传文件的属性信息。

**参数**

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

key
: 必须，字符串类型（String），类似传统数据库里边某个表的主键ID，每一个文件最终都用一个唯一 `key` 进行标示。

**返回值**

如果请求失败，返回 `false`；否则返回如下一个 `Hash` 类型的结构：

    {
        "fsize"    => 3053,
        "hash"     => "Fu9lBSwQKbWNlBLActdx8-toAajv",
        "mimeType" => "application/x-ruby",
        "putTime"  => 13372775859344500
    }

fsize
: 表示文件总大小，单位是 Byte

hash
: 文件的特征值，可以看做是基版本号

mimeType
: 文件的 mime-type

putTime
: 上传时间，单位是 百纳秒

<a name="get"></a>

### 获取文件下载链接（含文件属性信息）

    Qiniu::RS.get(bucket, key, save_as = nil, expires_in = nil, version = nil)

`Qiniu::RS.get` 函数除了能像 `Qiniu::RS.stat` 一样返回文件的属性信息外，还能返回具体的下载链接及其有效时间。

**参数**

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

key
: 必须，字符串类型（String），类似传统数据库里边某个表的主键ID，每一个文件最终都用一个唯一 `key` 进行标示。

save_as
: 可选，字符串类型（String），文件下载时保存的具体名称

expires_in
: 可选，整型，用于设置下载 URL 的有效期，单位：秒，缺省为 3600 秒

version
: 可选，字符串类型（String），值为 `Qiniu::RS.stat` 或 `Qiniu::RS.get` 函数返回的 `hash` 字段的值，可用于断点续下载。

**返回值**

如果请求失败，返回 `false`；否则返回如下一个 `Hash` 类型的结构：

    {
        "fsize"    => 3053,
        "hash"     => "Fu9lBSwQKbWNlBLActdx8-toAajv",
        "mimeType" => "application/x-ruby",
        "url"      => "http://iovip.qbox.me/file/<an-authorized-token>",
        "expires"  => 3600
    }

fsize
: 表示文件总大小，单位是 Byte

hash
: 文件的特征值，可以看做是基版本号

mimeType
: 文件的 mime-type

url
: 文件的临时有效下载链接

expires
: 文件下载链接的有效期，单位为 秒，过了 `expires` 秒之后，下载 `url` 将不再有效

<a name="download"></a>

### 只获取文件下载链接

    Qiniu::RS.download(bucket, key, save_as = nil, expires_in = nil, version = nil)

`Qiniu::RS.download` 函数参数与 `Qiniu::RS.get` 一样，差别在于，`Qiniu::RS.download` 只返回文件的下载链接。

<a name="delete"></a>

### 删除指定文件

    Qiniu::RS.delete(bucket, key)

`Qiniu::RS.delete` 函数提供了从指定的 `bucket` 中删除指定的 `key`，即删除 `key` 索引关联的具体文件。

**参数**

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

key
: 必须，字符串类型（String），类似传统数据库里边某个表的主键ID，每一个文件最终都用一个唯一 `key` 进行标示。

**返回值**

如果删除成功，返回 `true`，否则返回 `false` 。

<a name="drop"></a>

### 删除所有文件（单个 bucket）

    Qiniu::RS.drop(bucket)

`Qiniu::RS.drop` 提供了删除整个 `bucket` 及其里边的所有 `key`，以及这些 `key` 关联的所有文件都将被删除。

**参数**

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

**返回值**

如果删除成功，返回 `true`，否则返回 `false` 。

<a name="batch"></a>

### 批量操作

    Qiniu::RS.batch(command, bucket, keys)

SDK 还提供了 `Qiniu::RS.batch` 函数来提供批量处理 `Qiniu::RS.stat` 或是 `Qiniu::RS.get` 或 `Qiniu::RS.delete` 的相应功能。

**参数**

command
: 必须，字符串类型（String），其值可以是 `stat`, `get`, `delete` 中的一种

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

keys
: 必须，数组类型（Array），所要操作 `key` 的集合。

**返回值**

如果请求失败，返回 `false`，否则返回一个 `Array` 类型的结构，其中每个元素是一个 `Hash` 类型的结构。例如批量`get`：

    [
        {
            "code" => 200,
            "data" => {
                "expires"  => 3600,
                "fsize"    => 3053,
                "hash"     => "Fu9lBSwQKbWNlBLActdx8-toAajv",
                "mimeType" => "application/x-ruby",
                "url"      => "http://iovip.qbox.me/file/<an-authorized-token>"
            }
        },
        ...
    ]

<a name="batch_get"></a>

#### 批量获取文件属性信息（含下载链接）

    Qiniu::RS.batch_get(bucket, keys)

`Qiniu::RS.batch_get` 函数是在 `Qiniu::RS.batch` 之上的封装，提供批量获取文件属性信息（含下载链接）的功能。

**参数**

bucket
: 必须，字符串类型（String），类似传统数据库里边的表名称，我们暂且将其叫做“资源表”，每份数据是属性信息都存储到具体的 bucket（资源表）中 。

keys
: 必须，数组类型（Array），所要操作 `key` 的集合。

**返回值**

如果请求失败，返回 `false`，否则返回一个 `Array` 类型的结构，其中每个元素是一个 `Hash` 类型的结构。`Hash` 类型的值同 `Qiniu::RS.get` 函数的返回值类似，只多出一个 `code` 字段，`code` 为 200 表示所有 keys 全部获取成功，`code` 若为 298 表示部分获取成功。

    [
        {
            "code" => 200,
            "data" => {
                "expires"  => 3600,
                "fsize"    => 3053,
                "hash"     => "Fu9lBSwQKbWNlBLActdx8-toAajv",
                "mimeType" => "application/x-ruby",
                "url"      => "http://iovip.qbox.me/file/<an-authorized-token>"
            }
        },
        ...
    ]

<a name="batch_download"></a>

#### 批量获取文件下载链接

    Qiniu::RS.batch_download(bucket, keys)

`Qiniu::RS.batch_download` 函数也是在 `Qiniu::RS.batch` 之上的封装，提供批量获取文件下载链接的功能。

参数同 `Qiniu::RS.batch_get` 的参数一样。

**返回值**

如果请求失败，返回 `false`，否则返回一个 `Array` 类型的结构，其中每个元素是一个字符串类型的下载链接：

    ["<download-link-1>", "<download-link-2>", …, "<download-link-N>"]

<a name="batch_delete"></a>

#### 批量删除文件

    Qiniu::RS.batch_delete(bucket, keys)

`Qiniu::RS.batch_download` 函数也是在 `Qiniu::RS.batch` 之上的封装，提供批量删除文件的功能。

参数同 `Qiniu::RS.batch_get` 的参数一样。

**返回值**

如果批量删除成功，返回 `true` ，否则为 `false` 。

<a name="publish"></a>

### 创建公开外链

    Qiniu::RS.publish(domain, bucket)

调用 `Qiniu::RS.publish` 函数可以将您在七牛云存储中的资源表 `bucket` 发布到某个 `domain` 下，`domain` 需要在 DNS 管理里边 CNAME 到 `iovip.qbox.me` 。

这样，用户就可以通过 `http://<domain>/<key>` 来访问资源表 `bucket` 中的文件。键值为 `foo/bar/file` 的文件对应访问 URL 为 `http://<domain>/foo/bar/file`。 另外，`domain` 可以是一个真实的域名，比如 `www.example.com`，也可以是七牛云存储的二级路径，比如 `iovip.qbox.me/example` 。

例如：执行 `Qiniu::RS.publish("cdn.example.com", "EXAMPLE_BUCKET")` 后，那么键名为 `foo/bar/file` 的文件可以通过 `http://cdn.example.com/foo/bar/file` 访问。

**参数**

domain
: 必须，字符串类型（String），资源表发布的目标域名，例如：`cdn.example.com`

bucket
: 必须，字符串类型（String），要公开发布的资源表名称。

**返回值**

如果发布成功，返回 `true`，否则返回 `false` 。

<a name="unpublish"></a>

### 取消公开外链

    Qiniu::RS.unpublish(domain)

可以通过 SDK 提供的 `Qiniu::RS.unpublish` 函数来取消指定 `bucket` 的在某个 `domain` 域下的所有公开外链访问。

**参数**

domain
: 必须，字符串类型（String），资源表已发布的目标域名名称，例如：`cdn.example.com`

**返回值**

如果撤销成功，返回 `true`，否则返回 `false` 。

<a name="buckets"></a>

### Bucket（资源表）管理

<a name="mkbucket"></a>

#### 创建 Bucket

    Qiniu::RS.mkbucket(bucket_name)

可以通过 SDK 提供的 `Qiniu::RS.mkbucket` 函数创建一个 bucket（资源表）。

**参数**

bucket_name
: 必须，字符串类型（String），资源表 bucket 的名称。

**返回值**

如果指定 bucket 创建成功，返回 `true`，否则返回 `false` 。

<a name="list-all-buckets"></a>

#### 列出所有 Bucket

    Qiniu::RS.buckets

可以通过 SDK 提供的 `Qiniu::RS.buckets` 函数列出当前登录客户的所有 buckets（资源表）。

**返回值**

如果请求成功，返回一个 buckets 的列表（Array），否则返回 `false` 。

    ["Bucket1", "Bucket2", …, "BucketN"]

<a name="set-protected"></a>

#### 访问控制

    Qiniu::RS.set_protected(bucket_name, protected_mode)

可以通过 SDK 提供的 `Qiniu::RS.set_protected` 函数来设置指定 bucket 的访问属性，一般在水印处理时作原图保护用。

**参数**

bucket_name
: 必须，字符串类型（String），指定资源表 bucket 的名称。

protected_mode
: 必须，整型，值为 1 或者 0，值为 1 表示启用保护模式，反之亦然。

该函数不常用，一般在特殊场景下会用到。比如给图片打水印时，首先要设置原图保护，禁用公开的图像处理操作，采用水印的特殊图像处理，而保护原图就可以通过该函数操作实现。

**返回值**

如果设置成功，返回 `true`，否则返回 `false` 。


<a name="op-image"></a>

### 图像处理

<a name="image_info"></a>

#### 查看图片属性信息

    Qiniu::RS.image_info(url)

使用 SDK 提供的 `Qiniu::RS.image_info` 方法，可以基于一张存储于七牛云存储服务器上的图片，针对其下载链接来获取该张图片的属性信息。

**参数**

url
: 必须，字符串类型（String），图片的下载链接，需是 `Qiniu::RS.get`（或`Qiniu::RS.batch_get`）函数返回值中 `url` 字段的值，或者是 `Qiniu::RS.download`（或`Qiniu::RS.batch_download`）函数返回的下载链接。且文件本身必须是图片。

**返回值**

如果请求失败，返回 `false`；否则，返回如下一个 `Hash` 类型的结构：

    {
        "format"     => "jpeg",
        "width"      => 640,
        "height"     => 425,
        "colorModel" => "ycbcr"
    }

format
: 原始图片类型

width
: 原始图片宽度，单位像素

height
: 原始图片高度，单位像素

colorModel
: 原始图片着色模式

<a name="image_exif"></a>

#### 查看图片EXIF信息

    Qiniu::RS.image_exif(url)

使用 SDK 提供的 `Qiniu::RS.image_exif` 方法，可以基于一张存储于七牛云存储服务器上的原始图片图片，取到该图片的  EXIF 信息。

**参数**

url
: 必须，字符串类型（String），原图的下载链接，需是 `Qiniu::RS.get`（或`Qiniu::RS.batch_get`）函数返回值中 `url` 字段的值，或者是 `Qiniu::RS.download`（或`Qiniu::RS.batch_download`）函数返回的下载链接。且文件本身必须是图片。

**返回值**

如果参数 `url` 所代表的图片没有 EXIF 信息，返回 `false`。否则，返回一个包含 EXIF 信息的 Hash 结构。


<a name="image_preview_url"></a>

#### 获取指定规格的缩略图预览地址

    Qiniu::RS.image_preview_url(url, spec)

使用 SDK 提供的 `Qiniu::RS.image_preview_url` 方法，可以基于一张存储于七牛云存储服务器上的图片，针对其下载链接，以及指定的缩略图规格类型，来获取该张图片的缩略图地址。

**参数**

url
: 必须，字符串类型（String），图片的下载链接，需是 `Qiniu::RS.get`（或`Qiniu::RS.batch_get`）函数返回值中 `url` 字段的值，或者是 `Qiniu::RS.download`（或`Qiniu::RS.batch_download`）函数返回的下载链接。且文件本身必须是图片。

spec
: 可选，字符串或整型的枚举值，指定缩略图的具体规格，参考 [七牛云存储API之缩略图预览](/v3/api/foimg/#fo-imagePreview) 和 [自定义缩略图规格](/v3/api/foimg/#fo-imagePreviewEx) 。该值缺省为 0 （即输出宽800px高600px图片质量为85的缩略图）

**返回值**

返回一个字符串类型的缩略图 URL



<a name="image_mogrify_preview_url"></a>

#### 高级图像处理（缩略、裁剪、旋转、转化）

`Qiniu::RS.image_mogrify_preview_url()` 方法支持将一个存储在七牛云存储的图片进行缩略、裁剪、旋转和格式转化处理，该方法返回一个可以直接预览缩略图的URL。

    image_mogrify_preview_url = Qiniu::RS.image_mogrify_preview_url(source_image_url, mogrify_options)

**参数**

source_image_url
: 必须，字符串类型（string），指定原始图片的下载链接，可以根据 rs.get() 获取到。

mogrify_options
: 必须，Hash Map 格式的图像处理参数。

`mogrify_options` 对象具体的规格如下：

    mogrify_options = {
        :thumbnail => <ImageSizeGeometry>,
        :gravity => <GravityType>, =NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast
        :crop => <ImageSizeAndOffsetGeometry>,
        :quality => <ImageQuality>,
        :rotate => <RotateDegree>,
        :format => <DestinationImageFormat>, =jpg, gif, png, tif, etc.
        :auto_orient => <TrueOrFalse>
    }

`Qiniu::RS.image_mogrify_preview_url()` 方法是对七牛云存储图像处理高级接口的完整包装，关于 `mogrify_options` 参数里边的具体含义和使用方式，可以参考文档：[图像处理高级接口](/v3/api/foimg/#fo-imageMogr)。

**返回值**

返回一个可以预览最终缩略图的URL，String 类型。


<a name="image_mogrify_save_as"></a>

#### 高级图像处理（缩略、裁剪、旋转、转化）并持久化存储处理结果

`Qiniu::RS.image_mogrify_save_as()` 方法支持将一个存储在七牛云存储的图片进行缩略、裁剪、旋转和格式转化处理，并且将处理后的缩略图作为一个新文件持久化存储到七牛云存储服务器上，这样就可以供后续直接使用而不用每次都传入参数进行图像处理。

    result = Qiniu::RS.image_mogrify_save_as(target_bucket, target_key, src_img_url, mogrify_options)

**参数**

target_bucket
: 必须，字符串类型（string），指定最终缩略图要存放的 bucket 。

target_key
: 必须，字符串类型（string），指定最终缩略图存放在云存储服务端的唯一文件ID。

src_img_url
: 必须，字符串类型（string），指定原始图片的下载链接，可以根据 rs.get() 获取到。

mogrify_options
: 必须，Hash Map 格式的图像处理参数。

`mogrify_options` 对象具体的规格如下：

    mogrify_options = {
        :thumbnail => <ImageSizeGeometry>,
        :gravity => <GravityType>, =NorthWest, North, NorthEast, West, Center, East, SouthWest, South, SouthEast
        :crop => <ImageSizeAndOffsetGeometry>,
        :quality => <ImageQuality>,
        :rotate => <RotateDegree>,
        :format => <DestinationImageFormat>, =jpg, gif, png, tif, etc.
        :auto_orient => <TrueOrFalse>
    }

`Qiniu::RS::Image.mogrify_preview_url()` 方法是对七牛云存储图像处理高级接口的完整包装，关于 `mogrify_options` 参数里边的具体含义和使用方式，可以参考文档：[图像处理高级接口](/v3/api/foimg/#fo-imageMogr)。

**返回值**

如果请求失败，返回 `false`；否则，返回如下一个 `Hash` 类型的结构：

    {"hash" => "FrOXNat8VhBVmcMF3uGrILpTu8Cs"}

示例代码：

    data = Qiniu::RS.get("<test_image_bucket>", "<test_image_key>")
    src_img_url = data["url"]

    target_bucket = "test_thumbnails_bucket"
    target_key = "cropped-" + @test_image_key

    mogrify_options = {
      :thumbnail => "!120x120r",
      :gravity => "center",
      :crop => "!120x120a0a0",
      :quality => 85,
      :rotate => 45,
      :format => "jpg",
      :auto_orient => true
    }

    result = Qiniu::RS.image_mogrify_save_as(target_bucket, target_key, src_img_url, mogrify_options)
    if result
      thumbnail = Qiniu::RS.get(target_bucket, target_key)
      puts thumbnail["url"]

      # 您可以选择将存放缩略图的 bucket 公开，这样就可以直接以外链的形式访问到缩略图，而不用走API获取下载URL。
      result = Qiniu::RS.publish("pic.example.com", target_bucket)

      # 然后将 pic.example.com CNAME 到 iovip.qbox.me ，就可以直接以如下方式访问缩略图
      # [GET] http://pic.example.com/<target_key>
    end


<a name="image-watermarking"></a>

## 高级图像处理（水印）

<a name="watermarking-pre-work"></a>

### 水印准备工作

为了保护用户原图和方便用户访问打过水印之后的图片，在经水印作用之前，需进行以下一些设置：

1. [设置原图保护](#watermarking-set-protected)
2. [设置水印预览图URL分隔符](#watermarking-set-sep)
3. [设置水印预览图规格别名](#watermarking-set-style)

<a name="watermarking-set-protected"></a>

#### 1. 设置原图保护

用户的图片打上水印后，其原图不可见。通过给原图所在的 Bucket（资源表）设置访问控制，可以达到保护原图的目的，详情请参考 [Bucket（资源表）管理之访问控制](set-protected)。

设置原图保护也可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](https://github.com/qiniu/devtools/tags) 来实现：

    // 为<Bucket>下面的所有图片设置原图保护
    qboxrsctl protected <Bucket> <Protected>

<a name="watermarking-set-sep"></a>

#### 2. 设置水印预览图URL分隔符

没有设置水印前，用户可以通过如下公开链接的形式访问原图（[创建公开外链后的情况下](/v3/api/io/#rs-Publish)）：

    http://<Domain>/<Key>

设置水印后，其原图属性为私有，不能再通过这种形式访问。但是用户可以在原图的 `<Key>` 后面加上“分隔符”，以及相应的水印风格样式来访问打水印后的图片。例如，假设您为用户设定的访问水印图的分隔符为中划线 “-”，那么用户可以通过这种形式来访问打水印后的图片：

    http://<Domain>/<Key>-/imageView/<Mode>/w/<Width>/h/<Height>/q/<Quality>/format/<Format>/sharpen/<Sharpen>/watermark/<HasWatermark>

其中，`HasWatermark` 参数为 `0` （或者没有）表示不打水印，为 `1` 表示给图片打水印。

通过 SDK 提供的 `Qiniu::RS.set_separator` 函数可以设置水印预览图URL分隔符：

    Qiniu::RS.set_separator(bucket_name, separator)

**参数**

bucket_name
: 必须，字符串类型（String），图片所在的 Bucket（资源表） 名称

separator
: 必须，字符串类型（String），源图片与预览图规格之间的分割符

**返回值**

操作成功返回 `true`，否则返回 `false`。

除了使用 SDK 提供的方法，同样可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](https://github.com/qiniu/devtools/tags) 达到同样的目的：

    // 设置预览图分隔符
    qboxrsctl separator <Bucket> <Sep>

<a name="watermarking-set-style"></a>

#### 3. 设置水印预览图规格别名

通过步骤2中所描述的水印预览图 URL 来访问打水印后的图片毕竟较为繁琐，因此可以通过为该水印预览图规格设置“别名”的形式来访问。如：

别名（Name） | 规格（Style） | 说明
----------- | ------------ | -------
small.jpg   | imageView/0/w/120/h/90 | 大小为 120x90，不打水印
middle.jpg  | imageView/0/w/440/h/330/watermark/1 | 大小为 440x330，打水印
large.jpg   | imageView/0/w/1280/h/760/watermark/1 | 大小为 1280x760，打水印


SDK 提供了 `Qiniu::RS.set_style` 函数可以定义预览图规格别名，该函数原型如下：

    Qiniu::RS.set_style(bucket, name, style)

**参数**

bucket
: 必须，字符串类型（String），图片所在的 Bucket（资源表） 名称

name
: 必须，字符串类型（String），预览图规格名称（别名）

style
: 必须，字符串类型（String），具体的规格样式

**返回值**

操作成功返回 `true`，否则返回 `false` 。

除了使用 SDK 提供的方法，同样也可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](https://github.com/qiniu/devtools/tags) 达到同样的目的：

    // 为 <Buecket> 下面的所有图片设置名为 <Name> 的 <Style>
    qboxrsctl style <Bucket> <Name> <Style>

无论是通过 SDK 提供的方法还是命令行辅助工具操作，在设置完成后，即可通过通过以下方式来访问设定规格后的图片：

	// 其中 “-” 为分隔符，“small.jpg” 为预览图规格别名
	[GET] http://<Domain>/<Key>-small.jpg

	// 其中 “!” 为分隔符，“middle.jpg” 为预览图规格别名
	[GET] http://<Domain>/<Key>!middle.jpg

	// 其中 “@” 为分隔符，“large.jpg” 为预览图规格别名
    [GET] http://<Domain>/<Key>@large.jpg

以上这些设置水印模板前的准备只需操作一次，即可对后续设置的所有水印模板生效。由于是一次性操作，建议使用 qboxrsctl 命令行辅助工具进行相关设置。

**取消水印预览图规格设置**

您也可以为某个水印预览图规格取消“别名”设置，SDK 提供了相应的方法：

    Qiniu::RS.unset_style(bucket, name)

**参数**

bucket
: 必须，字符串类型（String），图片所在的 Bucket（资源表） 名称

name
: 必须，字符串类型（String），预览图规格名称（别名）

**返回值**

操作成功返回 `true`，否则返回 `false` 。

除了使用 SDK 提供的方法，同样也可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](https://github.com/qiniu/devtools/tags) 达到同样的目的：

    // 取消预览图规格别名为 <Name> 的 Style
    qboxrsctl unstyle <Bucket> <Name>


<a name="watermarking-set-template"></a>

### 设置水印模板

给图片加水印，SDK 提供了设置水印模板的函数：`Qiniu::RS.set_watermark` ，通过该函数操作，客户方可以设置通用的水印模板，也可以为客户方的每一个终端用户分别设置一个水印模板。

`Qiniu::RS.set_watermark` 函数原型如下：

    Qiniu::RS.set_watermark(customer_id, {
        :font     => <FontName>,
        :fontsize => <FontSize>,
        :fill     => <FillColor>,
        :text     => <WatermarkText>,
        :bucket   => <LogoBucket>,
        :dissolve => <Dissolve>,
        :gravity  => <Gravity>,
        :dx       => <DistanceX>,
        :dy       => <DistanceY>
    })

**参数**：

1. `customer_id = <EndUserID>`
: 客户方终端用户标识。如果`customer_id`为 `nil`，则表示设置默认水印模板。作为面向终端用户的服务提供商，您可以为不同的用户设置不同的水印模板，只需在设置水印模板的时候传入`customer_id`参数。如果该参数未设置，则表示为终端用户设置一个默认模板。举例：假如您为终端用户提供的是一个手机拍照软件，用户拍照后图片存储于七牛云存储服务器。为了给每个用户所上传的图片打上标有该用户用户名的水印，您可以为该用户设置一个水印模板，其水印文字可以是该终端用户的用户名。但如果您未给该终端用户设置模板，那么水印上的所有设置都是默认的（其文字部分可能是你们自己设置的企业标识）。该 `customer_id` 和 [Qiniu::RS.generate_upload_token](#generate-upload-token) 中的 `customer` 参数含义一致，结合这点，您很容易想明白为什么 `Qiniu::RS.generate_upload_token` 函数中会有 `customer` 这个可选参数还有 `Qiniu::RS.set_watermark` 函数中会有 `customer_id` 参考以及两者间的关系。

2. `:font => <FontName>`
: 为水印上的文字设置一个默认的字体名，可选。

3. `:fontsize => <FontSize>`
: 字体大小，可选，0表示默认，单位: 缇，等于 1/20 磅。

4. `:fill => <FillColor>`
: 字体颜色，可选。

5. `:text => <WatermarkText>`
: 水印文字，必须，图片用 \0 - \9 占位。

6. `:bucket => <ImageFromBucket>`
: 如果水印中有图片，需要指定图片所在的 `RS Bucket` 名称，可选。

7. `:dissolve => <Dissolve>`
: 透明度，可选，字符串，如50%。

8. `:gravity => <Gravity>`
: 位置，可选，字符串，默认为右下角（SouthEast）。可选的值包括：NorthWest、North、NorthEast、West、Center、East、SouthWest、South和SouthEast。

9. `:dx => <DistanceX>`
: 横向边距，可选，默认值为10，单位px。

10. `:dy => <DistanceY>`
: 纵向边距，可选，默认值为10，单位px。

**返回值**

操作成功返回 `true`，否则返回 `false` 。


<a name="watermarking-get-template"></a>

### 获取水印模板

SDK 提供了 `Qiniu::RS.get_watermark` 函数获取指定终端用户或者缺省的水印模板。该函数原型如下：

    Qiniu::RS.get_watermark(customer_id = nil)

**参数**

customer_id
: 客户方终端用户标识，可选，字符串类型，含义同 [Qiniu::RS.set_watermark](#watermarking-set-template) 函数中的 `customer_id` 参数。该值缺省为 `nil`，如果该值为 `nil`，则表示取默认的通用水印模板。

**返回值**

如果请求成功，返回如下一段 Hash 结构的数据；否则返回 `false`。

    {
    	font: <FontName>
    	fontsize: <FontSize>
    	fill: <FillColor>
    	text: <WatermarkText>
    	bucket: <LogoBucket>
    	dissolve: <Dissolve>
    	gravity: <Gravity>
    	dx: <DistanceX>
    	dy: <DistanceY>
    }

请求成功后返回数据的含义同 [设置水印模板](#watermarking-set-template) 时传入的参数一致。


<a name="Contributing"></a>

## 贡献代码

七牛云存储 Ruby SDK 源码地址：[https://github.com/qiniu/ruby-sdk](https://github.com/qiniu/ruby-sdk)

1. 登录 [github.com](https://github.com)
2. Fork [https://github.com/qiniu/ruby-sdk](https://github.com/qiniu/ruby-sdk)
3. 创建您的特性分支 (`git checkout -b my-new-feature`)
4. 提交您的改动 (`git commit -am 'Added some feature'`)
5. 将您的改动记录提交到远程 `git` 仓库 (`git push origin my-new-feature`)
6. 然后到 github 网站的该 `git` 远程仓库的 `my-new-feature` 分支下发起 Pull Request

<a name="License"></a>

## 许可证

Copyright (c) 2012 qiniutek.com

基于 MIT 协议发布:

* [www.opensource.org/licenses/MIT](http://www.opensource.org/licenses/MIT)

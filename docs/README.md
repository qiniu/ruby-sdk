---
title: Ruby SDK 使用指南 | 七牛云存储
---

# Ruby SDK 使用指南

此 Ruby SDK 适用于 Ruby 1.8.x, 1.9.x, jruby, rbx, ree 版本，基于 [七牛云存储官方API](/v3/api/) 构建。使用此 SDK 构建您的网络应用程序，能让您以非常便捷地方式将数据安全地存储到七牛云存储上。无论您的网络应用是一个网站程序，还是包括从云端（服务端程序）到终端（手持设备应用）的架构的服务或应用，通过七牛云存储及其 SDK，都能让您应用程序的终端用户高速上传和下载，同时也让您的服务端更加轻盈。

七牛云存储 Ruby SDK 源码地址：<https://github.com/qiniu/ruby-sdk> [![Build Status](https://api.travis-ci.org/qiniu/ruby-sdk.png?branch=master)](https://travis-ci.org/qiniu/ruby-sdk) [![Dependency Status](https://gemnasium.com/why404/qiniu-rs-for-ruby.png)](https://gemnasium.com/why404/qiniu-rs-for-ruby)

**目录**

- [安装](#Installation)
- [接入](#turn-on)
    - [配置密钥（AccessKey / SecretKey）](#establish_connection!)
    - [针对 Ruby On Rails 网站应用初始化设置](#ror-init)
- [使用](#Usage)
    - [文件上传](#upload)
        - [生成上传授权凭证（uploadToken）](#generate-upload-token)
        - [Ruby 服务端上传文件](#upload-server-side)
            - [开启断点续上传](#resumable-upload)
        - [iOS / Android / Web 端直传文件说明](#upload-client-side)
    - [文件下载](#download)
        - [公有资源下载](#download-public-files)
        - [私有资源下载](#download-private-files)
            - [生成下载授权凭证（downloadToken）](#download-token)
        - [高级特性](#other-download-features)
            - [断点续下载](#resumable-download)
            - [自定义 404 NotFound](#upload-file-for-not-found)
    - [文件管理](#file-management)
        - [查看单个文件属性信息](#stat)
        - [复制单个文件](#copy)
        - [移动单个文件](#move)
        - [删除单个文件](#delete)
        - [批量操作](#batch)
            - [批量获取文件属性信息](#batch-get)
            - [批量复制文件](#batch-copy)
            - [批量移动文件](#batch-move)
            - [批量删除文件](#batch-delete)
    - [云处理](#cloud-processing)
        - [图像](#image-processing)
            - [查看图片属性信息](#image-info)
            - [查看图片EXIF信息](#image-exif)
            - [图像在线处理（缩略、裁剪、旋转、转化）](#image-mogrify-for-preview)
            - [图像在线处理（缩略、裁剪、旋转、转化）后并持久化存储](#image-mogrify-for-save-as)
        - 音频(TODO)
        - 视频(TODO)
- [贡献代码](#Contributing)
- [许可证](#License)


<a name="Installation"></a>

## 安装

在您 Ruby 应用程序的 `Gemfile` 文件中，添加如下一行代码：

    gem 'qiniu-rs'

然后，在应用程序所在的目录下，可以运行 `bundle` 安装依赖包：

    $ bundle

或者，可以使用 Ruby 的包管理器 `gem` 进行安装：

    $ gem install qiniu-rs


<a name="turn-on"></a>

## 接入

<a name="establish_connection!"></a>

### 配置密钥（AccessKey / SecretKey）

要接入七牛云存储，您需要拥有一对有效的 Access Key 和 Secret Key 用来进行签名认证。可以通过如下步骤获得：

1. [开通七牛开发者帐号](https://dev.qiniutek.com/signup)
2. [登录七牛开发者自助平台，查看 Access Key 和 Secret Key](https://dev.qiniutek.com/account/keys) 。

在获取到 Access Key 和 Secret Key 之后，您可以在您的程序中调用如下两行代码进行初始化对接：

    Qiniu::RS.establish_connection! :access_key => YOUR_APP_ACCESS_KEY,
                                    :secret_key => YOUR_APP_SECRET_KEY

<a name="ror-init"></a>

### 针对 Ruby On Rails 网站应用初始化设置

如果您使用的是 [Ruby on Rails](http://rubyonrails.org/) 框架，我们建议您在应用初始化启动的过程中，依次调用上述两个函数即可，操作如下：

首先，在应用初始化脚本加载的目录中新建一个文件：`YOUR_RAILS_APP/config/initializers/qiniu-rs.rb`

然后，编辑 `YOUR_RAILS_APP/config/initializers/qiniu-rs.rb` 文件内容如下：

    Qiniu::RS.establish_connection! :access_key => YOUR_APP_ACCESS_KEY,
                                    :secret_key => YOUR_APP_SECRET_KEY

这样，您就可以在您的 `RAILS_APP` 中使用七牛云存储 Ruby SDK 提供的其他任意方法了。

接下来，我们会逐一介绍此 SDK 提供的其他方法。


<a name="Usage"></a>

## 使用

<a name="upload"></a>

### 文件上传

**注意**：如果您只是想要上传已存在您电脑本地或者是服务器上的文件到七牛云存储，可以直接使用七牛提供的 [qrsync](/v3/tools/qrsync/) 上传工具。如果是需要通过您的网站或是移动应用(App)上传文件，则可以接入使用此 SDK，详情参考如下文档说明。

<a name="generate-upload-token"></a>

#### 生成上传授权凭证（uploadToken）

要上传一个文件，首先需要调用 SDK 提供的 `Qiniu::RS.generate_upload_token` 函数来获取一个经过授权用于临时匿名上传的 `upload_token`——经过数字签名的一组数据信息，该 `upload_token` 作为文件上传流中 `multipart/form-data` 的一部分进行传输。

`Qiniu::RS.generate_upload_token` 函数原型如下：

    Qiniu::RS.generate_upload_token :scope              => target_bucket,
                                    :expires_in         => expires_in_seconds,
                                    :callback_url       => callback_url,
                                    :callback_body_type => callback_body_type,
                                    :customer           => end_user_id,
                                    :escape             => allow_upload_callback_api,
                                    :async_options      => async_callback_api_commands,
                                    :return_body        => custom_response_body

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

:async_options
: 可选，字符串类型（String），用于设置文件上传成功后，执行指定的预转指令。参考 [uploadToken 之 asyncOps 说明](http://docs.qiniutek.com/v3/api/io/#uploadToken-asyncOps)

:return_body
: 可选，字符串类型（String），用于设置文件上传成功后，执行七牛云存储规定的回调API，并以 JSON 响应格式返回其执行结果。参考 [uploadToken 之 returnBody 说明](/v3/api/io/#uploadToken-returnBody)。


**返回值**

返回一个字符串类型（String）的用于上传文件用的临时授权 `upload_token`。

<a name="upload-server-side"></a>

#### Ruby 服务端上传文件

通过 `Qiniu::RS.upload_file()` 方法可在客户方的业务服务器上直接往七牛云存储上传文件。该函数规格如下：

    Qiniu::RS.upload_file :uptoken            => upload_token,
                          :file               => file_path,
                          :bucket             => bucket_name,
                          :key                => record_id,
                          :mime_type          => file_mime_type,
                          :note               => some_notes,
                          :callback_params    => callback_params,
                          :enable_crc32_check => false,
                          :rotate             => auto_rotate

**参数**

:uptoken
: 必须，字符串类型（String），调用 `Qiniu::RS.generate_upload_token` 生成的 [用于上传文件的临时授权凭证](#generate-upload-token)

:file
: 必须，字符串类型（String），本地文件可被读取的有效路径

:bucket
: 必须，字符串类型（String），空间名称。

:key
: 必须，字符串类型（String），若把 Bucket 理解为关系性数据库的某个表，那么 key 类似数据库里边某个表的主键ID，需给每一个文件一个UUID用于进行标示。

:mime_type
: 可选，字符串类型（String），文件的 mime-type 值。如若不传入，SDK 会自行计算得出，若计算失败缺省使用 application/octet-stream 代替之。

:note
: 可选，字符串类型（String），为文件添加备注信息。

:callback_params
: 可选，String 或者 Hash 类型，文件上传成功后，七牛云存储向客户方业务服务器发送的回调参数。

:enable_crc32_check
: 可选，Boolean 类型，是否启用文件上传 crc32 校验，缺省为 false 。

:rotate
: 可选，数字类型，上传图片时专用，可针对图片上传后进行旋转。该参数值为 0 ：表示根据图像EXIF信息自动旋转；值为 1 : 右转90度；值为 2 :右转180度；值为 3 : 右转270度。

**返回值**

上传成功，返回如下一个 Hash：

    {"hash"=>"FgHk-_iqpnZji6PsNr4ghsK5qEwR"}

上传失败，会抛出 `UploadFailedError` 异常。

<a name="resumable-upload"></a>

##### 开启断点续上传

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


<a name="upload-client-side"></a>

#### iOS / Android / Web 端直传文件说明

客户端 iOS / Android / Web 上传流程和服务端上传类似，差别在于：客户端直传文件所需的 `uploadToken` 选择在客户方的业务服务器端生成，然后将其生成的 `uploadToken` 颁发给客户端。

简单来讲，客户端上传流程分为两步：

1. [服务端生成上传授权凭证（uploadToken）](#generate-upload-token)
2. 客户端程序调用 [iOS](/v3/sdk/objc/) / [Android](/v3/sdk/android/) SDK 的文件上传方法进行上传

如果是网页直传文件到七牛云存储，网页可以使用 JavaScript 动态实现 [七牛云存储上传API](/v3/api/io/#upload-file-by-html-form)。

通过客户端直传文件，您的终端用户即可把数据（比如图片或视频）直接上传到七牛云存储服务器上，而无须经由您的服务端中转，终端用户上传数据始终是离他物理距离最近的七牛存储节点。当终端用户上传成功后，七牛云存储服务端会向您指定的 `callback_url` （一般在 [uploadToken](#generate-upload-token) 里边指定）发送回调数据（回调数据在客户端程序里边指定）。如果 `callback_url` 所指向的服务端处理完毕后输出 `JSON` 格式的数据，七牛云存储服务端会将该回调请求所得的 JSON 响应信息原封不动地返回给客户端应用程序。


<a name="download"></a>

### 文件下载

七牛云存储上的资源下载分为 [公有资源下载](#download-public-files) 和 [私有资源下载](#download-private-files) 。

私有（private）是 Bucket（空间）的一个属性，一个私有 Bucket 中的资源为私有资源，私有资源不可匿名下载。

新创建的空间（Bucket）缺省为私有，也可以将某个 Bucket 设为公有，公有 Bucket 中的资源为公有资源，公有资源可以匿名下载。

<a name="download-public-files"></a>

#### 公有资源下载

    [GET] http://<bucket>.qiniudn.com/<key>

或者，

    [GET] http://<绑定域名>/<key>

绑定域名可以是自定义域名，可以在 [七牛云存储开发者自助网站](https://dev.qiniutek.com/buckets) 进行域名绑定操作。

注意，尖括号不是必需，代表替换项。

<a name="download-private-files"></a>

#### 私有资源下载

私有资源只能通过临时下载授权凭证(downloadToken)下载，下载链接格式如下：

    [GET] http://<bucket>.qiniudn.com/<key>?token=<downloadToken>

或者，

    [GET] http://<绑定域名>/<key>?token=<downloadToken>

<a name="download-token"></a>

##### 生成下载授权凭证（downloadToken）

`<downloadToken>` 可以使用 SDK 提供的如下方法生成：

    Qiniu::RS.generate_download_token :expires_in => expires_in_seconds,
                                      :pattern    => download_url_patterns

**参数**

expires_in
: 可选，数字类型，用于设置上传 URL 的有效期，单位：秒，缺省为 3600 秒，即 1 小时后该上传链接不再有效。

pattern
: 可选，字符串类型，用于设置可匹配的下载链接。参考：[downloadToken pattern 详解](/v3/api/io/#download-token-pattern)


<a name="other-download-features"></a>

#### 高级特性

<a name="resumable-download"></a>

##### 断点续下载

七牛云存储支持标准的断点续下载，参考：[云存储API之断点续下载](/v3/api/io/#download-by-range-bytes)

<a name="upload-file-for-not-found"></a>

##### 自定义 404 NotFound

您可以上传一个应对 HTTP 404 出错处理的文件，当用户访问一个不存在的文件时，即可使用您上传的“自定义404文件”代替之。要这么做，您只须使用 `Qiniu::RS.upload_file` 函数上传一个 `key` 为固定字符串类型的值 `errno-404` 即可。

除了使用 SDK 提供的方法，同样也可以借助七牛云存储提供的命令行辅助工具 [qboxrsctl](/v3/tools/qboxrsctl/) 达到同样的目的：

    qboxrsctl put <Bucket> <Key> <LocalFile>

将其中的 `<Key>` 换作  `errno-404` 即可。

注意，每个 `<Bucket>` 里边有且只有一个 `errno-404` 文件，上传多个，最后的那一个会覆盖前面所有的。


<a name="file-management"></a>

### 文件管理

文件管理包括对存储在七牛云存储上的文件进行查看、复制、移动和删除处理。

<a name="stat"></a>

#### 查看单个文件属性信息

    Qiniu::RS.stat(bucket, key)

可以通过 SDK 提供的 `Qiniu::RS.stat` 函数，来查看某个已上传文件的属性信息。

**参数**

bucket
: 必须，字符串类型（String），空间名称。

key
: 必须，字符串类型（String），若把 Bucket 理解为关系性数据库的某个表，那么 key 类似数据库里边某个表的主键ID，需给每一个文件一个UUID用于进行标示。

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


<a name="copy"></a>

#### 复制单个文件

    Qiniu::RS.copy(source_bucket, source_key, target_bucket, target_key)

可以通过 SDK 提供的 `Qiniu::RS.copy` 函数进行文件复制操作。

**参数**

source_bucket
: 必须，字符串类型（String），指定源空间。

source_key
: 必须，字符串类型（String），指定源文件。

target_bucket
: 必须，字符串类型（String），指定要复制到的目标空间。

target_key
: 必须，字符串类型（String），指定要复制到目标空间的目标文件名。

**返回值**

如果请求失败，返回 `false`；否则返回 `true` 。


<a name="move"></a>

#### 移动单个文件

    Qiniu::RS.move(source_bucket, source_key, target_bucket, target_key)

可以通过 SDK 提供的 `Qiniu::RS.move` 函数进行文件移动操作。

**参数**

source_bucket
: 必须，字符串类型（String），指定源空间。

source_key
: 必须，字符串类型（String），指定源文件。

target_bucket
: 必须，字符串类型（String），指定要移动到的目标空间。

target_key
: 必须，字符串类型（String），指定要移动到目标空间的目标文件名。

**返回值**

如果请求失败，返回 `false`；否则返回 `true` 。


<a name="delete"></a>

### 删除单个文件

    Qiniu::RS.delete(bucket, key)

`Qiniu::RS.delete` 函数提供了从指定的 `bucket` 中删除指定的 `key`，即删除 `key` 索引关联的具体文件。

**参数**

bucket
: 必须，字符串类型（String），空间名称。

key
: 必须，字符串类型（String），若把 Bucket 理解为关系性数据库的某个表，那么 key 类似数据库里边某个表的主键ID，需给每一个文件一个UUID用于进行标示。

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
: 必须，字符串类型（String），空间名称。

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

<a name="batch-get"></a>

#### 批量获取文件属性信息

    Qiniu::RS.batch_get(bucket, keys)

`Qiniu::RS.batch_get` 函数是在 `Qiniu::RS.batch` 之上的封装，提供批量获取文件属性信息（含下载链接）的功能。

**参数**

bucket
: 必须，字符串类型（String），空间名称。

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


<a name="batch-copy"></a>

#### 批量复制文件

    Qiniu::RS.batch_copy(*args)

等价于，

    Qiniu::RS.batch_copy [source_bucket, source_key, target_bucket, target_key], ...

`Qiniu::RS.batch_copy()` 的参数是一个可变长数组，其中每个数组其元素含义同 `Qiniu::RS.copy` 的参数一样。

**返回值**

如果批量删除成功，返回 `true` ，否则为 `false` 。


<a name="batch-move"></a>

#### 批量移动文件

    Qiniu::RS.batch_move(*args)

等价于，

    Qiniu::RS.batch_move [source_bucket, source_key, target_bucket, target_key], ...

`Qiniu::RS.batch_move()` 的参数是一个可变长数组，其中每个数组其元素含义同 `Qiniu::RS.move` 的参数一样。

**返回值**

如果批量删除成功，返回 `true` ，否则为 `false` 。


<a name="batch-delete"></a>

#### 批量删除文件

    Qiniu::RS.batch_delete(bucket, keys)

`Qiniu::RS.batch_download` 函数也是在 `Qiniu::RS.batch` 之上的封装，提供批量删除文件的功能。

参数同 `Qiniu::RS.batch_get` 的参数一样。

**返回值**

如果批量删除成功，返回 `true` ，否则为 `false` 。


<a name="cloud-processing"></a>

### 云处理

<a name="image-processing"></a>

#### 图像

<a name="image-info"></a>

##### 查看图片属性信息

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

<a name="image-exif"></a>

##### 查看图片EXIF信息

    Qiniu::RS.image_exif(url)

使用 SDK 提供的 `Qiniu::RS.image_exif` 方法，可以基于一张存储于七牛云存储服务器上的原始图片图片，取到该图片的  EXIF 信息。

**参数**

url
: 必须，字符串类型（String），原图的下载链接，需是 `Qiniu::RS.get`（或`Qiniu::RS.batch_get`）函数返回值中 `url` 字段的值，或者是 `Qiniu::RS.download`（或`Qiniu::RS.batch_download`）函数返回的下载链接。且文件本身必须是图片。

**返回值**

如果参数 `url` 所代表的图片没有 EXIF 信息，返回 `false`。否则，返回一个包含 EXIF 信息的 Hash 结构。

<a name="image-mogrify-for-preview"></a>

##### 图像在线处理（缩略、裁剪、旋转、转化）

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

<a name="image-mogrify-for-save-as"></a>

#### 图像在线处理（缩略、裁剪、旋转、转化）后并持久化存储

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

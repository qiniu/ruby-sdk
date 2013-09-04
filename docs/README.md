---
title: Ruby SDK
---

- [概述](#overview)
- [准备开发环境](#prepare)
	- [环境依赖](#dependences)
	- [安装](#install)
	- [ACCESS_KEY 和 SECRET_KEY](#appkey)
- [使用SDK](#sdk-usage)
	- [初始化环境与清理](#init)
	- [上传文件](#io-put)
		- [上传流程](#io-put-flow)
		- [上传策略](#io-put-policy)
		- [断点续上传、分块并行上传](#resumable-io-put)
	- [下载文件](#io-get)
		- [下载公有文件](#io-get-public)
		- [下载私有文件](#io-get-private)
		- [HTTPS 支持](#io-https-get)
		- [断点续下载](#resumable-io-get)
	- [资源操作](#rs)
		- [获取文件信息](#rs-stat)
		- [删除文件](#rs-delete)
		- [复制/移动文件](#rs-copy-move)
		- [批量操作](#rs-batch)
    - [云处理](#fop)

<a name="overview"></a>


## 概述

此 Ruby SDK 适用于 Ruby 1.8.x, 1.9.x, jruby, rbx, ree 版本，基于 [七牛云存储官方API](http://docs.qiniu.com) 构建。使用此 SDK 构建您的网络应用程序，能让您以非常便捷地方式将数据安全地存储到七牛云存储上。无论您的网络应用是一个网站程序，还是包括从云端（服务端程序）到终端（手持设备应用）的架构的服务或应用，通过七牛云存储及其 SDK，都能让您应用程序的终端用户高速上传和下载，同时也让您的服务端更加轻盈。

七牛云存储 Ruby SDK 源码地址：<https://github.com/qiniu/ruby-sdk> [![Build Status](https://api.travis-ci.org/qiniu/ruby-sdk.png?branch=master)](https://travis-ci.org/qiniu/ruby-sdk) [![Dependency Status](https://gemnasium.com/why404/qiniu-rs-for-ruby.png)]


<a name="prepare"></a>

## 准备开发环境

### 安装

在您 Ruby 应用程序的 `Gemfile` 文件中，添加如下一行代码：

    gem 'qiniu-rs'

然后，在应用程序所在的目录下，可以运行 `bundle` 安装依赖包：

    $ bundle

或者，可以使用 Ruby 的包管理器 `gem` 进行安装：

    $ gem install qiniu-rs


<a name="appkey"></a>

### ACCESS_KEY 和 SECRET_KEY

在使用SDK 前，您需要拥有一对有效的 AccessKey 和 SecretKey 用来进行签名授权。

可以通过如下步骤获得：

1. [开通七牛开发者帐号](https://portal.qiniu.com/signup)
2. [登录七牛开发者自助平台，查看 AccessKey 和 SecretKey](https://portal.qiniu.com/setting/key) 。

**注意：SECRET_KEY用户应当妥善保存，不能外泄。亦不可放置在客户端中，分发给最终用户。一旦发生泄露，请立刻到开发者平台更新。**

<a name="sdk-usage"></a>

## 使用SDK

<a name="init"></a>

### 初始化环境

在使用Ruby SDK之前，需要初始化环境，并且设置默认的ACCESS_KEY和SECRET_KEY：

    Qiniu::RS.establish_connection! :access_key => <YOUR_APP_ACCESS_KEY>,
                                    :secret_key => <YOUR_APP_SECRET_KEY>

如果您使用的是 [Ruby on Rails](http://rubyonrails.org/) 框架，我们建议您在应用初始化启动的过程中，依次调用上述两个函数即可，操作如下：

首先，在应用初始化脚本加载的目录中新建一个文件：`YOUR_RAILS_APP/config/initializers/qiniu-rs.rb`

然后，编辑 `YOUR_RAILS_APP/config/initializers/qiniu-rs.rb` 文件内容如下：

    Qiniu::RS.establish_connection! :access_key => YOUR_APP_ACCESS_KEY,
                                    :secret_key => YOUR_APP_SECRET_KEY

这样，您就可以在您的 `RAILS_APP` 中使用七牛云存储 Ruby SDK 提供的其他任意方法了。


<a name="io-put"></a>

### 上传文件

为了尽可能地改善终端用户的上传体验，七牛云存储首创了客户端直传功能。一般云存储的上传流程是：

    客户端（终端用户） => 业务服务器 => 云存储服务

这样多了一次上传的流程，和本地存储相比，会相对慢一些。但七牛引入了客户端直传，将整个上传过程调整为：

    客户端（终端用户） => 七牛 => 业务服务器

客户端（终端用户）直接上传到七牛的服务器，通过DNS智能解析，七牛会选择到离终端用户最近的ISP服务商节点，速度会比本地存储快很多。文件上传成功以后，七牛的服务器使用回调功能，只需要将非常少的数据（比如Key）传给应用服务器，应用服务器进行保存即可。

<a name="io-put-flow"></a>

#### 上传流程

在七牛云存储中，整个上传流程大体分为这样几步：

1. 业务服务器颁发 [uptoken（上传授权凭证）](http://docs.qiniu.com/api/put.html#uploadToken)给客户端（终端用户）
2. 客户端凭借 [uptoken](http://docs.qiniu.com/api/put.html#uploadToken) 上传文件到七牛
3. 在七牛获得完整数据后，发起一个 HTTP 请求回调到业务服务器
4. 业务服务器保存相关信息，并返回一些信息给七牛
5. 七牛原封不动地将这些信息转发给客户端（终端用户）

需要注意的是，回调到业务服务器的过程是可选的，它取决于业务服务器颁发的 [uptoken](http://docs.qiniu.com/api/put.html#uploadToken)。如果没有回调，七牛会返回一些标准的信息（比如文件的 hash）给客户端。如果上传发生在业务服务器，以上流程可以自然简化为：

1. 业务服务器生成 uptoken（不设置回调，自己回调到自己这里没有意义）
2. 凭借 [uptoken](http://docs.qiniu.com/api/put.html#uploadToken) 上传文件到七牛
3. 善后工作，比如保存相关的一些信息

<a name="io-put-policy"></a>

#### 上传策略

[uptoken](http://docs.qiniu.com/api/put.html#uploadToken) 实际上是用 AccessKey/SecretKey 进行数字签名的上传策略(`Qiniu_RS_PutPolicy`)，它控制则整个上传流程的行为。让我们快速过一遍你都能够决策啥：

```{ruby}
class PutPolicy

  include Utils

  attr_accessor :scope, :callback_url, :callback_body, :return_url, :return_body, :async_ops, :end_user, :expires

  def initialize(opts = {})
    @scope = opts[:scope]
    @callback_url = opts[:callback_url]
    @callback_body = opts[:callback_body]
    @return_url = opts[:return_url]
    @return_body = opts[:return_body]
    @async_ops = opts[:async_ops]
    @end_user = opts[:end_user]
    @expires = opts[:expires] || 3600
  end
```

* `scope` 限定客户端的权限。如果 `scope` 是 bucket，则客户端只能新增文件到指定的 bucket，不能修改文件。如果 `scope` 为 bucket:key，则客户端可以修改指定的文件。
* `callbackUrl` 设定业务服务器的回调地址，这样业务服务器才能感知到上传行为的发生。
* `callbackBody` 设定业务服务器的回调信息。文件上传成功后，七牛向业务服务器的callbackUrl发送的POST请求携带的数据。支持 [魔法变量](http://docs.qiniu.com/api/put.html#MagicVariables) 和 [自定义变量](http://docs.qiniu.com/api/put.html#xVariables)。
* `returnUrl` 设置用于浏览器端文件上传成功后，浏览器执行301跳转的URL，一般为 HTML Form 上传时使用。文件上传成功后浏览器会自动跳转到 `returnUrl?upload_ret=returnBody`。
* `returnBody` 可调整返回给客户端的数据包，支持 [魔法变量](http://docs.qiniu.com/api/put.html#MagicVariables) 和 [自定义变量](http://docs.qiniu.com/api/put.html#xVariables)。`returnBody` 只在没有 `callbackUrl` 时有效（否则直接返回 `callbackUrl` 返回的结果）。不同情形下默认返回的 `returnBody` 并不相同。在一般情况下返回的是文件内容的 `hash`，也就是下载该文件时的 `etag`；但指定 `returnUrl` 时默认的 `returnBody` 会带上更多的信息。
* `asyncOps` 可指定上传完成后，需要自动执行哪些数据处理。这是因为有些数据处理操作（比如音视频转码）比较慢，如果不进行预转可能第一次访问的时候效果不理想，预转可以很大程度改善这一点。

关于上传策略更完整的说明，请参考 [uptoken](http://docs.qiniu.com/api/put.html#uploadToken)。

<a name="upload-token"></a>

#### 生成上传凭证

服务端生成 [uptoken](http://docs.qiniu.com/api/put.html#uploadToken) 代码如下：

```{ruby}
@access_key = Qiniu::Conf.settings[:access_key]
@secret_key = Qiniu::Conf.settings[:secret_key]

@mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)
pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
token = pp.token(@mac)
```

<a name="upload-do"></a>

#### 上传文件

上传文件到七牛（通常是客户端完成，但也可以发生在服务端）：

```{ruby}
@access_key = Qiniu::Conf.settings[:access_key]
@secret_key = Qiniu::Conf.settings[:secret_key]

@mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)
pe = Qiniu::Io::PutExtra.new
pp = Qiniu::Rs::PutPolicy.new({ :scope => @bucket1, :expires => 1800 })
token = pp.token(@mac)
file_data = File.new(@file_path, 'r')
code, res = Qiniu::Io.Put(token, @to_del_key, file_data, pe)
```

上传文件有两种方式：Put()接受一个文件对象作为参数；PutFile()接受一个文件的路径做为参数。文件上传可以通过PutExtra结构控制更多的上传行为，具体参考[PutExtra](#put-extra)

<a name="put-extra"></a>

#### PutExtra

PutExtra是上传时的可选信息，默认为None

```{ruby}
class PutExtra

  attr_accessor :Params, :MimeType, :Crc32, :CheckCrc

  def initialize
    @Params = {}          #用户自定义参数，{"x:<name>" => <value>}，参数名以x:开头
    @MimeType = ''
    @Crc32 = 0
    @CheckCrc = 0
end
end
```

* `params` 是一个Hash。用于放置[自定义变量](http://docs.qiniu.com/api/put.html#xVariables)，key必须以 x: 开头命名，不限个数。可以在 uploadToken 的 callbackBody 选项中求值。
* `mime_type` 表示数据的MimeType，当不指定时七牛服务器会自动检测。
* `crc32` 待检查的crc32值
* `check_crc` 可选值为0, 1, 2。 
	`check_crc == 0`: 表示不进行 crc32 校验。
	`check_crc == 1`: 上传二进制数据时等同于 `check_crc=2`；上传本地文件时会自动计算 crc32 值。
	`check_crc == 2`: 表示进行 crc32 校验，且 crc32 值就是上面的 `crc32` 变量


<a name="io-get"></a>

### 下载文件

<a name="io-get-public"></a>

#### 下载公有文件

每个 bucket 都会绑定一个或多个域名（domain）。如果这个 bucket 是公开的，那么该 bucket 中的所有文件可以通过一个公开的下载 url 可以访问到：

    http://<domain>/<key>

假设某个 bucket 既绑定了七牛的二级域名，如 hello.qiniudn.com，也绑定了自定义域名（需要备案），如 hello.com。那么该 bucket 中 key 为 a/b/c.htm 的文件可以通过 http://hello.qiniudn.com/a/b/c.htm 或 http://hello.com/a/b/c.htm 中任意一个 url 进行访问。

<a name="io-get-private"></a>

#### 下载私有文件

如果某个 bucket 是私有的，那么这个 bucket 中的所有文件只能通过一个的临时有效的 downloadUrl 访问：

    http://<domain>/<key>?e=<deadline>&token=<dntoken>

其中 dntoken 是由业务服务器签发的一个[临时下载授权凭证](http://docs.qiniu.com/api/get.html#download-token)，deadline 是 dntoken 的有效期。dntoken不需要单独生成，SDK 提供了生成完整 downloadUrl 的方法（包含了 dntoken），示例代码如下：

```{ruby}
@access_key = Qiniu::Conf.settings[:access_key]
@secret_key = Qiniu::Conf.settings[:secret_key]

@mac = Qiniu::Auth::Digest::Mac.new(@access_key, @secret_key)
base_url = Qiniu::Rs.MakeBaseUrl("a.qiniudn.com", "down.jpg")
url = @mac.make_request(base_url, @mac)
```

生成 downloadUrl 后，服务端下发 downloadUrl 给客户端。客户端收到 downloadUrl 后，和公有资源类似，直接用任意的 HTTP 客户端就可以下载该资源了。唯一需要注意的是，在 downloadUrl 失效却还没有完成下载时，需要重新向服务器申请授权。

无论公有资源还是私有资源，下载过程中客户端并不需要七牛 SDK 参与其中。

<a name="resumable-io-get"></a>

#### 断点续下载

无论是公有资源还是私有资源，获得的下载 url 支持标准的 HTTP 断点续传协议。考虑到多数语言都有相应的断点续下载支持的成熟方法，七牛 Ruby-SDK 并不提供断点续下载相关代码。

<a name="rs"></a>

### 资源操作

资源操作包括对存储在七牛云存储上的文件进行查看、复制、移动和删除处理，并且允许批量地执行文件管理操作，方便用户使用。

<a name="rs-stat"></a>

#### 获取文件信息

用户可以通过Qiniu::Rs::Client.Stat()获取文件信息。使用方式如下：

```{ruby}
@rs_cli = Qiniu::Rs::Client.new(@mac)
code, res = @rs_cli.Stat(@bucket1, @to_del_key)
```

<a name="rs-delete"></a>

#### 删除文件

用户可以通过Qiniu::Rs::Client.Delete()删除文件。使用方式如下：

```{ruby}
@rs_cli = Qiniu::Rs::Client.new(@mac)
code, res = @rs_cli.Delete(@bucket1, @to_del_key)
```

<a name="rs-copy-move"></a>

#### 移动文件

用户可以通过Qiniu::Rs::Client.Move()移动文件。使用方式如下：

```{ruby}
@rs_cli = Qiniu::Rs::Client.new(@mac)
code, res = @rs_cli.Copy(@bucket1, @to_copy_key, @bucket1, @to_move_key)
```

<a name="rs-copy-move"></a>

#### 复制文件

用户可以通过Qiniu::Rs::Client.Copy()复制文件。使用方式如下：

```{ruby}
@rs_cli = Qiniu::Rs::Client.new(@mac)
code, res = @rs_cli.Copy(@bucket1, @to_del_key, @bucket1, @to_copy_key)
```

<a name="rs-batch"></a>

#### 批量操作

批量操作允许用户在一次请求中操作若干个文件。包括：

* 批量获取文件信息：Qiniu::Rs::Client.BatchStat()
* 批量删除文件：Qiniu::Rs::Client.BatchDelete()
* 批量移动文件：Qiniu::Rs::Client.BatchMove()
* 批量复制文件：Qiniu::Rs::Client.BatchCopy()

批量获取文件信息和批量删除文件的参数是EntryPath的数组，用于指定一组文件。批量移动文件和批量复制文件使用的参数是EntryPathPair的数组，EntryPathPair包含一对EntryPath，分别指定源文件和目标文件。

批量操作的具体使用方式如下：

```{ruby}
@rs_cli = Qiniu::Rs::Client.new(@mac)

# 批量获取文件信息
to_stat = []
@keys.each do | key |
	to_stat << Qiniu::Rs::EntryPath.new(@bucket1, key)
end
code, res = @rs_cli.BatchStat(to_stat)

# 批量删除文件
to_del = []
@keys.each do  | key |
	to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
end
@move_keys.each do | key |
	to_del << Qiniu::Rs::EntryPath.new(@bucket1, key)
end

code, res = @rs_cli.BatchDelete(to_del)

# 批量移动文件
to_move = []
i = 0
while i < @copy_keys.length do
	to_move << Qiniu::Rs::EntryPathPair.new(
		Qiniu::Rs::EntryPath.new(@bucket1, @copy_keys[i]),
		Qiniu::Rs::EntryPath.new(@bucket2, @move_keys[i]))
	i += 1
end
code, res = @rs_cli.BatchMove(to_move)

# 批量复制文件
to_copy = []
i = 0
while i < @keys.length do
	to_copy << Qiniu::Rs::EntryPathPair.new(
		Qiniu::Rs::EntryPath.new(@bucket1, @keys[i]),
		Qiniu::Rs::EntryPath.new(@bucket2, @copy_keys[i]))
	i += 1
end
code, res = @rs_cli.BatchCopy(to_copy)
```

<a name="fop"></a>

### 云处理

#### 查看图像信息

```{ruby}
ii = Qiniu::Fop::ImageInfo.new
code, ret = ii.call @image_url
puts code, ret
```

#### 查看图像Exif

```{ruby}
exif = Qiniu::Fop::Exif.new
code, ret = exif.call @image_url
puts code, ret
```

#### 生成缩略图

```{ruby}
iv = Qiniu::Fop::ImageView.new
iv.height = 100
iv.width = 40
returl = iv.make_request @image_url
puts returl
```

## 贡献代码

1. Fork
2. 创建您的特性分支 (git checkout -b my-new-feature)
3. 提交您的改动 (git commit -am 'Added some feature')
4. 将您的修改记录提交到远程 git 仓库 (git push origin my-new-feature)
5. 然后到 github 网站的该 git 远程仓库的 my-new-feature 分支下发起 Pull Request

## 许可证

Copyright (c) 2013 qiniu.com

基于 MIT 协议发布:

* [www.opensource.org/licenses/MIT](http://www.opensource.org/licenses/MIT)


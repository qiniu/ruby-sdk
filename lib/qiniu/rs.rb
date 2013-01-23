# -*- encoding: utf-8 -*-

module Qiniu
  module RS
    autoload :Version, 'qiniu/rs/version'
    autoload :Config, 'qiniu/rs/config'
    autoload :Log, 'qiniu/rs/log'
    autoload :Exception, 'qiniu/rs/exceptions'
    autoload :Utils, 'qiniu/rs/utils'
    autoload :Auth, 'qiniu/rs/auth'
    autoload :IO, 'qiniu/rs/io'
    autoload :UP, 'qiniu/rs/up'
    autoload :RS, 'qiniu/rs/rs'
    autoload :EU, 'qiniu/rs/eu'
    autoload :Pub, 'qiniu/rs/pub'
    autoload :Image, 'qiniu/rs/image'
    autoload :AccessToken, 'qiniu/tokens/access_token'
    autoload :QboxToken, 'qiniu/tokens/qbox_token'
    autoload :UploadToken, 'qiniu/tokens/upload_token'
    autoload :DownloadToken, 'qiniu/tokens/download_token'
    autoload :Abstract, 'qiniu/rs/abstract'

    class << self

      StatusOK = 200

      def establish_connection!(opts = {})
        Config.initialize_connect opts
      end

      def login!(user, pwd)
        code, data = Auth.exchange_by_password!(user, pwd)
        code == StatusOK
      end

      def mkbucket(bucket_name)
        code, data = RS.mkbucket(bucket_name)
        code == StatusOK
      end

      def buckets
        code, data = RS.buckets
        code == StatusOK ? data : false
      end

      def set_protected(bucket, protected_mode)
        code, data = Pub.set_protected(bucket, protected_mode)
        code == StatusOK
      end

      def set_separator(bucket, separator)
        code, data = Pub.set_separator(bucket, separator)
        code == StatusOK
      end

      def set_style(bucket, name, style)
        code, data = Pub.set_style(bucket, name, style)
        code == StatusOK
      end

      def unset_style(bucket, name)
        code, data = Pub.unset_style(bucket, name)
        code == StatusOK
      end

=begin
      def set_watermark(customer_id, options = {})
        code, data = EU.set_watermark(customer_id, options)
        code == StatusOK
      end

      def get_watermark(customer_id = nil)
        code, data = EU.get_watermark(customer_id)
        code == StatusOK ? data : false
      end
=end

      def put_auth(expires_in = nil, callback_url = nil)
        code, data = IO.put_auth(expires_in, callback_url)
        code == StatusOK ? data["url"] : false
      end

      def upload opts = {}
        code, data = IO.upload_file(opts[:url],
                                    opts[:file],
                                    opts[:bucket],
                                    opts[:key],
                                    opts[:mime_type],
                                    opts[:note],
                                    opts[:callback_params],
                                    opts[:enable_crc32_check])
        code == StatusOK
      end

      def put_file opts = {}
        code, data = IO.put_file(opts[:file],
                                 opts[:bucket],
                                 opts[:key],
                                 opts[:mime_type],
                                 opts[:note],
                                 opts[:enable_crc32_check])
        code == StatusOK
      end

      def upload_file opts = {}
        uncontained_opts = [:uptoken, :file, :bucket, :key] - opts.keys
        raise MissingArgsError, uncontained_opts unless uncontained_opts.empty?

        source_file = opts[:file]
        raise NoSuchFileError, source_file unless File.exist?(source_file)

        opts[:enable_resumable_upload] = true unless opts.has_key?(:enable_resumable_upload)

        if opts[:enable_resumable_upload] && File::size(source_file) > Config.settings[:block_size]
          code, data = UP.upload_with_token(opts[:uptoken],
                                            opts[:file],
                                            opts[:bucket],
                                            opts[:key],
                                            opts[:mime_type],
                                            opts[:note],
                                            opts[:customer],
                                            opts[:callback_params],
                                            opts[:rotate])
        else
          code, data = IO.upload_with_token(opts[:uptoken],
                                            opts[:file],
                                            opts[:bucket],
                                            opts[:key],
                                            opts[:mime_type],
                                            opts[:note],
                                            opts[:callback_params],
                                            opts[:enable_crc32_check],
                                            opts[:rotate])
        end
        raise UploadFailedError.new(code, data) if code != StatusOK
        return data
      end

      def stat(bucket, key)
        code, data = RS.stat(bucket, key)
        code == StatusOK ? data : false
      end

      def get(bucket, key, save_as = nil, expires_in = nil, version = nil)
        code, data = RS.get(bucket, key, save_as, expires_in, version)
        code == StatusOK ? data : false
      end

      def download(bucket, key, save_as = nil, expires_in = nil, version = nil)
        code, data = RS.get(bucket, key, save_as, expires_in, version)
        code == StatusOK ? data["url"] : false
      end

      def copy(source_bucket, source_key, target_bucket, target_key)
        code, data = RS.copy(source_bucket, source_key, target_bucket, target_key)
        code == StatusOK
      end

      def move(source_bucket, source_key, target_bucket, target_key)
        code, data = RS.move(source_bucket, source_key, target_bucket, target_key)
        code == StatusOK
      end

      def delete(bucket, key)
        code, data = RS.delete(bucket, key)
        code == StatusOK
      end

      def batch(command, bucket, keys)
        code, data = RS.batch(command, bucket, keys)
        code == StatusOK ? data : false
      end

      def batch_stat(bucket, keys)
        code, data = RS.batch_stat(bucket, keys)
        code == StatusOK ? data : false
      end

      def batch_get(bucket, keys)
        code, data = RS.batch_get(bucket, keys)
        code == StatusOK ? data : false
      end

      def batch_copy(*args)
        code, data = RS.batch_copy(args)
        code == StatusOK
      end

      def batch_move(*args)
        code, data = RS.batch_move(args)
        code == StatusOK
      end

      def batch_download(bucket, keys)
        code, data = RS.batch_get(bucket, keys)
        return false unless code == StatusOK
        links = []
        data.each { |e| links << e["data"]["url"] }
        links
      end

      def batch_delete(bucket, keys)
        code, data = RS.batch_delete(bucket, keys)
        code == StatusOK ? data : false
      end

      def publish(domain, bucket)
        code, data = RS.publish(domain, bucket)
        code == StatusOK
      end

      def unpublish(domain)
        code, data = RS.unpublish(domain)
        code == StatusOK
      end

      def drop(bucket)
        code, data = RS.drop(bucket)
        code == StatusOK
      end

      def image_info(url)
        code, data = Image.info(url)
        code == StatusOK ? data : false
      end

      def image_exif(url)
        code, data = Image.exif(url)
        code == StatusOK ? data : false
      end

      def image_preview_url(url, spec)
        Image.preivew_url(url, spec)
      end

      def image_mogrify_preview_url(source_image_url, options)
        Image.mogrify_preview_url(source_image_url, options)
      end

      def image_mogrify_save_as(bucket, key, source_image_url, options)
        code, data = RS.image_mogrify_save_as(bucket, key, source_image_url, options)
        code == StatusOK ? data : false
      end

      def generate_upload_token(opts = {})
        token_obj = UploadToken.new(opts)
        token_obj.access_key = Config.settings[:access_key]
        token_obj.secret_key = Config.settings[:secret_key]
        #token_obj.scope = opts[:scope]
        #token_obj.expires_in = opts[:expires_in]
        #token_obj.callback_url = opts[:callback_url]
        #token_obj.callback_body_type = opts[:callback_body_type]
        #token_obj.customer = opts[:customer]
        #token_obj.escape = opts[:escape]
        #token_obj.async_options = opts[:async_options]
        #token_obj.return_body = opts[:return_body]
        token_obj.generate_token
      end

      def generate_download_token(opts = {})
        token_obj = DownloadToken.new(opts)
        token_obj.access_key = Config.settings[:access_key]
        token_obj.secret_key = Config.settings[:secret_key]
        #token_obj.expires_in = opts[:expires_in]
        #token_obj.pattern = opts[:pattern]
        token_obj.generate_token
      end

    end

  end
end

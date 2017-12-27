# -*- encoding: utf-8 -*-

require 'qiniu/exceptions'

module Qiniu
  require_relative 'qiniu/version'
  require_relative 'qiniu/utils'
  require_relative 'qiniu/auth'
  require_relative 'qiniu/config'
  require_relative 'qiniu/log'
  require_relative 'qiniu/tokens/access_token'
  require_relative 'qiniu/tokens/qbox_token'
  require_relative 'qiniu/tokens/upload_token'
  require_relative 'qiniu/tokens/download_token'
  require_relative 'qiniu/abstract'
  require_relative 'qiniu/storage'
  require_relative 'qiniu/fop'
  require_relative 'qiniu/misc'
  require_relative 'qiniu/host_manager'
  require_relative 'qiniu/http'

    class << self

      StatusOK = 200

      def establish_connection!(opts = {})
        Config.initialize_connect opts
      end

      def establish_https_connection!(opts = {})
        Config.initialize_connect_https opts
      end

      def switch_to_http!
        Config.switch_to_http
      end

      def switch_to_https!
        Config.switch_to_https
      end

      def mkbucket(bucket_name)
        code, _data = Storage.mkbucket(bucket_name)
        code == StatusOK
      end

      def buckets
        code, data = Storage.buckets
        code == StatusOK ? data : false
      end

      def set_protected(bucket, protected_mode)
        code, _data = Misc.set_protected(bucket, protected_mode)
        code == StatusOK
      end

      def set_separator(bucket, separator)
        code, _data = Misc.set_separator(bucket, separator)
        code == StatusOK
      end

      def set_style(bucket, name, style)
        code, _data = Misc.set_style(bucket, name, style)
        code == StatusOK
      end

      def unset_style(bucket, name)
        code, _data = Misc.unset_style(bucket, name)
        code == StatusOK
      end

      def upload_file(opts = {})
        uncontained_opts = [:uptoken, :file, :bucket, :key] - opts.keys
        raise MissingArgsError, uncontained_opts unless uncontained_opts.empty?

        source_file = opts[:file]
        raise NoSuchFileError, source_file unless File.exist?(source_file)

        opts[:enable_resumable_upload] = true unless opts.has_key?(:enable_resumable_upload)

        if opts[:enable_resumable_upload] && File::size(source_file) > Config.settings[:block_size]
          code, data, _raw_headers = Storage.resumable_upload_with_token(opts[:uptoken],
                                            opts[:file],
                                            opts[:bucket],
                                            opts[:key],
                                            opts[:mime_type],
                                            opts[:customer],
                                            opts[:callback_params],
                                            opts[:rotate])
        else
          code, data, _raw_headers = Storage.upload_with_token(opts[:uptoken],
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
        data
      end

      def stat(bucket, key)
        code, data = Storage.stat(bucket, key)
        code == StatusOK ? data : false
      end

      def copy(source_bucket, source_key, target_bucket, target_key)
        code, _data = Storage.copy(source_bucket, source_key, target_bucket, target_key)
        code == StatusOK
      end

      def move(source_bucket, source_key, target_bucket, target_key)
        code, _data = Storage.move(source_bucket, source_key, target_bucket, target_key)
        code == StatusOK
      end

      def delete(bucket, key)
        code, _data = Storage.delete(bucket, key)
        code == StatusOK
      end

      def fetch(bucket, target_url, key)
        code, _data = Storage.fetch(bucket, target_url, key)
        code == StatusOK
      end

      def batch(command, bucket, keys)
        code, data = Storage.batch(command, bucket, keys)
        code == StatusOK ? data : false
      end

      def batch_stat(bucket, keys)
        code, data = Storage.batch_stat(bucket, keys)
        code == StatusOK ? data : false
      end

      def batch_copy(*args)
        code, _data = Storage.batch_copy(args)
        code == StatusOK
      end

      def batch_move(*args)
        code, _data = Storage.batch_move(args)
        code == StatusOK
      end

      def batch_delete(bucket, keys)
        code, data = Storage.batch_delete(bucket, keys)
        code == StatusOK ? data : false
      end

      def drop(bucket)
        code, _data = Storage.drop(bucket)
        code == StatusOK
      end

      def image_info(url)
        code, data = Fop::Image.info(url)
        code == StatusOK ? data : false
      end

      def image_exif(url)
        code, data = Fop::Image.exif(url)
        code == StatusOK ? data : false
      end

      def image_mogrify_preview_url(source_image_url, options)
        Fop::Image.mogrify_preview_url(source_image_url, options)
      end

      def image_mogrify_save_as(bucket, key, source_image_url, options)
        code, data = Storage.image_mogrify_save_as(bucket, key, source_image_url, options)
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

end # module Qiniu

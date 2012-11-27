# -*- encoding: utf-8 -*-

module Qiniu
  module RS

    class Exception < RuntimeError
    end

    class ResponseError < Exception
      attr_reader :response

      def initialize(message, response = nil)
        @response = response
        super(message)
      end

      def http_code
        @response.code.to_i if @response
      end

      def http_body
        @response.body if @response
      end

      def inspect
        "#{message}: #{http_body}"
      end
    end

    class RequestFailed < ResponseError
      def message
        "HTTP status code: #{http_code}. Response body: #{http_body}"
      end

      def to_s
        message
      end
    end

    class UploadFailedError < Exception
      def initialize(status_code, response_data)
        data_string = response_data.map { |key, value| %Q(:#{key.to_s} => #{value.to_s}) }
        msg = %Q(Uploading Failed. HTTP Status Code: #{status_code}. HTTP response body: #{data_string.join(', ')}.)
        super(msg)
      end
    end

    class FileSeekReadError < Exception
      def initialize(fpath, block_index, seek_pos, read_length, result_length)
        msg =  "Reading file: #{fpath}, "
        msg += "at block index: #{block_index}. "
        msg += "Expected seek_pos:#{seek_pos} and read_length:#{read_length}, "
        msg += "but got result_length: #{result_length}."
        super(msg)
      end
    end

    class BlockSizeNotMathchError < Exception
      def initialize(fpath, block_index, offset, restsize, block_size)
        msg  = "Reading file: #{fpath}, "
        msg += "at block index: #{block_index}. "
        msg += "Expected offset: #{offset}, restsize: #{restsize} and block_size: #{block_size}, "
        msg += "but got offset+restsize=#{offset+restsize}."
        super(msg)
      end
    end

    class BlockCountNotMathchError < Exception
      def initialize(fpath, block_count, checksum_count, progress_count)
        msg  = "Reading file: #{fpath}, "
        msg += "Expected block_count, checksum_count, progress_count is: #{block_count}, "
        msg += "but got checksum_count: #{checksum_count}, progress_count: #{progress_count}."
        super(msg)
      end
    end

    class MissingArgsError < Exception
      def initialize(missing_keys)
        key_list = missing_keys.map {|key| key.to_s}.join(' and the ')
        super("You did not provide both required args. Please provide the #{key_list}.")
      end
    end

    class MissingAccessToken < MissingArgsError
      def initialize
        super([:access_token])
      end
    end

    class MissingRefreshToken < MissingArgsError
      def initialize
        super([:refresh_token])
      end
    end

    class MissingUsernameOrPassword < MissingArgsError
      def initialize
        super([:username, :password])
      end
    end

    class InvalidArgsError < Exception
      def initialize(invalid_keys)
        key_list = invalid_keys.map {|key| key.to_s}.join(' and the ')
        super("#{key_list} should not be empty.")
      end
    end

    class MissingConfError < Exception
      def initialize(missing_conf_file)
        super("Error, missing #{missing_conf_file}. You must have #{missing_conf_file} to configure your client id and secret.")
      end
    end

    class NoSuchFileError < Exception
      def initialize(missing_file)
        super("Error, no such file #{missing_file}.")
      end
    end

  end
end

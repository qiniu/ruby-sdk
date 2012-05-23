# -*- encoding: utf-8 -*-

module Qiniu
  module RS

    class Exception < RuntimeError
      def to_s
        inspect
      end
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
        "HTTP status code #{http_code}"
      end

      def to_s
        message
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

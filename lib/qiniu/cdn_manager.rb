require 'json'

module Qiniu
  class CDNManager
    class << self
      def refresh_urls(urls)
        refresh(urls: Array(urls))
      end

      def refresh_dirs(dirs)
        refresh(dirs: Array(dirs))
      end

      def refresh(opts = {})
        body = {}
        unless opts[:urls].nil? || opts[:urls].empty?
          body[:urls] = opts[:urls]
        end
        unless opts[:dirs].nil? || opts[:dirs].empty?
          body[:dirs] = opts[:dirs]
        end
        post_json(refresh_url, body)
      end

      def prefetch(urls)
        post_json(prefetch_url, urls: Array(urls))
      end

      private

      def refresh_url
        "#{Config.settings[:cdn_host]}/v2/tune/refresh"
      end

      def prefetch_url
        "#{Config.settings[:cdn_host]}/v2/tune/prefetch"
      end

      def post_json(url, body)
        HTTP.api_post(url, body.to_json,
          headers: {
            'Authorization' => "QBox #{Auth.generate_acctoken(url)}",
            'Content-Type' => 'application/json'
          }
        )
      end
    end
  end
end

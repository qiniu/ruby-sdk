# -*- encoding: utf-8 -*-
# vim: sw=2 ts=2

require 'qiniu/adt'
require 'qiniu/http'

module Qiniu
  module Fop
    module Persistance

      class PfopPolicy
        include ADT::Policy

        private
        def initialize(bucket,
                       key,
                       fops,
                       notify_url)
          @bucket     = bucket
          @key        = key
          @notify_url = notify_url

          self.fops!(fops)
        end # initialize

        public
        PARAMS = {
          # 字符串类型参数
          :bucket     =>  "bucket",
          :key        =>  "key",
          :fops       =>  "fops",
          :notify_url =>  "notifyURL",
          :pipeline   =>  "pipeline",

          # 数值类型参数
          :force      =>  "force"
        } # PARAMS

        PARAMS.each_pair do |key, fld|
          attr_accessor key
        end

        def params
          return PARAMS
        end # params

        def fops! (fops)
          if fops.is_a?(Hash) then
            fops = fops.values
          end

          if fops.is_a?(Array) then
            new_fops = []
            fops.each do |v|
              if v.is_a?(ApiSpecification) then
                new_fops.push(v.to_s)
              end
            end

            @fops = new_fops.join(";")
          else
            @fops = fops.to_s
          end
        end # fops!

        def force!
          @force = 1
        end # force!

        alias :to_s :to_json
      end # class PfopPolicy

      class << self

        API_HOST = 'http://api.qiniu.com'

        PFOP_URL = API_HOST + '/pfop/'

        def pfop (args)
          ### 生成fop指令串
          if args.is_a?(PfopPolicy) then
            # PfopPolicy的各个字段按固定顺序组织
            body = args.to_query_string()
          elsif args.is_a?(Hash) then
            # 无法保证固定字段顺序
            body = HTTP.generate_query_string(args)
          else
            # 由调用者保证固定字段顺序
            body = args.to_s
          end

          ### 发送请求
          return HTTP.management_post(PFOP_URL, body)
        end # pfop

        PREFOP_URL = API_HOST + '/status/get/prefop?id='

        def prefop (persistent_id)
          ### 抽取persistentId
          if persistent_id.is_a?(Hash) then
            pid = persistent_id['persistentId']
          else
            pid = persistent_id.to_s
          end

          ### 发送请求
          url = PREFOP_URL + pid
          return HTTP.api_get(url)
        end # prefop

        def generate_p1_url (url, fop)
          # 如果fop是ApiSpecification，则各字段按固定顺序组织，保证一致性
          # 否则由调用者保证固定字段顺序
          fop = CGI.escape(fop.to_s).gsub('+', '%20')

          ### 生成url
          return url + '?p/1/' + fop
        end # generate_pl_url

      end # class << self

    end # module Persistance
  end # module Fop
end # module Qiniu

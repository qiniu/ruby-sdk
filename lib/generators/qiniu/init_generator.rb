module Qiniu
  class InitGenerator < Rails::Generators::Base
    source_root File.expand_path("../../templates", __FILE__)

    def init
      template "qiniu.rb", "config/initializers/qiniu.rb"
      puts <<-eos
        Please replace <YOUR_ACCESS_KEY> with your real access_key
        replace <YOUR_SECRET_KEY> with your real secret_key in config/initializers/qiniu.rb
      eos
    end
  end
end

$LOAD_PATH.push File.expand_path(__dir__ + '/lib')
require 'logger'

module WeightBattle

  # Test::Controller
  class Controller < Sinatra::Base
    register Sinatra::ConfigFile
    register Sinatra::Namespace
    helpers Sinatra::JSON
    helpers Sinatra::ContentFor
    enable :inline_templates

    set :environments, %w{development staging production}
    config_file __dir__ + '/config/app.yml'

    configure do
      use Rack::MethodOverride
      use Rack::ETag
      use Rack::Session::Memcache, memcache_server: settings.memcached,
        expire_after: settings.expire_after
      use Rack::Protection

      disable :show_exceptions
      set :log_file, STDOUT if settings.logging && settings.log_file.nil?
      set :server, :puma

      Sequel.extension :core_extensions, :blank, :sql_expr
      Sequel::Model.plugin :dataset_associations
      Sequel::Model.plugin :eager_each
      Sequel::Model.plugin :schema
      Sequel::Model.plugin :touch
      Sequel::Model.plugin :force_encoding, 'UTF-8'
      WeightBattle::DB = Sequel.connect(
        adapter: 'mysql2', host: settings.db_host,
        database: settings.db_schema, user: settings.db_user,
        password: settings.db_password
      )
      Sequel::MySQL.default_engine = 'InnoDB'
      Sequel::MySQL.default_charset = 'utf8'
      Sequel::MySQL.default_collate = 'utf8_bin'
      require 'models'

      set :root, __dir__
      set :default_locale, 'ja'

    end

    configure :development do
      register Sinatra::Reloader

      enable :show_exceptions
      enable :dump_errors
    end
    
    before do
      @title="目標達成コンテスト"
    end

    get '/' do
      slim :index
    end

    get '/entry/?' do
      slim :entry
    end

    post '/entry/?' do
      @acheivement = Model::Acheivement.new
      @acheivement.registrant = params[:registrant]
      @acheivement.acheivement = params[:acheivement]
      @acheivement.score = params[:score]
      @acheivement.updown = params[:updown]
      @acheivement.save
      redirect '/'
    end

    post '/confirm' do
      @registrant = params[:registrant]
      @weightBefore = params[:weightBefore].to_f
      @weightAfter = params[:weightAfter].to_f
      @percentage = (@weightAfter - @weightBefore)/@weightBefore * 100
      @updown = 0
      @updown = @percentage/@percentage.abs if @percentage != 0
      @goal = params[:sex].to_i == 1 ? 3.0 : 2.0
      @score = (1.0 - @percentage.abs / @goal) * 100
      @acheivement = (100 - @score).abs
      slim :confirm
    end

    get '/ranking' do
      @ranking = Model::Acheivement.order(:abs.sql_function(:score)).limit(5)
      slim :ranking
    end


  end
end

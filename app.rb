$LOAD_PATH.push File.expand_path(__dir__ + '/lib')
require 'logger'
require 'validator'
require 'active_support'
require 'active_support/core_ext/hash'
require 'active_support/hash_with_indifferent_access'

Oj.default_options = {mode: :compat}
module WeightBattle

  class Controller < Sinatra::Base
    register Sinatra::ConfigFile

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
      @title = settings.app_name
    end

    get '/' do
      slim :index
    end

    get '/entry/?' do
      @message = (Oj.load(session[:message] || '{}')).with_indifferent_access
      @params = (Oj.load(session[:params] || '{}')).with_indifferent_access
      slim :entry
    end

    post '/entry/?' do
      session.delete(:message)
      @acheivement = Model::Acheivement.new
      @acheivement.registrant = params[:registrant]
      @acheivement.acheivement = params[:acheivement]
      @acheivement.updown = params[:updown]
      unless @acheivement.valid?
        logger.error("error occured: #{@acheivement.errors}")
        logger.error("invalid data: #{@params}")
        session[:message] = Oj.dump(@acheivement.errors)
        redirect '/entry'
      end
      @acheivement.save
      session.delete(:params)
      redirect '/'
    end

    post '/confirm' do
      session.delete(:message)
      session.delete(:params)
      @errors = HashWithIndifferentAccess.new
      msg = settings.message.with_indifferent_access
      @errors[:registrant] = msg[:registrant][:is_null] if params[:registrant].blank?
      if params[:weightBefore].blank?
        @errors[:weightBefore] = msg[:weight_before][:is_null]
      elsif !params[:weightBefore].float?
        @errors[:weightBefore] = msg[:is_not_digit]
      end
      if params[:weightAfter].blank?
        @errors[:weightAfter] = msg[:weight_after][:is_null]
      elsif !params[:weightAfter].float?
        @errors[:weightAfter] = msg[:is_not_digit]
      end
      if params[:updown].blank? || !params[:updown].integer?
        @errors[:updown] = msg[:updown][:is_null]
      else
        updown = params[:updown].to_i
        @errors[:updown] = msg[:updown][:is_null] if updown != 1 && updown != -1
      end
      if params[:sex].blank? || !params[:sex].integer?
        @errors[:sex] = msg[:sex][:is_null]
      else
        sex = params[:sex].to_i
        @errors[:sex] = msg[:sex][:is_null] if sex != 1 && sex != 2
      end
      session[:params] = Oj.dump(params)
      if @errors.size > 0
        session[:message] = Oj.dump(@errors)
        redirect back
      end

      @weight_before = params[:weightBefore].to_f
      @weight_after = params[:weightAfter].to_f
      @updown = updown
      @registrant = params[:registrant]
      offset_rate = sex == 1 ? 3.0 : 2.0
      @mark = @weight_before * (100 + offset_rate * updown) / 100
      @acheivement = 100 - (@mark - @weight_after).abs / @mark * 100
      slim :confirm
    end

    get '/ranking' do
      @ranking = Model::Acheivement.order(:acheivement.desc).limit(5)
      slim :ranking
    end
  end
end

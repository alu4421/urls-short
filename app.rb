#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'haml'
require 'uri'
require 'pp'
#require 'socket'
require 'data_mapper'

DataMapper.setup( :default, ENV['DATABASE_URL'] || 
                            "sqlite3://#{Dir.pwd}/db/my_shortened_urls.db" )
DataMapper::Logger.new($stdout, :debug)
DataMapper::Model.raise_on_save_failure = true 

require_relative 'model'

DataMapper.finalize

#DataMapper.auto_migrate!
DataMapper.auto_upgrade! # No borra información , actualiza.

Base = 36 #base alfanumerica 36, no contiene la ñ para la ñ incorporar la base 64.

get '/' do
  @list = ShortenedUrl.all(:order => [ :id.asc ], :limit => 20)
  haml :index
end

post '/' do
  uri = URI::parse(params[:url])
  if uri.is_a? URI::HTTP or uri.is_a? URI::HTTPS then
    begin
      if params[:opc_url] == ""
        @short_url = ShortenedUrl.first_or_create(:url => params[:url])
      else
        @short_opc_url = ShortenedUrl.first_or_create(:url => params[:url], :opc_url => params[:opc_url])
      end
    rescue Exception => e
      puts "EXCEPTION!"
      pp @short_url
      puts e.message
    end
  else
    logger.info "Error! <#{params[:url]}> is not a valid URL"
  end
  redirect '/'
end

get '/:shortened' do
  #URLs sin parametros urls corto, por lo que se usara la id
  short_url = ShortenedUrl.first(:id => params[:shortened].to_i(Base))
  #URLs con parametros urls corto, por lo que se usara el campo opc_url
  short_opc_url = ShortenedUrl.first(:opc_url => params[:shortened])

  if short_opc_url #Si tiene información, entonces devolvera por opc_ulr
    redirect short_opc_url.url, 301
  else
    redirect short_url.url, 301
  end
end


error do haml :index end

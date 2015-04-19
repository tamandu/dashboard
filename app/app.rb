#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require 'sinatra/base'
require 'erb'

require_relative 'routes/init'
require_relative 'models/init'

class Dashboard < Sinatra::Base
  
  set :public_folder, File.expand_path('../../public', __FILE__)
  set :views, File.expand_path('../views', __FILE__)
  
  configure do
    enable :method_override
    enable :sessions
  end
  
  #not found
  error 404 do
    '<h1>Not found</h1>'
  end
  
  not_found do
  end
  
end
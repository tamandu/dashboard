#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Dashboard < Sinatra::Base
  get '/' do
    erb :index
  end
end
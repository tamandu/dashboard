# -*- coding: utf-8 -*-
#!/usr/bin/env ruby

require 'sequel'
require 'mysql2'
require 'yaml'

db_config = YAML.load_file('../config/db_config.yml')

DB = Sequel.connect("mysql2://#{db_config[:username]}:#{db_config[:password]}@#{db_config[:host]}/#{db_config[:database]}")

require_relative 'network'
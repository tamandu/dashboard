#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class Dashboard < Sinatra::Base
  
  
  #######################################
  ########### Private Network ###########
  #######################################
  get '/network/private' do
    networks = Network.order_by_network_address
    erb 'network/private/private_network_layout'.to_sym do
      erb 'network/private/list'.to_sym, :locals => {:networks => networks}
    end
  end
  
  get '/network/private/new' do
    erb 'network/private/private_network_layout'.to_sym do
      erb 'network/private/new'.to_sym, :locals => {:errors => session[:errors]}
    end
  end
  
  post '/network/private' do
    begin
      #insert network record to network table
      network = Network.create(:network_address => params[:network_address], :subnet_mask => params[:subnet_mask], :vlan_id => params[:vlan_id], :comment => params[:comment])
      
      #create ip table in the network
      DB.create_table "iplist_#{network.id}".to_sym do
        primary_key :id
        String      :ip_address
        String      :hostname
        String      :comment
      end
      
      #insert ip record ipto ip table in the network
      network_range = IPAddress::IPv4.new(network.prefix)
      network_range.each_with_index do |ip, i|
        case i
        when 0 then
          DB["iplist_#{network.id}".to_sym].insert(:ip_address => ip.address, :hostname => '', :comment => 'network address')
          PrivateIP.create(:network_id => network.id, :ip_address => ip.address, :comment => 'network address')
        when (network_range.count - 1) then
          DB["iplist_#{network.id}".to_sym].insert(:ip_address => ip.address, :hostname => '', :comment => 'broadcast address')
          PrivateIP.create(:network_id => network.id, :ip_address => ip.address, :comment => 'broadcast address')
        else
          DB["iplist_#{network.id}".to_sym].insert(:ip_address => ip.address, :hostname => '', :comment => '')
          PrivateIP.create(:network_id => network.id, :ip_address => ip.address, :comment => '')
        end
      end
      
      redirect '/network/private'
    rescue Sequel::ValidationFailed => e
      erb 'network/private/private_network_layout'.to_sym do
        erb 'network/private/new'.to_sym, :locals => {:errors => e.errors}
      end
    end
  end
  
  get '/network/private/:network_id/edit' do
    if network = Network[:id => params[:network_id]]
      erb 'network/private/private_network_layout'.to_sym do
        erb 'network/private/edit'.to_sym, :locals => {:network => network, :errors => session[:errors]}
      end
    else
      halt 404
    end
  end
  
  put '/network/private/:network_id' do
    if network = Network[:id => params[:network_id]]
      begin
        network.update(:vlan_id => params[:vlan_id], :comment => params[:comment])
        redirect '/network/private'
      rescue Sequel::ValidationFailed => e
        erb 'network/private/private_network_layout'.to_sym do
          erb 'network/private/edit'.to_sym, :locals => {:network => network, :errors => e.errors}
        end
      end
    else
      halt 404
    end
  end
  
  delete '/network/private/:network_id' do
    if network = Network[:id => params[:network_id]]
      network.delete
      DB.drop_table("iplist_#{network.id}".to_sym)
      PrivateIP.where(:network_id => params[:network_id]).delete
      redirect '/network/private'
    else
      halt 404
    end
  end
  
  get '/network/private/:network_id/ip' do
    if network = Network[:id => params[:network_id]]
      ip_list = DB["iplist_#{params[:network_id]}".to_sym].all
      erb 'network/private/private_network_layout'.to_sym do
        erb 'network/private/ip/list'.to_sym, :locals => {:network => network, :ip_list => ip_list}
      end
    else
      halt 404
    end
  end
  
  get '/network/private/:network_id/ip/:ip_id/edit' do
    if ip = DB["iplist_#{params[:network_id]}".to_sym][:id => params[:ip_id]]
      erb 'network/private/private_network_layout'.to_sym do
        erb 'network/private/ip/edit'.to_sym, :locals => {:network_id => params[:network_id], :ip => ip}
      end
    else
      halt 404
    end
  end
  
  put '/network/private/:network_id/ip/:ip_id' do
    DB["iplist_#{params[:network_id]}".to_sym].where(:id => params[:ip_id]).update(:hostname => params[:hostname], :comment => params[:comment])
    redirect "/network/private/#{params[:network_id]}/ip"
  end
  
  
  ######################################
  ########### Global Network ###########
  ######################################
  get '/network/global' do
  	global_ips = GlobalIP.order_by_global_ip
    erb 'network/global/global_network_layout'.to_sym do
      erb 'network/global/list'.to_sym, :locals => {:global_ips => global_ips}
    end
  end
  
  get '/network/global/new' do
    erb 'network/global/global_network_layout'.to_sym do
      erb 'network/global/new'.to_sym, :locals => {:errors => session[:errors]}
    end
  end
  
  post '/network/global' do
  	begin
  		GlobalIP.create(:global_ip => params[:global_ip], :mapped_ip => params[:mapped_ip], :hostname => params[:hostname], :comment => params[:comment])
  		redirect '/network/global'
  	rescue Sequel::ValidationFailed => e
  	  erb 'network/global/global_network_layout'.to_sym do
        erb 'network/global/new'.to_sym, :locals => {:errors => e.errors}
      end
  	end
  end
  
  get '/network/global/:global_id/edit' do
    if global_ip = GlobalIP[:id => params[:global_id]]
      erb 'network/global/global_network_layout'.to_sym do
        erb 'network/global/edit'.to_sym, :locals => {:global_ip => global_ip, :errors => session[:errors]}
      end
    else
      halt 404
    end
  end
  
  put '/network/global/:global_id' do
    if global_ip = GlobalIP[:id => params[:global_id]]
      begin
        global_ip.update(:mapped_ip => params[:mapped_ip], :hostname => params[:hostname], :comment => params[:comment])
        redirect '/network/global'
      rescue Sequel::ValidationFailed => e
        erb 'network/global/global_network_layout'.to_sym do
          erb 'network/global/edit'.to_sym, :locals => {:global_ip => global_ip, :errors => e.errors}
        end
      end
    else
      halt 404
    end
  end
  
  delete '/network/global/:global_id' do
    if global_ip = GlobalIP[:id => params[:global_id]]
      global_ip.delete
      redirect '/network/global'
    else
      halt 404
    end
  end
  
end
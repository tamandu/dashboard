# -*- coding: utf-8 -*-
#!/usr/bin/env ruby

require 'ipaddress'

class Network < Sequel::Model
  plugin :schema
  plugin :validation_helpers
  
  #define table schema
  set_schema do
    primary_key :id
    String      :network_address, :null => false
    String      :subnet_mask,     :null => false
    Integer     :vlan_id,         :null => true
    String      :comment,     		:null => true
  end
  
  create_table unless table_exists?
  
  #define validation
  def validate
    super
    
    #network address
    if !network_address || network_address.empty?
      errors.add(:network_address, 'network address is required')
    else
      if IPAddress::valid_ipv4?(network_address)
        errors.add(:network_address, 'network address is not private scope') unless IPAddress::IPv4.new(network_address).private?
        errors.add(:network_address, 'network address already exists') if new? && PrivateIP[:ip_address => network_address]
      else
        errors.add(:network_address, 'network address is invalid')
      end
    end
    
    #subnet mask
    if !subnet_mask || subnet_mask.empty?
      errors.add(:subnet_mask, 'subnet mask is required')
    else
      errors.add(:subnet_mask, 'subnet mask is not ip address') unless IPAddress.valid_ipv4_netmask?(subnet_mask)
    end
    
    #vlan id
    if vlan_id
      errors.add(:vlan_id, 'vlan id is not integer') unless is_integer?(vlan_id)
      errors.add(:vlan_id, 'vlan id should be between 1 and 4095') unless vlan_id.to_i.between?(1, 4095)
      errors.add(:vlan_id, 'vlan id is already used') if Network[:vlan_id => vlan_id] && (Network[:vlan_id => vlan_id].id) != id
    end
  end
  
  def prefix
    network = IPAddress::IPv4.new(network_address + '/' + subnet_mask)
    network.address + '/' + network.prefix.to_s
  end
  
  #class method
  def self.order_by_network_address
    sort { |x, y| IPAddress::IPv4.new(x.prefix) <=> IPAddress::IPv4.new(y.prefix) }
  end
  
  #private method
  private
  def is_integer?(string)
    true if Integer(string) rescue false
  end  
end


class PrivateIP < Sequel::Model
  #define table schema
  plugin :schema
  plugin :validation_helpers
  
  #define table schema
  set_schema do
    primary_key :id
    Integer     :network_id,  :null   => false
    String      :ip_address,  :null   => false
    String      :comment,     :null   => true
    index       :ip_address,  :unique => true
  end
  
  create_table unless table_exists?
end


class GlobalIP < Sequel::Model
  #define table schema
  plugin :schema
  plugin :validation_helpers
  
  #define table schema
  set_schema do
    primary_key :id
    String      :global_ip,   :null => false
    String      :mapped_ip,   :null => true
    String      :hostname,    :null => true
    String      :comment,     :null => true
  end
  
  create_table unless table_exists?
  
  #define validation
  def validate
    super
    
    #global ip address
    if !global_ip || global_ip.empty?
      errors.add(:global_ip, 'global ip address is required')
    else
      if IPAddress::valid_ipv4?(global_ip)
        errors.add(:global_ip, 'global ip address is not global scope') if IPAddress::IPv4.new(global_ip).private?
        errors.add(:global_ip, 'global ip address already exists') if new? && GlobalIP[:global_ip => global_ip]
      else
        errors.add(:global_ip, 'global ip address is invalid')
      end
    end
    
    #mapped ip address
    if mapped_ip
      if IPAddress::valid_ipv4?(mapped_ip)
        errors.add(:mapped_ip, 'mapped ip address is not private scope') unless IPAddress::IPv4.new(mapped_ip).private?
        if PrivateIP[:ip_address => mapped_ip]
          errors.add(:mapped_ip, "mapped ip address is network address") if PrivateIP[:ip_address => mapped_ip].comment == "network address"
          errors.add(:mapped_ip, "mapped ip address is broadcast address") if PrivateIP[:ip_address => mapped_ip].comment == "broadcast address"
          errors.add(:mapped_ip, "mapped ip address is already mapped to another global ip address") if GlobalIP[:mapped_ip => mapped_ip] && (GlobalIP[:mapped_ip => mapped_ip].id) != id
        else
          errors.add(:mapped_ip, "mapped ip address doesn't exist in private network")
        end
      else
        errors.add(:mapped_ip, 'mapped ip address is invalid')
      end
    end
    
    #hostname
    if mapped_ip
    	errors.add(:network_address, 'hostname is required') if !hostname || hostname.empty?
    end
  end
  
  #class method
  def self.order_by_global_ip
    sort { |x, y| IPAddress::IPv4.new(x.global_ip) <=> IPAddress::IPv4.new(y.global_ip) }
  end
end
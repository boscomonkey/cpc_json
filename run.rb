#!/usr/bin/env ruby

require 'json'
require_relative 'cpc_json'

if fname = ARGV[0]
  cj = CpcJson.new fname
  obj = cj.parse
  puts JSON.pretty_generate(obj)
else
  raise "USAGE: #{$0} CPC_XML"
end

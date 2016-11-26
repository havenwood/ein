# frozen_string_literal: true

require 'roda'
require_relative 'lib/ein'

class App < Roda
  DATA_FILE = 'data.pstore'

  plugin :json

  opts[:ein] = if File.exist? DATA_FILE
    Marshal.load File.read DATA_FILE
  else
    EIN.instance.fetch_data
    File.write DATA_FILE, Marshal.dump(EIN.instance)
    EIN.instance
  end

  route do |r|
    # GET /000003154 request
    r.is ':ein' do |ein|
      opts[:ein].find_ein(ein) or response.status = 404
    end
  end
end

run App.freeze.app

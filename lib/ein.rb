# frozen_string_literal: true

require 'http'
require 'zipruby'
require 'csv'
require 'singleton'

class EIN
  include Singleton

  attr_accessor :data

  def initialize
    @data = []
  end

  def fetch_data url: 'https://apps.irs.gov/pub/epostcard/data-download-pub78.zip'
    @data = parse unzip download url
  end

  def find ein
    @data.assoc ein
  end

  def inspect
    "#<#{self.class.name}:#{@data.size} cached>"
  end

  def _dump depth = -1
    Marshal.dump @data, depth
  end

  def self._load string
    instance.data = Marshal.load string
    instance
  end

  private

  def download url
    puts "Downloading #{url} ..."
    HTTP.follow.get(url).to_s
  end

  def unzip zip
    puts 'Unzipping data ...'
    Zip::Archive.open_buffer(zip) { |archive| archive.map(&:read).join }
  end

  def parse data
    puts 'Parsing data ...'
    CSV.new(data, col_sep: '|').reject &:empty?
  end
end

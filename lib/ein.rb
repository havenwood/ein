# frozen_string_literal: true

require 'http'
require 'zipruby'
require 'csv'
require 'singleton'

class EIN
  include Singleton

  attr_accessor :data

  def initialize url: 'https://apps.irs.gov/pub/epostcard/', filename: 'data-download-pub78.zip'
    @url = url
    @filename = filename
    @data = []
  end

  def fetch_data
    @data = parse_data unzip download_zip
  end

  def find_ein ein
    @data.assoc ein
  end

  def inspect
    "#<EIN:#{@data.size} cached>"
  end

  def _dump depth = -1
    Marshal.dump @data, depth
  end

  def self._load string
    instance.data = Marshal.load string
    instance
  end

  private

  def download_zip
    puts "Downloading #{@filename} from #{@url} ..."
    HTTP.follow.get(File.join @url, @filename).to_s
  end

  def unzip zip
    puts "Unzipping #{@filename} ..."
    text = nil
    Zip::Archive.open_buffer zip do |archive|
      text = archive.map(&:read).join
    end
    text
  end

  def parse_data text
    puts 'Parsing data ...'
    CSV.new(text, col_sep: '|').reject &:empty?
  end
end
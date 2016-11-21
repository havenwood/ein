# frozen_string_literal: true

require 'roda'
require 'http'
require 'zipruby'
require 'csv'
require 'json'

class EIN
  def initialize url: 'http://apps.irs.gov/pub/epostcard/', filename: 'data-download-pub78'
    %w[zip txt json].each do |ext|
      instance_variable_set "@#{ext}_filename", "#{filename}.#{ext}"
    end

    if File.exist? @json_filename
      @array = load_json_from_disk
    elsif File.exist? @txt_filename
      load_txt_from_disk
      @array = parse_txt
      save_json_to_disk
    else
      if File.exist? @zip_filename
        zip = load_zip_from_disk
      else
        zip = download_zip url
        save_zip_to_disk zip
      end

      unzip zip
      save_txt_to_disk
      @array = parse_txt
      save_json_to_disk
    end
  end

  def to_a
    @array
  end

  def find_ein ein
    @array.assoc ein
  end

  def inspect
    "#<EIN:...>"
  end

  private

  def load_zip_from_disk
    puts "Loading #{@zip_filename} file from disk ..."
    File.read @zip_filename
  end

  def download_zip url
    puts "Downloading #{@zip_filename} from #{url} ..."
    HTTP.follow.get(File.join url, @zip_filename).to_s
  end

  def save_zip_to_disk zip
    puts "Saving #{@zip_filename} to disk ..."
    File.write @zip_filename, zip
  end

  def unzip zip
    puts "Unzipping #{@zip_filename} ..."
    Zip::Archive.open_buffer zip do |archive|
      @text = archive.map(&:read).join
    end
  end

  def save_txt_to_disk
    puts "Saving #{@txt_filename} to disk ..."
    File.write @txt_filename, @text
  end

  def parse_txt
    puts "Parsing data from #{@txt_filename} ..."
    csv = CSV.new @text, col_sep: '|'
    remove_instance_variable :@text
    csv.to_a.reject &:empty?
  end

  def load_txt_from_disk 
    puts "Loading #{@txt_filename} from disk ..."
    @text = File.read @txt_filename
  end

  def load_json_from_disk
    puts "Loading #{@json_filename} from disk ..."
    JSON.parse File.read @json_filename
  end

  def save_json_to_disk
    puts "Saving #{@json_filename} to disk ..."
    File.write @json_filename, @array.to_json
  end
end

class App < Roda
  plugin :json

  opts[:ein] = EIN.new

  route do |r|
    # GET /000003154 request
    r.is ':ein' do |ein|
      opts[:ein].find_ein(ein) or response.status = 404
    end
  end
end

run App.freeze.app

require 'benchmark'
require_relative 'libs/debreader-libarchive-ruby'

class InfoExtractor
  attr_reader :info

  def initialize(path, exclude_dir)
    @scan_path = path
    @exclude_dir = exclude_dir
    get_file_list
    read_package_info
  end


  private
  def get_file_list
    Dir.chdir @scan_path
    @filenames = (Dir['**/*.deb']). # recursively get .deb filenames
    drop_while { |x| x.include?(@exclude_dir+'/')} # discard files in exclude_dir
    @filenames
  end

  def read_package_info
    @info = []
    @filenames.collect do | filename |
      path = File.realpath filename
      pkg = DebReaderLibArchiveRuby::Package.new(path)
      @info += [ path, pkg['Package'], pkg['Version'], pkg['Architecture'] ]
    end
  end
end

path = '/linux/linux/repo/trusty/debs/M'
filenames = []

Benchmark.bm do |bm|

  bm.report do
    @scanner = InfoExtractor.new(path, 'to_delete')
    p @scanner.info.size
  end
end

# info = @scanner.info
# puts info
require 'benchmark'
require_relative 'libs/debreader_swig'

class DebFilesScanner
  include Enumerable
  attr_reader :info

  # path is the path of the folder containing
  # .deb files
  def initialize(debs_dir, dest_folder='.')
    @debs_dir = debs_dir
    @dest_dir = dest_folder # the folder where .debs will be moved
    @info = []  # array to hold all control files' content

    get_file_list
    extract_pkg_info
    @info # return the info Array
  end

  # methods for convenience of getting @info size
  def size
    @info.size
  end

  # implemeting each for making it collection
  def each &block
    @info.each do |pkg|
      if block_given?
        block.call pkg
      else
        yield pkg
      end
    end
  end

private
  # Get the list of the deb files
  # recursively from $debs_dir into an array
  def get_file_list
    Dir.chdir @debs_dir
    @filenames = (Dir['**/*.deb']). # recursively get .deb filenames
    drop_while { |x| x.include?(@dest_dir+'/')} # discard files in @dest_dir
  end

  def extract_pkg_info
    @filenames.collect do |file|
      pkg = DebReaderSwig::Package.new(file)
      @info.push pkg
    end
  end
end

# -------------------------------------Test---------------------------

a = DebFilesScanner.new('debs','to_delete')

puts a.find { |x| puts x['Version'] if x['Package'] == 'nautilus'}
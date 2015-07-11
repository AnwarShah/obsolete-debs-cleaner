require_relative 'deb_helpers.rb'
require_relative 'debreader_swig'

class DebFilesScanner
  include DebHelpers
  include Enumerable, Comparable

  attr_reader :debs_info
  attr_accessor :debs_dir, :exclude_dir

  def initialize(debs_dir, exclude_dir='to_delete')
    @debs_dir = debs_dir
    @exclude_dir = 'to_delete' unless exclude_dir.empty?
    @debs_info = read_debs # get individual deb data
  end

  # methods for convenience of getting @info size
  def size
    @debs_info.size
  end

  # implemeting each for making it collection
  def each(&block)
    @debs_info.each do |pkg|
      if block_given?
        block.call pkg
      else
        yield pkg
      end
    end
  end

  # methods from comparable module
  # equality will be based on packages name, version and arch string
  # Equal if and only both objects have same packages file, for same version
  # and same arch
  def <=>other
    if size < other.size
      return -1
    elsif size > other.size
      return 1
    end
    # otherwise
    debs_str = @debs_info.collect { |x| x.to_s }.sort
    other_debs_str = other.collect { |x| x.to_s }.sort
    ret_value = 0
    (debs_str).zip(other_debs_str).each do |pkg_str_x, pkg_str_y|
      ret_value = pkg_str_x <=> pkg_str_y
      break if ret_value != 0
    end
    if [1, 0, -1].include?(ret_value)
      return ret_value
    end

    nil # means not comparable
  end

private # private methods
  def read_debs
    filenames = get_file_list(@debs_dir, @exclude_dir)
    extract_deb_info(filenames)
  end

end

require 'forwardable'
require_relative 'deb_file'

class NameMismatchError < StandardError; end;

class PackageDebs
  include Enumerable
  extend Forwardable

  # Collection of Debs for a single package
  attr_reader :package_name, :architecture

  def_delegators :@debs, :each, :[], :first, :last
  def_delegator :@debs, :[], :get

  # name is the package name
  # deb is an object of DebFile class
  def initialize(name, deb)
    @package_name = name
    @debs = [] #array to hold all instance

    if match_package?(deb)
      @architecture = deb.architecture
      @debs << deb
    end
  end

  def add(deb)
    @debs << deb if match_package?deb
  end

  def remove(deb)
    @debs.delete(deb)
  end

  def get_deb_path(index)
    @debs[index].path
  end

  def get_max_deb_size
    size = -1
    @debs.each { |d|
      size = d.raw_file_size if size < d.raw_file_size }
    size
  end

  def total_debs
    @debs.length
  end

  def sort
    @debs.sort!
  end

  def get_all
    @debs
  end

  def get_all_versions_string
    versions = []
    @debs.each { |v| versions << v.version }
    versions
  end

  def show_all_versions
    @debs.each do |deb|
      puts deb.version
    end
  end

  def show_all
    @debs.each do |deb|
      puts deb
    end
  end

  def to_s
    all_versions_str = get_all_versions_string.join(', ')
    "#{package_name}: #{all_versions_str}"
  end

  private
  def match_package?(deb)
    # check whether supplied deb and package name matched
    if @package_name == deb.package_name
      return true
    else
      raise NameMismatchError.new(
                "Package name doesn't match with supplied deb file's package.")
    end
  end

  alias_method :length, :total_debs
  alias_method :delete, :remove
  alias_method :<<, :add
end

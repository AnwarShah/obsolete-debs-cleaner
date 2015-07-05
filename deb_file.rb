require_relative 'deb_helpers'

class DebFile
  include Comparable

  attr_reader :control_file_content, :path, :file_size,
              :package_name, :version, :architecture,
              :maintainer, :installed_size,
              :depends, :recommends, :breaks, :replaces,
              :section, :description, :home_page

  def initialize(file_path)
    @path = File.realpath file_path
    @file_size = DebHelpers.pretty_file_size( File.size file_path )
    @control_file_content = DebHelpers.read_control_info(@path)
    @package_information = DebHelpers.parse_control_string(@control_file_content)

    @package_name = @package_information['Package']
    @version = @package_information['Version']
    @architecture = @package_information['Architecture']
    @maintainer = @package_information['Maintainer']
    @installed_size = @package_information['Installed-Size']
    @depends = @package_information['Depends']
    @recommends = @package_information['Recommends']
    @breaks = @package_information['Breaks']
    @replaces = @package_information['Replaces']

    @section = @package_information['Section']
    @description = @package_information['Description']
    @home_page = @package_information['Homepage']

  end

  def valid?
    @package_name.nil? || @version.nil? ? false : true
  end

  def <=>(otherObj)
    version1 = @version
    version2 = otherObj.version

    DebHelpers.compare_version(version1, version2)
  end

  def to_s
    "#{@package_name} #{@version} #{@architecture}"
  end

end

=begin
  AptVersion is a Ruby class to extract, analyze and compare
  version string of debian packages.
=end

require 'debian'

class AptPkg_Version
  include Comparable

  attr_reader :epoch, :upstream, :revision, :version

  def initialize(ver_string)

    ver_string = ver_string.partition(':') # is there an epoch?
    unless ver_string[2].empty?
      @epoch = ver_string[0]
      @has_epoch = true
    else
      @epoch = '0'
      @has_epoch = false
    end

    if @has_epoch # has an epoch
      ver_string = ver_string[2].rpartition('-')
    else
      ver_string = ver_string[0].rpartition('-')
    end

    # if first part is not empty, then there is a revision
    unless ver_string[0].empty?
      @upstream = ver_string[0]
      @revision = ver_string[2] # last part
      @has_revision = true
    else # otherwise, if empty
      @upstream = ver_string[2]
      @revision = '0'
      @has_revision = false
    end


    # construct full version string
    @version = "#{@epoch.to_s}:#{@upstream.to_s}"
    unless @revision == '0'
      @version += "-#{@revision.to_s}"
    end

    # Check for version string validity
    is_valid_version?

  end

  def to_s
    @version
  end

  def <=>(otherObj)
    # Compares the version of this object to the other object
    # if this is greater than other, return 1
    # if less, return -1
    # if equal , return 0
    # else return nil

    ver1 = @version
    ver2 = otherObj.version

    if Debian::Version.cmp_version(ver1, '>', ver2 )
      return 1

    elsif Debian::Version.cmp_version(ver1, '<', ver2 )
      return -1

    elsif Debian::Version.cmp_version(ver1, '=', ver2 )
      return 0

    else
      return nil
    end

  end

    # Make private
    private

  def is_valid_version?

    # Please check Ubuntu or debian policy guide for
    # versioning scheme

    # return true if matched with the most general rule
    return true if valid_epoch? && valid_upstream? && valid_revision?

    false # otherwise return false
  end

  def valid_epoch?

    return true if @has_epoch && @epoch.match(/\A[0-9]+\Z/)
    return true if !@has_epoch && @epoch == '0'

    raise InvalidAptVersion.new("Invalid epoch string: #{@epoch}")

  end

  def valid_upstream?

    if @has_epoch && @has_revision
      valid_regex = /\A[0-9]+[a-zA-Z0-9~.+-:]*\Z/

    elsif @has_epoch && !@has_revision
      valid_regex = /\A[0-9]+[a-zA-Z0-9~.+:]*\Z/

    elsif !@has_epoch && @has_revision
      valid_regex = /\A[0-9]+[a-zA-Z0-9~.+-]*\Z/

    else
      valid_regex = /\A[0-9]+[a-zA-Z0-9~.+]*\Z/
    end

    return true if @upstream.match(valid_regex)

    raise InvalidAptVersion.new(
              "Invalid upstream : #{@upstream}")
  end

  def valid_revision?

    return true if @has_revision && @revision.match(/\A[a-zA-Z0-9~.+]*\Z/)
    return true if !@has_revision && @revision == '0'

    raise InvalidAptVersion.new(
              "Invalid revision: #{@revision}")
  end

end


class InvalidAptVersion < ArgumentError
  # This is a simple extension to the Exception class
  # ArgumentError
  def initialize(error_msg)
    super error_msg
  end
end

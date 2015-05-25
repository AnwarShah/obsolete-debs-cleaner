=begin

Apt Version Comparison Library

Usage:
    vercmp(string1, string2)

Returns:
    -1 if ver1 less than (<) ver2
    0 if ver1 equal to (=) ver2
    1 if ver1 greater than (>) ver2

=end

class VerCompare
  attr_reader :epoch, :version, :revision

  def initialize(version)
    # Parses the `version` string into epoch, version and revision
    epoch = version.split(':')

    if epoch.length > 1 # We have an epoch
      val = epoch[0].to_i
      if val.between?(0, 9)
        @epoch = val
      else
        raise ArgumentError.new("Invalid version string")
      end
    else
      @epoch = 0
      epoch = ['0', epoch[0]] #Setup a fake list with epoch 0
    end

    version = epoch[1..-1].join('').split('-')

    if version.length > 1
      # We have a revision number
      @revision = version[-1] # last one is the revision
      @version = version[0...-1].join('')
    else
      # We don't have a revision
      @revision = ''
      @version = version[0]
    end

  end

end


class VerType

  attr_reader :val

  def initialize(val)
    @val = val
  end

  def type
    if @val.match(/^[[:alpha:]]+$/)
      return 'alpha'
    elsif @val.match(/^[[:digit:]]+$/)
      return 'digit'
    elsif @val == '~'
      return 'tilde'
    else
      return 'delimit'
    end
  end

  def order
    if @val == '~'
      return -1
    elsif @val.match(/^[[:digit:]]+$/) # digit
      return 0
    elsif !@val
      return 0
    elsif @val.match(/^[[:alpha:]]+$/) # alphabet
      return @val.ord
    else
      return @val.ord + 256
    end

  end

end

def compare_section(s1, s2)
  # Compare two version subsections

  types1 = s1.split(//).map { |x| VerType.new(x) }
  types2 = s2.split(//).map { |x| VerType.new(x) }

  # While there is more
  i=0
  while( i < types1.length && i < types2.length )
    if ! types1[i].type == types2[i].type
      # Check order
      if types1[i].order > types2[i].order
        return 1
      else
        return -1
      end
    end

    # Get more of same type for both
    j = i
    curtype = types1[i].type
    while j < types1.length && types1[j].type == curtype
      j += 1
    end
    str1 = (i...j).to_a.inject('') { |str, x | str += types1[x].val }

    j = i
    while j < types2.length && types2[j].type == curtype
      j += 1
    end
    str2 = (i...j).to_a.inject('') { |str, x| str += types2[x].val }

    # Compare
    if str1 > str2
      return 1
    elsif str1 < str2
      return -1
    else
      j += 1
    end

    i = j

  end

  if s1 > s2
    return 1
  elsif s1 < s2
    return -1
  else
    return 0
  end

end


def vercmp(ver1, ver2)
  # Compares 2 version strings

  # Returns
  # -1 if ver1 less than (<) ver2
  # 0 if ver1 equal to (=) ver2
  # 1 if ver1 greater than (>) ver2

  ver1 = VerCompare.new(ver1)
  ver2 = VerCompare.new(ver2)

  # Compare epochs
  if ver1.epoch > ver2.epoch
    return 1
  elsif ver1.epoch < ver2.epoch
    return -1
  end

  # Epochs are equal, compare version
  result = compare_section(ver1.version, ver2.version)
  if result != 0
    return result
  end

  # Compare revisions
  return compare_section(ver1.revision, ver2.revision)

end

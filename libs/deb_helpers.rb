require 'debian'

module DebHelpers

  class UserChoice

    attr_reader :selections

    def initialize(selection_str, options)
      @selection_s = selection_str
      @valid_options = options
      @options_count = @valid_options.length
      @selections = []  # user selected options

      parse_selections
    end

    def valid?
      @selections.uniq! # remove duplicates
      # check invalid range
      @selections.each  do |x|
        return false unless @valid_options.include?(x)
      end
      true # otherwise
    end # method valid?

    def set_new_selection(selection_s)
      @selection_s = selection_s
      parse_selections # parse new selection
    end

    private
    def parse_selections
      # selection string can contain only digits seperated by any non-digits
      @selections = @selection_s.chomp.split(/\D+/).keep_if { |v| v.length > 0 }
      @selections = @selections.map { |e| e.to_i }
    end

  end

  class DebPkgInfo
    include Comparable
    include DebHelpers

    attr_reader :version, :arch, :path, :size

    def initialize(version, arch, path, size)
      @version = version
      @arch  = arch
      @path =  path
      @size = size
    end

    def <=>(obj)
      compare_version(@version, obj.version)
    end

    def to_s
      "Ver: #{@version}, Arc: #{@arch}, Path: #{@path}, Size: #{@size}"
    end
  end # class DebPkgInfo

  def compare_version(ver1, ver2)
    if Debian::Version.cmp_version(ver1, '>', ver2)
      return 1

    elsif Debian::Version.cmp_version(ver1, '<', ver2)
      return -1

    elsif Debian::Version.cmp_version(ver1, '=', ver2)
      return 0

    else
      return nil
    end
  end

  def pretty_file_size(size_in_byte)
    sizes = {
        'B' => 1024,
        'KB' => 1024 * 1024,
        'MB' => 1024 * 1024 * 1024,
        'GB' => 1024 * 1024 * 1024 * 1024,
        'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }
    sizes.each_pair do |key, value|
      if size_in_byte <= value
        return "#{(size_in_byte / (value / 1024).round(2)).round(3) } #{key}"
      end
    end
  end

  def extract_deb_info(filenames)
    info = [] # array to hold all control files' content
    filenames.collect do |file|
      pkg = DebReaderSwig::Package.new(file)
      info.push pkg if  pkg.valid?
    end
    info
  end

  def format_exclude_dir(dir)
    if dir.length == 0
      return ''
    else
      return dir + '/'
    end
  end

  def get_file_list(debs_dir, exclude_dir)
    exclude_dir = format_exclude_dir(exclude_dir)
    Dir.chdir debs_dir
    filenames = (Dir['**/*.deb'])# recursively get .deb filenames

    if exclude_dir.length > 0
      filenames.reject! { |x| x.include?(exclude_dir) } # discard files in @dest_dir
    end
    filenames
  end

end

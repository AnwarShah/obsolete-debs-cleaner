require 'debian'

module DebHelpers

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

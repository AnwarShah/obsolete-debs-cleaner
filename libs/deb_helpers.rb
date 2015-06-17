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

  def extract_deb_info(filenames)
    info = [] # array to hold all control files' content
    filenames.collect do |file|
      pkg = DebReaderSwig::Package.new(file)
      info.push pkg
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

require 'debian'
require 'libarchive_rs'

module DebHelpers

  # @param [Object] filename
  def read_control_info(filename)
    control_file_contents = ''

    begin
      Archive.read_open_filename(filename) do |archive|
        while entry = archive.next_header
          path = entry.pathname.sub(/^\//, '')

          if path.include? 'control.tar.gz'
            control_tar_gz_data = archive.read_data
            control_gz_reader = Archive.read_open_memory(control_tar_gz_data)
            while control_entry = control_gz_reader.next_header
              if (control_entry.pathname).include? 'control'
                control_file_contents = control_gz_reader.read_data
              end
            end
          end
        end # while
      end # block
      return control_file_contents
    rescue Archive::Error => msg
      puts "Error while processing deb file: #{filename} (#{msg})"
      return
    end
  end

  def parse_control_string(control_file_contents)
    fields = {}
    control_file_contents.scan(/^([\w-]+?): (.*?)\n(?! )/m).each do |entry|
      field, value = entry
      fields[field] = value
    end
    unless fields['installed_size'].nil?
      fields['installed_size'] = fields['installed_size'].to_i * 1024
    end
    fields
  end

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

  def format_exclude_dir(dir)
    (dir.length == 0) ? '' : dir + '/'
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

  module_function :read_control_info, :parse_control_string,
                  :pretty_file_size, :compare_version
end

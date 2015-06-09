# The content of this script is collected from the debeasy gem
# Credit goes to actual writer

=begin
  This script reads deb file and extract information about the package
=end

require 'libarchive'

module DebReader

  class Package

    attr_reader :control_file_contents, :fields

    def initialize(path)
      @file_path = path
      @fields = {}
      extract_pkg_info
      parse_control_file
    end

    # method to get hash like entries
    def [](field)
      @fields.has_key?(field.to_s) ? @fields[field.to_s] : nil
    end

    # get all entries in an array
    def fields
      @fields.keys
    end

    # get package metadata as a hash
    def info_hash
      @fields
    end

    private

    def extract_pkg_info

      Archive.read_open_filename(@file_path) do |ar|
        while entry = ar.next_header do
          name = entry.pathname
          data = ar.read_data

          if name == 'control.tar.gz'
            control_tar_gz = Archive.read_open_memory(data)
            while control_entry = control_tar_gz.next_header do
              entry_name = control_entry.pathname
              if entry_name =~ /control$/
                @control_file_contents = control_tar_gz.read_data
              end
            end
          end

        end
      end
    end

    def parse_control_file
      @control_file_contents.scan(/^([\w-]+?): (.*?)\n(?! )/m).each do |entry|
        field, value = entry
        @fields[field] = value
      end
      @fields["installed_size"] = @fields["installed_size"].to_i * 1024 unless @fields["installed_size"].nil?
    end
  end

end

__END__
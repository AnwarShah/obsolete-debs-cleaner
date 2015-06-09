require 'libarchive_rs'
require 'debian'

module DebReaderSwig

  class Package
    include Comparable

    # Class for reading control or metainformation
    # of a single debian package file
    attr_reader :control_file_contents, :fields, :file_path

    def initialize(file_path)
      @file_path = file_path
      @fields = {}
      read_control_file @file_path
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

    # Implemeting method for comparing two package
    def <=>(otherObj)
      ver1 = self['Version']
      ver2 = otherObj['Version']

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

    # Overriding to_s for better view
    def to_s
      "#{self['Package']} #{self['Version']} #{self['Architecture']}"
    end

    private

    def read_control_file(filename)

      Archive.read_open_filename(filename) do |archive|
        while entry = archive.next_header
          path = entry.pathname.sub(/^\//, '')

          if path.include? 'control.tar.gz'
            control_tar_gz_data = archive.read_data
            control_gz_reader = Archive.read_open_memory(control_tar_gz_data)
            while control_entry = control_gz_reader.next_header
              if (control_entry.pathname).include? 'control'
                @control_file_contents = control_gz_reader.read_data
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
      unless @fields['installed_size'].nil?
        @fields['installed_size'] = @fields['installed_size'].to_i * 1024
      end
    end
  end

end

__END__
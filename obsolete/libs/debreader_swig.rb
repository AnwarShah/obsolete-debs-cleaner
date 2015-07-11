require_relative 'deb_helpers.rb'
require 'libarchive_rs'
require 'debian'

module DebReaderSwig

  class Package
    include DebHelpers
    include Comparable

    # Class for reading control or metainformation
    # of a single debian package file
    attr_reader :control_file_contents, :fields, :file_path, :file_size

    def initialize(file_path)
      @file_path = file_path
      @fields = {}
      read_control_file(@file_path)
      parse_control_file unless @control_file_contents.nil?
      @file_size = get_file_size
    end

    # method to get hash like entries
    def [](field)
      @fields.has_key?(field.to_s) ? @fields[field.to_s] : nil
    end

    # method to check validity of deb file
    def valid?
      @fields.size > 0
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

      compare_version(ver1, ver2)
    end

    # Overriding to_s for better view
    def to_s
      "#{self['Package']} #{self['Version']} #{self['Architecture']}"
    end

private

    def get_file_size
      File.size(@file_path)
    end

    def read_control_file(filename)
      begin
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
      rescue Archive::Error => msg
        puts "Error while processing deb file: #{filename} (#{msg})"
        return
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
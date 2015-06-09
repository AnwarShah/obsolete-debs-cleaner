
require 'debian/ar'
require 'debian/utils'

module DpkgDebReader

  class Package
    attr_reader :info

    def initialize(debfile)
      @fields = {}
      @info = ''

      ar = Debian::Ar.new(debfile)
      reader = lambda { |ctz|
        Debian::Utils::gunzip(ctz) { |ct|
          Debian::Utils::tar(ct, Debian::Utils::TAR_EXTRACT, '*/control') { |fp|
            @info = fp.readlines.join("")
            fp.close
          }
          ct.close
        }
      }
      ar.open('control.tar.gz', &reader)
      ar.open('control.tar.gz/', &reader) if @info.empty?
      ar.close
    end

    # method to get hash like entries
    def [](field)
      @fields.has_key?(field.to_s) ? @fields[field.to_s] : nil
    end

    private
    def parse_control_file
      @info.scan(/^([\w-]+?): (.*?)\n(?! )/m).each do |entry|
        field, value = entry
        @fields[] = value
      end
      unless @fields["installed_size"].nil?
        @fields["installed_size"] = @fields["installed_size"].to_i * 1024
      end
    end
  end

end
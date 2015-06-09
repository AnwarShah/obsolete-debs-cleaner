require 'benchmark'
require_relative 'dpkgdebReader'

module Tester

  def self.get_file_list(scan_path, exclude_dir)
    Dir.chdir scan_path
    @filenames = (Dir['**/*.deb']). # recursively get .deb filenames
    drop_while { |x| x.include?(exclude_dir+'/')} # discard files in exclude_dir
    @filenames
  end


  def self.read_package_info2

    @filenames.collect do |filename|
      path = File.realpath(filename)

      pkg = DpkgDebReader.load(path)
      pkg = parse_control_file(pkg)
      [ path, pkg['Package'], pkg['Version'],
        pkg['Architecture'] ]
    end
  end

  def self.parse_control_file(control_file_contents)
    fields = {}
    control_file_contents.scan(/^([\w-]+?): (.*?)\n(?! )/m).each do |entry|
      field, value = entry
      # fields[field.gsub("-", "_").downcase] = value
      fields[field] = value
    end
    # fields["installed_size"] = @fields["installed_size"].to_i * 1024 unless @fields["installed_size"].nil?
    fields
  end

end

path = '/linux/linux/repo/trusty/debs/L'
# path = 'testdata'

filenames = Tester.get_file_list path, 'to_delete'
Benchmark.measure  Tester.read_package_info2
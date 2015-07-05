require_relative 'deb_file'
require_relative 'package_debs'

class PkgInfoCollector

  def initialize(dir_to_scan, dirs_to_ignore=[])
    @scan_dir = dir_to_scan
    @ignore_dirs = format_dirname(dirs_to_ignore)

    collect_info
  end

  def collect_info
    @deb_files = get_deb_files(@scan_dir, @ignore_dirs)

    @deb_objects = []
    @deb_files.each do |deb|
      @deb_objects << DebFile.new(deb) # create object with info 
    end

    @collection = build_package_collection
  end

  ################# Interface methods ###########

  def show_all
    @collection.each do |name, debs|
      version_s = debs.size > 1 ? 'versions' : 'version'
      puts "#{name} has #{debs.size} #{version_s}"
      debs.show_all_versions
    end
  end

  def file_list
    @deb_files
  end

  def all_debs
    @deb_objects
  end

  def get_collection
    @collection
  end

  def to_s
    "Scan: #{@scan_dir}, Ignore: #{@ignore_dirs}"
  end

private ############ Private methods

  def build_package_collection
    package_info = {}

    @deb_objects.each do |deb|
      name = deb.package_name
      if package_info[name].nil? then
        package_info[name] = PackageDebs.new(name, deb)
      else
        package_info[name] << (deb)
      end
    end
    package_info
  end

  def get_deb_files(debs_dir, ignore_dirs)
    Dir.chdir debs_dir
    filenames = (Dir['**/*.deb'])# recursively get .deb filenames

    ignore_dirs.each do |dir|
      filenames.reject! { |x| x.include?(dir) } # discard files in ignore_dirs
    end
    filenames
  end

  def format_dirname(dirs)
    dirs.collect {|dir| dir + '/' }
  end

end

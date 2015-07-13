require 'ruby-progressbar'

require_relative 'deb_file'
require_relative 'package_debs'

class PkgInfoCollector

  def initialize(dir_to_scan, dirs_to_ignore=[])
    @scan_dir = dir_to_scan
    @ignore_dirs = format_dirname(dirs_to_ignore)

    collect_info
  end

  def collect_info
    @progress_bar = ProgressBar.create( :format => 'Getting deb file list: %B',
                                        :starting_at => 20,
                                        :total => nil,
                                        :unknown_progress_animation_steps => ['.'])
    @progress_bar.increment
    @deb_files = get_deb_files(@scan_dir, @ignore_dirs)
    puts 'Extracting info from deb files ... '
    @progress_bar = ProgressBar.create( :format => "%a %e %P% Scanned: %c deb files from %C",
                                        :total => @deb_files.length )
    @deb_objects = []
    @deb_files.each do |deb|
      @deb_objects << DebFile.new(deb) # create object with info
      @progress_bar.increment
    end

    @collection = build_package_collection #hash
    @size_info = calculate_size_info(@collection)
  end

  ################# Interface methods ###########

  def show_all
    @collection.each do |name, debs|
      version_s = debs.total_debs > 1 ? 'versions' : 'version'
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

  def get_size_info
    @size_info
  end

  def get_collection_with_multiples
    @collection.select { |pkg, val| val.length > 1 }
  end

  def to_s
    "Scan: #{@scan_dir}, Ignore: #{@ignore_dirs}"
  end

private ############ Private methods #################

  def build_package_collection
    package_info = {}

    @deb_objects.each do |deb|
      name = deb.package_name
      next if name.nil? # handle invalid deb with nil name
      if package_info[name].nil? then
        package_info[name] = PackageDebs.new(name, deb)
      else
        package_info[name] << (deb)
      end
    end
    package_info
  end

  def calculate_size_info(collections)
    sizes = {}
    collections.each do |pkg, pkg_debs|
      sizes[pkg] = pkg_debs.get_max_deb_size
    end
    sizes
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

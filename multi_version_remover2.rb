require_relative 'libs/deb_files_scanner'

class UserChoice

  attr_reader :selections

  def initialize(selection_str, options)
    @selection_s = selection_str
    @valid_options = options
    @options_count = @valid_options.length
    @selections = []  # user selected options
    @valid = false    # a flag for validity status

    parse_selections
  end

  def valid?
    check_selection_validity
    @valid
  end

  def set_new_selection(selection_s)
    @selection_s = selection_s
    # trigger parse selection
    parse_selections
  end

  private
  def parse_selections
    # selection string can contain only digits seperated by any non-digits
    @selections = @selection_s.chomp.split(/\D+/).keep_if { |v| v.length > 0 }
    @selections = @selections.map { |e| e.to_i }
  end

  def check_selection_validity
    # Remove same selection multiple times
    @selections.uniq!

    # check invalid range
    @selections.each  do |x|
      #if any value is out of range
      unless @valid_options.include?(x)
        @valid = false
        return
      end
    end

    # if passed all filter
    @valid = true
  end
end

###############################################################################
class DebPkgInfo
  include Comparable
  include DebHelpers

  attr_reader :version, :arch, :path

  def initialize(version, arch, path)
    @version = version
    @arch  = arch
    @path =  path
  end

  def <=>(obj)
    ver1 = @version
    ver2 = obj.version

    compare_version(ver1, ver2)
  end

  def to_s
    "Ver: #{@version}, Arc: #{@arch}, Path: #{@path}"
  end
end
################################################################################

class MultiVersionRemover
  attr_reader :scan_dir, :excluded_dir, :debs_info, :pkgs_info

  def initialize(scan_dir = '', exclude_folder = '')
    @excluded_dir = exclude_folder if not exclude_folder.empty?
    @scan_dir = '.' if scan_dir.empty?

    @debs_info = get_debs_info(@scan_dir, @excluded_dir)
    @pkgs_info = get_pkgs_info(@debs_info)
    drop_singles!(@pkgs_info) # drop packages with only 1 version
    multiversions_count = @pkgs_info.length

    # user_options = extract_user_options
    if multiversions_count > 0 # at least 1 package exisits with multi-version
      puts "#{multiversions_count} packages found with multiple versions"
      process_multidebs
    else
      puts 'No package found with multiple versions'
    end
  end

  def process_multidebs
    selections = get_user_deletion_list(@pkgs_info)
    delete_selected_versions(@pkgs_info, selections)
  end


private

  def get_debs_info(scan_dir, exclude_dir)
    DebFilesScanner.new(scan_dir, exclude_dir)
  end
  
  def get_pkgs_info(debs_info)
    pkgs_info = Hash.new  { |h, key| h[key] = [] }

    debs_info.each do |pkg|
      name = pkg['Package']
      pkgs_info[name].push(
          [ DebPkgInfo.new(pkg['Version'], pkg['Architecture'], pkg.file_path) ]  )
    end
    pkgs_info
  end

  def extract_user_options

  end

  def drop_singles!(pkgs_info)
    # Only keep packages with multiple versions
    pkgs_info.delete_if { |pkg, val|
      val.length <= 1
    }
  end

  def get_selection_from_user(valid_opt_arr)
    # Get selection for deletion for a single package
    prompt = "\nType the index to select versions to remove (Enter to skip)" +
     "\nUse any symobls to seperate multiple index" +
     "\nExample: 2, 3 or 2 3"

    puts prompt
    selection_str = gets.chomp
    user_sels = UserChoice.new(selection_str, valid_opt_arr)
    until user_sels.valid?
      puts 'Invalid selection. Please try again'
      selection_str = gets.chomp
      user_sels.set_new_selection(selection_str)
    end
    user_sels.selections  #return the selection array
  end

  def get_user_deletion_list(pkgs_info)
    # Get use selections for every packages
    all_selections = []
    pkgs_info.each { |pkg, val |
      options_arr = (1..val.length).to_a
      no_of_vers = options_arr.length
      prompt_msg_select(pkg, no_of_vers)

      val.each_index do |i|
        print "#{i+1}: "
        val[i].each { |pkg|
          puts "#{pkg.version} #{pkg.arch}"
        }
      end
      all_selections.push get_selection_from_user(options_arr)
    }
    all_selections # Return the selections for all package
  end


  def delete_selected_versions(info_hash, selections_arr)
    delete_list = []

    zip_arr = info_hash.zip(selections_arr)
    zip_arr.each do |pkg_arr, sel_arr|
        sel_arr.each_index { |idx|
          delete_list.push pkg_arr[1][idx]
        }
    end
    files_to_delete = get_delete_files_list(delete_list)
    delete_files(files_to_delete)
  end

  def delete_files(files_to_delete)
    no_of_files_to_delete = files_to_delete.size
    file_or_files = no_of_files_to_delete > 1 ? 'files' : 'file'

    puts "You have selected #{no_of_files_to_delete} #{file_or_files} to delete: "
    show_filelist(files_to_delete)

    if has_consent?
      puts "Files are deleted"
    else
      puts "Man! have some courage!"
    end

  end

  def has_consent?
    puts "Do you really want to delete these files? (Y/N)"
    response = gets.chomp.downcase
    until response == 'y' or response == 'n'
      puts 'Please type Y to agree or N to disagree'
      response = gets.chomp.downcase
    end
    response == 'y' ? true : false
  end

  def show_filelist(filelist)
    filelist.each do |file|
      puts file
    end
  end

  def get_delete_files_list(delete_list)
    # delete list is an array of class DebPkgInfo
    files_to_delete = []

    delete_list.each do |pkg|
      files_to_delete.push(
          File.realpath (pkg[0].path) )
    end
    files_to_delete
  end

  def prompt_msg_select(pkg_name, vers_count)
    puts "#{vers_count} versions found for package \"#{pkg_name}\": "
  end
end

################ TEST TEST TEST TEST ##############
ab = MultiVersionRemover.new('', 'to_delete')

pkgs_info = ab.pkgs_info

# pkgs_info.each do |pkg, info_arr|
#   print "Package: #{pkg}: "
#   puts
#   info_arr.each_with_index  do |inf, index|
#     puts "#{index}: #{inf}"
#
#   end
# end


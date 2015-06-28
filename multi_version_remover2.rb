#!/usr/bin/env ruby

require 'fileutils'
require_relative 'libs/deb_files_scanner'
require_relative 'libs/apt_version'
require_relative 'libs/deb_helpers'

class UserChoice

  attr_reader :selections

  def initialize(selection_str, options)
    @selection_s = selection_str
    @valid_options = options
    @options_count = @valid_options.length
    @selections = []  # user selected options

    parse_selections
  end

  def valid?
    @selections.uniq! # remove duplicates
    # check invalid range
    @selections.each  do |x|
      return false unless @valid_options.include?(x)
    end
    true # otherwise
  end # method valid?

  def set_new_selection(selection_s)
    @selection_s = selection_s
    parse_selections # parse new selection
  end

  private
  def parse_selections
    # selection string can contain only digits seperated by any non-digits
    @selections = @selection_s.chomp.split(/\D+/).keep_if { |v| v.length > 0 }
    @selections = @selections.map { |e| e.to_i }
  end

end

###############################################################################
class DebPkgInfo
  include Comparable
  include DebHelpers

  attr_reader :version, :arch, :path, :size

  def initialize(version, arch, path, size)
    @version = version
    @arch  = arch
    @path =  path
    @size = size
  end

  def <=>(obj)
    compare_version(@version, obj.version)
  end

  def to_s
    "Ver: #{@version}, Arc: #{@arch}, Path: #{@path}, Size: #{@size}"
  end
end
################################################################################

class MultiVersionRemover
  include DebHelpers

  attr_reader :scan_dir, :to_delete_dir, :debs_info, :pkgs_info

  def initialize(scan_dir = '.', exclude_folder = 'to_delete')
    @to_delete_dir = exclude_folder
    @scan_dir = scan_dir

    @debs_info = DebFilesScanner.new(@scan_dir, @to_delete_dir)
    @pkgs_info = extract_pkg_info(@debs_info)
    drop_singles!(@pkgs_info) # drop packages with only 1 version
    sort(@pkgs_info) # sort by package version

    multiversions_count = @pkgs_info.length
    # user_options = extract_user_options
    if multiversions_count > 0 # at least 1 package exisits with multi-version
      puts "#{multiversions_count} packages found with multiple versions"
      puts ''
      process_multidebs
    else
      puts 'No package found with multiple versions'
    end
  end

private

  def sort(pkg_info)
    pkg_info.collect do |mult|
      # mult[0] is package name, mult[1] is array of versions
      mult[1].sort!
    end
    pkg_info
  end

  def process_multidebs
    selections = get_user_deletion_list(@pkgs_info)
    delete_selected_versions(@pkgs_info, selections)
  end

  def extract_pkg_info(debs_info)
    pkgs_info = Hash.new  { |h, key| h[key] = [] }

    debs_info.each do |pkg|
      name = pkg['Package']
      size = pkg.file_size
      pkgs_info[name].push(
          [ DebPkgInfo.new(pkg['Version'], pkg['Architecture'],
                           pkg.file_path, size ) ]  )
    end
    pkgs_info
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

      present_version_info(val)
      all_selections.push get_selection_from_user(options_arr)
    }
    all_selections
  end


  def present_version_info(val)
    val.each_index do |i|
      print "#{i+1}: "
      val[i].each { |it|
        ver = AptPkg_Version.new(it.version)
        size = pretty_file_size it.size
        puts "E: %-3s V: %-10s R: %-10s Size: #{size}" %
                 [ ver.epoch, ver.upstream, ver.revision ]
      }
    end
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
    delete_files(files_to_delete) if files_to_delete.length > 0
  end

  def delete_files(files_to_delete)
    no_of_files_to_delete = files_to_delete.size
    file_or_files = no_of_files_to_delete > 1 ? 'files' : 'file'

    puts "You have selected #{no_of_files_to_delete} #{file_or_files} to delete: "
    show_filelist(files_to_delete)

    if has_consent?
      delete_count = 0
      check_dest_dir
      files_to_delete.each do |file|
        FileUtils.mv(file, @to_delete_dir)
        puts "#{file} -> #{@to_delete_dir}"
        delete_count += 1
      end
      puts "#{delete_count} Files are deleted"
    else
      puts "Man! have some courage!"
    end

  end

  def check_dest_dir
    Dir.mkdir(@to_delete_dir) unless File.exists?(@to_delete_dir)
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

if $0 == __FILE__
  MultiVersionRemover.new()
end

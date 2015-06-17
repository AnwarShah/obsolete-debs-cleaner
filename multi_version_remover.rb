#!/usr/bin/ruby 

# This program attempts to remove old, obsolete versions for local debian 
# packages by prompting user for the deletion list. Another variation 
# which automatically delete older versioned files is in the plan list
# @copyright Mohammad Anwar Shah
# version: 0.9.1

require 'fileutils'
require 'find'
require 'debian'

require_relative 'libs/debreader_swig'


TO_FOLDER = 'to_delete'

# Class for App-version sort routine
class AptVersSorter
  def initialize(info)
    @info = info
    @ver_arr = info[:versions]
    @size_arr = info[:sizes]
    @path_arr = info[:paths]
  end

  def sort_by_versions
    quick_sort(0, @ver_arr.length-1 )
  end

  def quick_sort(p, r)
    if p < r
      q = partition(p, r)
      quick_sort(p, q-1)
      quick_sort(q+1, r)
    end
  end

  def exchange(x, y )
    # Exchange versions
    temp_ver = @ver_arr[x]
    @ver_arr[x] = @ver_arr[y]
    @ver_arr[y] = temp_ver

    # exchange paths
    temp_path = @path_arr[x]
    @path_arr[x] = @path_arr[y]
    @path_arr[y] = temp_path

    # exchange sizes
    temp_path = @size_arr[x]
    @size_arr[x] = @size_arr[y]
    @size_arr[y] = temp_path

  end

  def partition(p, r )
    x = @ver_arr[r]
    i = p - 1

    p.upto(r-1) do |j|
      if version_cmp(@ver_arr[j], x) == -1 || version_cmp(@ver_arr[j], x ) == 0
        i = i + 1
        exchange( i , j )
      end
    end

    exchange(i+1,r )
    i + 1
  end

  # version comparison method
  def version_cmp(ver1, ver2)
    # Compares two versions ver1 and ver2
    # if ver1 is greater than ver2, return 1
    # if less, return -1
    # if equal , return 0
    # else return nil

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

def get_deb_files_name
  filenames = []

  filenames = (Dir['**/*.deb']). # recursively get .deb filenames
      drop_while { |x| x.include?(TO_FOLDER+'/')} # discard files in TO_FOLDER folder
  filenames
end

# Get the information from package files
def read_package_info(filenames)
  filenames.collect do |filename|
    path = File.realpath(filename)

    pkg = DebReaderSwig::Package.new(path)

    # return a 4 element array by extracting info from temp hash
    [ path, pkg['Package'], pkg['Version'], pkg['Architecture'] ]
  end
end

def read_deb_files

  filenames = get_deb_files_name

  # get deb file info into array of array
  files_info = read_package_info(filenames)

  # create a hash with a defined default structure
  info_hash = Hash.new { |hash, key| hash[key] = {} }

  files_info.collect do |path, name, ver, arch|

    pretty_size = pretty_file_size File.size(path)
    info_hash[name][:arch] = arch
    unless info_hash[name][:versions]
      info_hash[name][:versions] = [ver]
      info_hash[name][:paths] = [path]
      info_hash[name][:sizes] = [pretty_size]
    else
      info_hash[name][:versions] += [ver]
      info_hash[name][:paths] += [path]
      info_hash[name][:sizes] += [pretty_size]
    end

  end

  info_hash

end

def valid_selection?(selection_arr, vers_count)

  # Remove same selection multiple times
  selection_arr.uniq!
  # if more than available versions are selected
  if selection_arr.length > vers_count 
    return false
  end

  # check invalid range
  selection_arr.select do |x| 
    return false if x > vers_count - 1 or x < 0
  end

end

def print_info(info_hash)

  info_hash.each do |package, info|
    version_count = info[:versions].length
    version_s = version_count > 1 ? 'versions' : 'version'
    head = "#{package} {#{info[:arch]}} has #{version_count} #{version_s}"
    versions = ''
    info[:versions].each_with_index do |ver_no, index|
      versions += ' ' * 8 + "#{index+1} - " + ver_no + "\n"
    end
    puts head
    puts versions

  end

end

def display_delete_list(file_list)

  if file_list.length > 0 # file list is not empty
    puts "\nYou selected these files to delete: "
    file_list.each { |file| puts file }
  end

end

def get_user_selection
  selected = gets.chomp.split(/ |\,/).keep_if { |v| v.length > 0 }
  selected.map! { |e| e.to_i }
  selected
end

def mark_for_deletion(info_hash, sorted = false )

  marked_files = []
  instruction =  <<END
Select version(s) to remove from a given package.
Type the version index to select.
Use comma or space to separate multiple index.
Press ENTER to skip or keep all versions.
END

  not_sorted_msg = 'The packages ARE NOT in sorted order.'
  sorted_msg = 'The packages are presented in SORTED order.'

  puts instruction
  if sorted
    puts sorted_msg
  else
    puts not_sorted_msg
  end
  puts # empty line

  hint = 'ENTER to skip or Type index (separate with comma or space) to remove'
  info_hash.each do |package, info|
    versions_count = info[:versions].length

    if versions_count > 1 # if more than one version exists
      puts "#{package} {#{info[:arch]}}"

      info[:versions].each_index do |index|
        puts "[#{index}]: #{info[:versions][index]} size: #{info[:sizes][index]}"
      end
      puts  "\n#{hint}"

      # get input, split with comma and space and store individual. value
      selected = get_user_selection

      unless valid_selection?(selected, versions_count)
        puts 'INVALID selection! Retry'
        redo # again prompt
      else
        # include all filenames selected for deletion
        selected.each do |idx|
          filename = info[:paths][idx]
          marked_files.push(filename)
        end
      end
    end

  end # end of outer info_hash outer loop
  marked_files # return selected list

end

def move_for_delete_files(file_list, options = {})
  
  if options[:folder_name].nil? # if no delete folder name is provided
    to_del_dir = File.join(Dir.pwd, TO_FOLDER) # use 'to_delete'
  else
    to_del_dir = options[:folder_name]
  end

  Dir.mkdir(to_del_dir) if !Dir.exist?(to_del_dir)
  
  if file_list.empty? 
    puts 'No files selected for removal'
  else
    move_count = 0 # counter
    file_list.each { |file|
      FileUtils.mv(file, to_del_dir)
      puts "#{File.basename(file)} moved to \'#{File.realpath(to_del_dir)}\'"
      move_count += 1
    }
    files_word = move_count > 1 ? 'Files' : 'File'
    puts # line break
    puts "#{move_count} #{files_word} moved successfully into the folder named \'#{to_del_dir}\'"
  end

end

def multi_versions_exists?(files_info)

  files_info.each do |package, info|
    return true if info[:versions].length > 1
  end

  false # no multiple versions found
end


def main( options = {sort: false } )

  # display a welcome message
  puts '=' * 40

  welcome_msg = <<END
Welcome to .deb file cleaner program
This program will scan recursively the current directory for .deb files and
check for multiple versions of a package.
If found, user will be prompted to select some or all of the versions to delete.
The user selected files will NOT be deleted immediately.
Instead those files will be be moved into a folder.
Default name of destination folder is `to_delete` in current directory
END

  puts welcome_msg
  puts '=' * 40
  puts #empty line

  deb_file_info = {}

  # read deb files from directory
  t1 = Thread.new {
    deb_file_info = read_deb_files
  }

  print 'Scanning directory (Please wait) ' if t1.status
  while t1.status
    print '.'
    $stdout.flush
    sleep 0.2
  end

  t1.join
  # Add two line
  puts "\n\n"

  # if sorted option specified, sort
  if options[:sort]

    deb_file_info.collect do | pack, info |
      if info[:versions].length > 1
        AptVersSorter.new(info).sort_by_versions
      end
    end

  end

  # Print info about packages
  # print_info deb_file_info

  # Check whether multiple versions exists
  if !multi_versions_exists?(deb_file_info)
    puts 'No packages found with multiple versions'
    exit(0)
  end


  # get delete list from user
  for_delete_list = mark_for_deletion(deb_file_info, options[:sort] )

  # display the list to the user
  # display_delete_list(for_delete_list) if for_delete_list.length > 0

  puts # draw a line
  move_for_delete_files(for_delete_list, { folder_name: TO_FOLDER } )

end

help_msg = <<END
Usage: multi_version_remover.rb [Options]...[FOLDER]
Scan for .deb files recursively from current directory and
prompt user to remove multiple versions

All options are optional.
If not specified, it will run with -s and `to_folder` folder name

Options:
  -h    This help text
  -s    Present multiple versions in sorted order
  -S    Do not present in sorted order

FOLDER is the user specified folder name. Default name is `to_delete`
END


if $0 == __FILE__


    until ARGV.empty?
      option = ARGV.shift
      case option
        when '-h'
          help_flag = true
        when '-s'
          sort_flag = true
        when '-S'
          sort_flag = false
        else
          custom_folder = option
      end
    end


    if help_flag
      puts help_msg
      exit(0)
    end

    if custom_folder
      TO_FOLDER = custom_folder
    end

    if sort_flag.nil?
      main( { sort: true } ) # default is sort: true
    else
      main( { sort: sort_flag } ) # otherwise user specified
    end
end

__END__

# Todo:1) Add support for presenting package list with -
#         1) most versions
#         2) greatest size
#     2) Add support for deleting permanently or temporarily
#         1) with gvfs-trash
#     3) Presenting list with seperate epoch and version
#     4) Ability to reselect an skipped package
#     5) Skip remaining packages
#     6) Search for a string in versions
#     7) Search for a package

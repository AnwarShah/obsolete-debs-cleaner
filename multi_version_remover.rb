#!/usr/bin/ruby 

# This program attempts to remove old, obsolete versions for local debian 
# packages by prompting user for the deletion list. Another variation 
# which automatically delete older versioned files is in the plan list
# @copyright Mohammad Anwar Shah
# version: 0.9.1

require 'fileutils'
require 'find'

TO_FOLDER = "to_delete"

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

def read_deb_files

  ignores = ['to_delete']
  filenames = []

  Find.find('.') do |path|
    name = File.basename(path)
    if FileTest.directory?(path)
      if ignores.include?(name)
        Find.prune
      else
        next
      end
    else
      filenames << path if name =~ /.deb$/
    end
  end

  # get deb file info into array of array
  files_info = filenames.collect do |filename|
    Array(File.realpath(filename)) + File.basename(filename, '.deb').split('_')
  end

  # create a hash with a defined default structure
  info_hash = Hash.new { |hash, key| hash[key] = {} }

  files_info.collect do |path, name, ver, arch|

    pretty_size = pretty_file_size File.size(path)
    info_hash[name][:arch] = arch
    if !info_hash[name][:versions]
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

def mark_for_deletion(info_hash)

  marked_files = []

  instruction =
      "Use comma or space to separate the versions. Example: 2, 3 or 2 3" +
      "\nPress ENTER to skip or keep all versions" + 
      "\nThe packages ARE NOT presented in sorted order."

  puts instruction
  puts # empty line

  info_hash.each do |package, info|
    versions_count = info[:versions].length

    if versions_count > 1 # if more than one version exists
      puts "Select version(s) to delete for #{package} {#{info[:arch]}} package"
      
      info[:versions].each_index do |index|
        puts "[#{index}]: #{info[:versions][index]} size: #{info[:sizes][index]}"
      end
      
      # get input, split with comma and space and store individual. value
      selected = gets.chomp.split(/ |\,/).keep_if { |v| v.length > 0 } 
      selected.map! { |e| e.to_i }

      if !valid_selection?(selected, versions_count)
        puts "INVALID selection! Retry"
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
    puts "No files selected for removal"
  else
    file_list.each { |file| FileUtils.mv(file, to_del_dir) }
    puts "Files moved successfully into the #{to_del_dir} folder"
  end

end

def multi_versions_exists?(files_info)

  files_info.each do |package, info|
    return true if info[:versions].length > 1
  end

  false # no multiple versions found
end


def main

  # display a welcome message
  puts '=' * 40

  welcome_msg = "Welcome to .deb file cleaner program\n" +
    "\nThis program will scan recursively from current directory for " +
          ".deb (debian archive) files " +
    "\nand check whether multiple versions of a package exist. " +
    "\nIf multiple versions are found, will prompt user to select some or all of the versions to delete" +
    "\nThe user selected files will not be deleted immediately." +
    "\nInstead those files will be be moved into a folder named `to_delete`"

  puts welcome_msg
  puts '=' * 40
  puts #empty line

  # read deb files from directory
  deb_file_info = read_deb_files

  # Print info about packages
  # print_info deb_file_info

  # Check whether multiple versions exists
  if !multi_versions_exists?(deb_file_info)
    puts "No packages found with multiple versions"
    exit(0)
  end

  # get delete list from user
  for_delete_list = mark_for_deletion(deb_file_info)

  # display the list to the user
  display_delete_list(for_delete_list) if for_delete_list.length > 0
  puts # draw a line
  move_for_delete_files(for_delete_list, { folder_name: TO_FOLDER } )

end


main #call main method
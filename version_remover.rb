#!/usr/bin/ruby 

# This program attempts to remove old, obsolete versions for local debian 
# packages by prompting user for the deletion list. Another variation 
# which automatically delete older versioned files is in the plan list
# @copyright Mohammad Anwar Shah 

def read_deb_files

  # get filenames without extensions
  filenames = Dir.glob('*.deb').collect { |filename| filename.sub(/.deb$/, '')}
  # get deb file info into array of array
  files_info = filenames.collect { |filename| filename.split('_')}

  # create a hash with a defined default structure
  info_hash = Hash.new { |hash, key| hash[key] = {} }

  files_info.collect do |name, ver, arch|
    # if already a version exists, append the version to it
    if !info_hash[name][:version].nil? 
      info_hash[name][:version] << ver
    else
      info_hash[name] = { version: [ver], arch: arch}
    end
  end
  info_hash
end

def valid_selection?(selection_arr, vers_count)
  # if more than available versions are selected
  if selection_arr.length > vers_count 
    return false
  end
  # selected selection
  selection_arr.select { |x| return false if x > vers_count - 1 }      
end

def print_info(info_hash)
  info_hash.each do |key, value|
    version_s = value[:version].length > 1 ? 'versions' : 'version'
    head = "Package #{key} {#{value[:arch]}} has #{value[:version].length} #{version_s}"
    versions = ''
    value[:version].each do |ver_no| 
      versions += ' ' * 8 + 'version: ' + ver_no + "\n"
    end
    puts head
    puts versions
  end
end

def display_delete_list(file_list)
  puts "\nYou selected these files for deletion."
  file_list.each { |file| puts file }
end

def mark_for_deletion(info_hash)
  marked_files = []

  instruction = "Select the versions you want to REMOVE from the list. " + 
      "\nUse comma or space to separate the versions. Example: 2, 3 or 2 3"
  puts instruction
  puts # empty line

  info_hash.each do |package, info|
    versions_count = info[:version].length
    if versions_count > 1 # if more than one version exists
      puts "Select one(s) for Package #{package} {#{info[:arch]}} "
      
      info[:version].each_with_index do |version, index|
        list = "#{index}: #{version}"
        puts list
      end
      
      # get input, split with comma and space and store indv. value
      selected = gets.chomp.split(/ |\,/).keep_if { |v| v.length > 0 } 
      selected.map! { |e| e.to_i }
      if !valid_selection?(selected, versions_count)
        puts "Invalid selection"
      else
        # include all filenames selected for deletion
        selected.each do |idx|
          filename = package + '_' + info[:version][idx] +'_'+ 
                      info[:arch] + '.deb'
          marked_files.push(filename)
        end
      end
    end
  end # end of outer info_hash outer loop

  marked_files # return selected list
end


def main
  # read deb files from directory  
  deb_file_info = read_deb_files
  
  # print_info(deb_file_info)
  # get delete list from user
  for_delete_list = mark_for_deletion(deb_file_info)
  # display the list to the user
  display_delete_list(for_delete_list) if for_delete_list.length > 0
end


main #call main method
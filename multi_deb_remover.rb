require 'fileutils'

require_relative 'pkg_info_collector'
require_relative 'user_response_parser'
require_relative 'user_responses'

def get_selections(collection)

  collection_arr = collection.to_a # convert to arry for easy iteration

  res_processor = UserResponses.new()
  index = 0
  while index < collection_arr.length
    pkg = collection_arr[index][0]
    debs = collection_arr[index][1]

    puts "#{debs.length} version(s) found for #{pkg} #{debs.architecture}:"
    debs.sort.each_with_index do |deb, index|
      puts "#{index}: #{deb.version} #{deb.file_size}"
    end

    puts 'Select index to remove, P(Previous), S(Stop), F(Finish)'
    res = UserResponseParser.new(gets.chomp)
    res_processor.add_response(res)

    if res_processor.get_status == :invalid
      puts 'Invalid selection. Try again'
      redo
    elsif res_processor.get_status == :previous
      index = (index-1) < 0 ? 0 : index-1
      next
    elsif res_processor.get_status == :stop
      exit # stopping here.
    elsif res_processor.get_status == :finish
      break # to get selections
    else
      index = index + 1
    end # if else

  end # while

  res_processor.selections

end

def get_selected_files(collection, selections)
  collection_arr = collection.to_a # convert to arry for easy iteration

  files = []

  index = 0
  while index < selections.length
    debs = collection_arr[index][1]
    selection = selections[index]

    selection.each do |i|
      files << debs[i].path
    end
    index += 1
  end

  files
end

def remove_files(files)
  puts 'These files are selected for removal. Are you sure? (Y/N)'
  files.each { |f| puts f }
  answer = gets.chomp.downcase
  if answer == 'y'
    dest_dir = 'to_delete'
    FileUtils.mkdir(dest_dir) unless Dir.exist?(dest_dir)
    files.each { |file|
      FileUtils.move(file, dest_dir)
      puts "#{File.basename file} -> #{File.realpath dest_dir}"
    }
  end
end

if $0 == __FILE__
  exclude_dirs = ['to_delete']
  collector = PkgInfoCollector.new('debs', exclude_dirs)
  collection = collector.get_collection_with_multiples


  selections = get_selections(collection) # while
  files = get_selected_files(collection, selections)

  remove_files(files) if files.length > 0
end
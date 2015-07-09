#!/usr/bin/env ruby

require 'fileutils'

require_relative 'pkg_info_collector'
require_relative 'user_response_parser'


def get_selections(collection)

  collection_arr = collection.to_a # convert to arry for easy iteration
  selections = [] # array to save selections

  index = 0
  while index < collection_arr.length
    pkg = collection_arr[index][0]
    debs = collection_arr[index][1]

    puts "#{debs.length} version(s) found for #{pkg} #{debs.architecture}:"
    debs.sort.each_with_index do |deb, index|
      puts "#{index}: %-30s %10s" % [deb.version, deb.file_size]
    end

    puts 'Select index to remove, P(Previous), S(Stop), F(Finish)'
    res = UserResponseParser.new(gets.chomp)

    if res.response_type == :invalid
      puts 'Invalid selection. Try again'
      redo
    elsif res.response_type == :command
      case res.get_command
        when :previous
          index = (index-1) < 0 ? 0 : index-1
          next
        when :finish
          break
        when :stop
          exit
        else
          index += 1
      end
    elsif res.response_type == :selection
      selections[index] = res.get_response
      index += 1
    end # end
  end # while

  selections

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
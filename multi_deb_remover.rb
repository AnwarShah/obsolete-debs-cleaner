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
  files.each { |f| puts f }
  puts 'These files are selected for removal. Are you sure? (Y/N)'
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

def sorted_by_size(collection, sizes)
  # this method sorts the collection by using another
  # size hash as guide
  new_collection = { }
  sizes_arr = sizes.to_a
  sizes_arr.sort_by! { |pkg, max_deb_size| max_deb_size }
  sizes_arr.reverse! # get reverse sort

  sizes_arr.each do |pkg, max_size|
    new_collection[pkg] = collection[pkg] unless collection[pkg].nil?
  end

  new_collection
end

if $0 == __FILE__
  exclude_dirs = ['to_delete']
  collector = PkgInfoCollector.new('.', exclude_dirs)
  collection = collector.get_collection_with_multiples
  sizes = collector.get_size_info
  sorted_collection = sorted_by_size(collection, sizes)

  selections = get_selections(sorted_collection) # while
  files = get_selected_files(sorted_collection, selections)

  remove_files(files) if files.length > 0
end
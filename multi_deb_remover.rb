require_relative 'pkg_info_collector'
require_relative 'user_response_parser'

  if $0 == __FILE__
  exclude_dirs = ['to_delete']
  collector = PkgInfoCollector.new('debs', exclude_dirs)
  collection = collector.get_collection_with_multiples

  collection.each do |pkg, debs|
    puts "#{debs.length} version(s) found for #{pkg}:"
    debs.each_with_index do |deb, index|
      puts "#{index}: #{deb}"
    end
    puts 'Select index to remove'
    res = UserResponseParser.new(gets.chomp)
    if res.response_type == :command
      #Process command
      puts "Process command #{res.get_response}"
    else
      #Save selection
      puts 'Save selection'
    end
  end
end
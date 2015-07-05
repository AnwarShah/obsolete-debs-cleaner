require_relative 'pkg_info_collector'

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
    gets.chomp 
  end
end
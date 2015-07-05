require_relative 'pkg_info_collector'

if $0 == __FILE__
  exclude_dirs = ['to_delete']
  collector = PkgInfoCollector.new('debs', exclude_dirs)
  collection = collector.get_collection

  collection.each do |pkg, debs|
    p pkg
    puts debs[0]
  end
end
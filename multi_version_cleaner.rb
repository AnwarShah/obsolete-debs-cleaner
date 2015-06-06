class MultiVersionCleaner

  # path is the path of the folder containing
  # .deb files

  def initialize(debs_dir, dest_folder='.')
    @debs_dir = debs_dir
    @dest_dir = dest_folder # the folder where .debs will be moved
    get_file_list
    extract_pkg_info
  end

private
  # Get the list of the deb files
  # recursively from $debs_dir into an array

  def get_file_list
    Dir.chdir @debs_dir
    @filenames = (Dir['**/*.deb']). # recursively get .deb filenames
    drop_while { |x| x.include?(@dest_dir+'/')} # discard files in @dest_dir
  end

  def extract_pkg_info

  end
end
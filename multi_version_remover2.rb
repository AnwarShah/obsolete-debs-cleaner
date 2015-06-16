require_relative 'deb_files_scanner'

class UserChoice

  attr_reader :selections

  def initialize(selection_str, options)
    @selection_s = selection_str
    @valid_options = options
    @options_count = @valid_options.length
    @selections = []  # user selected options
    @valid = false    # a flag for validity status

    parse_selections
    check_selection_validity
  end

  def valid?
    @valid
  end

  private
  def parse_selections
    # selection string can contain only digits seperated by any non-digits
    @selections = @selection_s.chomp.split(/\D+/).keep_if { |v| v.length > 0 }
    @selections = @selections.map { |e| e.to_i }
  end

  def check_selection_validity
    # Remove same selection multiple times
    @selections.uniq!

    # check invalid range
    @selections.each  do |x|
      #if any value is out of range
      unless x >= 0 && x < @valid_options.length && @valid_options.include?(x)
        @valid = false
        return
      end
    end

    # if passed all filter
    @valid = true
  end
end

###############################################################################

class MultiVersionRemover

  def initialize(scan_dir = '', exclude_folder = '')
    $excluded_dir = exclude_folder if not exclude_folder.empty?
    $scan_dir = scan_dir if not scan_dir.empty?

    @debs_info = get_debs_info($scan_dir, $excluded_dir)
    user_options = extract_user_options
    if has_multiples?
      get_user_deletion_list
    end
    delete_files
  end

private # private utility methods
  def get_debs_info(scan_dir, exclude_dir)
    DebFilesScanner.new(scan_dir, exclude_dir).read_debs
  end

  def extract_user_options

  end

  def has_multiples?

  end

  def get_user_deletion_list
  end

  def delete_files

  end
end

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
    check_validity
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

  def check_validity
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

class MultiVersionRemover
  DEST_DIR = 'to_delete'

  def initialize
    get_user_choice
  end

end

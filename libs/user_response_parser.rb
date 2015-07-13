class UserResponseParser

  NEXT = 'n'
  PREVIOUS = 'p'
  STOP = 's'
  FINISH = 'f'

  def initialize(response_str, valid_selections_arr)
    @response_str = response_str
    @valid_selections = valid_selections_arr

    @commands = [NEXT, PREVIOUS, STOP, FINISH]
  end

  def response_type
    return :command if is_command?
    return :selection if is_selection?
    :invalid #otherwise invalid response
  end

  def get_command
    user_response = @response_str

    return :next if user_response.index NEXT
    return :previous  if user_response.index PREVIOUS
    return :stop if  user_response.index STOP
    return :finish if  user_response.index FINISH
  end

  def get_selection
    return nil if response_type == :command

    sels = @response_str

    sels = sels.chomp.split(/\D+/).keep_if { |v| v.length > 0 }

    sels.map! { |e| e.to_i }

    return :invalid unless valid_selections?(sels)
    sels
  end

  def valid_selections?(user_selections)
    user_selections.uniq! # remove duplicates
    # check invalid range
    user_selections.each  do |x|
      return false unless @valid_selections.include?(x)
    end
    true # otherwise
  end

  def is_command?
    # if response is of length one and only contain command char
    char = @response_str.strip
    if char.length == 1 &&
        @commands.any? { |x| char == x }
      return true
    end
    false
  end

  def is_selection?
    return false if is_command?
    chars = @response_str.split(/\W+/)
    begin
      chars.each do |x|
        Integer(x) # try to convert to int
      end
    rescue ArgumentError # that means some is not integer
      return false
    end
    true
  end

  private :valid_selections?, :is_selection?
end

# ################ test
#
# res = UserResponseParser.new('0 f ')
# puts res.response_type
# puts res.is_valid?
# puts res.get_response
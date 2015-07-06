class UserResponseParser

  NEXT = 'n'
  PREVIOUS = 'p'
  STOP = 's'
  FINISH = 'f'

  def initialize(response_str)
    @response_str = response_str

    @commands = [NEXT, PREVIOUS, STOP, FINISH]
  end

  def response_type
    return :command if is_command?
    return :selection if is_selection?
  end

  def get_response
    return get_command if response_type == :command
    return get_selection if response_type == :selection
  end

  def get_command
    user_response = @response_str

    return NEXT if user_response.index NEXT
    return PREVIOUS  if user_response.index PREVIOUS
    return STOP if  user_response.index STOP
    return FINISH if  user_response.index FINISH
  end

  def get_selection
    return nil if response_type == :command

    sels = @response_str

    sels = sels.chomp.split(/\D+/)
    sels = sels.keep_if { |v| v.length > 0 }

    sels.map { |e| e.to_i }
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

  def is_valid?
    return false unless is_command? || is_selection?
    true
  end
end

# ################ test
#
# res = UserResponseParser.new('0 f ')
# puts res.response_type
# puts res.is_valid?
# puts res.get_response
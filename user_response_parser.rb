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
    has_command_char? ? :command : :selection
  end

  def get_response
    return get_selection if response_type == :command
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

  def has_command_char?
    @commands.any? { |x| @response_str[x] }
  end

end

if $0 == __FILE__
  response = '1, 2, 3 f '
  res = UserResponseParser.new(response)

  puts res.get_response
  puts res.response_type
end
class UserResponses

  INVALID = :invalid
  SAVE = :save
  NEXT = :next
  PREVIOUS = :previous
  STOP = :stop
  FINISH = :finish

  attr_reader :selections

  def initialize
    @selections = [] # array to save selections
  end

  def add_response(res)
    # res is an instance of UserResponseParser

    if res.response_type == :command
      set_next_task(res.get_response)
    elsif res.response_type == :selection
      @selections << res.get_response # save
      set_next_task :save
    else
      set_next_task :invalid
    end
  end

  def get_status
    @status
  end

  private
  def set_next_task(task)
    case task
      when 'p'
        @status = :previous
      when 'n'
        @status = :next
      when 's'
        @status = :stop
      when 'f'
        @status = :finish
      else
        @status = task
    end
  end

end
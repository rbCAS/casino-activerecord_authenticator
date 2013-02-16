require 'casino_core/authenticator'

class CASinoCore::Authenticator::ActiveRecord

  # @param [Hash] options
  def initialize(options)
    @options = options
  end

  def validate(username, password)
    @username = username
    @password = password
    nil
  end
end

require 'casino_core/authenticator'
require 'active_record'
require 'unix_crypt'

class CASinoCore::Authenticator::ActiveRecord

  # @param [Hash] options
  def initialize(options)
    @options = options
    ::ActiveRecord::Base.establish_connection @options[:connection]

    eval <<-END
      class #{@options[:table].classify} < ActiveRecord::Base
      end
    END

    @model = "#{self.class.to_s}::#{@options[:table].classify}".constantize
  end

  def validate(username, password)
    user = @model.send("find_by_#{@options[:username_column]}!", username)
    password_from_database = user.send(@options[:password_column])

    if valid_password?(password, password_from_database)
      { username: user.send(@options[:username_column]) }
    else
      false
    end

  rescue ActiveRecord::RecordNotFound
    false
  end

  private
  def valid_password?(password, password_from_database)
    UnixCrypt.valid?(password, password_from_database)
  end
end

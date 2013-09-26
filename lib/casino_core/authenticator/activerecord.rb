require 'active_record'
require 'unix_crypt'
require 'bcrypt'
require 'digest/sha1'

class CASinoCore::Authenticator::ActiveRecord

  class AuthDatabase < ::ActiveRecord::Base
    self.abstract_class = true
  end

  # @param [Hash] options
  def initialize(options)
    @options = options

    eval <<-END
      class #{self.class.to_s}::#{@options[:table].classify} < AuthDatabase
      end
    END

    @model = "#{self.class.to_s}::#{@options[:table].classify}".constantize
    @model.establish_connection @options[:connection]
  end

  def validate(username, password)
    @model.verify_active_connections!
    user = @model.send("find_by_#{@options[:username_column]}!", username)
    password_from_database = user.send(@options[:password_column])

    if valid_password?(password, password_from_database, (user.salt if user.respond_to?(:salt)))
      { username: user.send(@options[:username_column]), extra_attributes: extra_attributes(user) }
    else
      false
    end

  rescue ActiveRecord::RecordNotFound
    false
  end

  private
  def secure_digest(*args)
    Digest::SHA1.hexdigest(args.flatten.join('--'))
  end

  def valid_password?(password, password_from_database, salt=nil)
    return false if password_from_database.blank?
    magic = password_from_database.split('$')[1]
    case magic
    when /\A2a?\z/
      valid_password_with_bcrypt?(password, password_from_database)
    when /\Asha?\z/
      valid_password_with_sha1_crypt?(password, password_from_database, salt)
    else
      valid_password_with_unix_crypt?(password, password_from_database)
    end
  end

  def valid_password_with_bcrypt?(password, password_from_database)
    password_with_pepper = password + @options[:pepper].to_s
    BCrypt::Password.new(password_from_database) == password_with_pepper
  end

  def valid_password_with_unix_crypt?(password, password_from_database)
    UnixCrypt.valid?(password, password_from_database)
  end

  def valid_password_with_sha1_crypt?(password, password_from_database, salt)
    site_auth_key = digest = @options[:pepper].to_s
    10.times do 
      digest = secure_digest(digest, salt, password, site_auth_key)
    end
    digest == password_from_database.split('$')[2]
  end

  def extra_attributes(user)
    attributes = {}
    extra_attributes_option.each do |attribute_name, database_column|
      attributes[attribute_name] = user.send(database_column)
    end
    attributes
  end

  def extra_attributes_option
    @options[:extra_attributes] || {}
  end
end

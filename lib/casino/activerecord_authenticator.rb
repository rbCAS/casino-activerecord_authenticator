require 'active_record'
require 'unix_crypt'
require 'bcrypt'
require 'phpass'

class CASino::ActiveRecordAuthenticator

  class AuthDatabase < ::ActiveRecord::Base
    self.abstract_class = true
  end

  # @param [Hash] options
  def initialize(options)
    if !options.respond_to?(:deep_symbolize_keys)
      raise ArgumentError, "When assigning attributes, you must pass a hash as an argument."
    end
    @options = options.deep_symbolize_keys

    raise ArgumentError, 'Connection information is missing' unless @options[:connection]
    raise ArgumentError, 'Table name is missing' unless @options[:table]
    raise ArgumentError, 'Username column is missing' unless @options[:username_column]
    raise ArgumentError, 'Password column is missing' unless @options[:password_column]

    eval <<-END
      class #{model_class_name} < AuthDatabase
        self.table_name = "#{@options[:table]}"
        self.inheritance_column = :_type_disabled
      end
    END

    @model = model_class_name.constantize
    @model.establish_connection @options[:connection]
  end

  def validate(username, password)
    user = user_by_constraints(username)
    password_from_database = user.send(@options[:password_column])

    if valid_password?(password, password_from_database)
      user_data(user)
    else
      false
    end

  rescue ActiveRecord::RecordNotFound
    false
  end

  def load_user_data(username)
    user_data(user_by_constraints(username))
  rescue ActiveRecord::RecordNotFound
    nil
  end

  private
  def model_class_name
    if @options[:model_name]
      model_name = @options[:model_name]
    else
      model_name = @options[:table]
      if @options[:connection].kind_of?(Hash) && @options[:connection][:database]
        model_name = "#{@options[:connection][:database].gsub(/[^a-zA-Z]+/, '')}_#{model_name}"
      end
      model_name = model_name.classify
    end
    "#{self.class.to_s}::#{model_name}"
  end

  def find_by_query
    constraints = ''
    @options.fetch(:constraint_columns, {}).each_key { |key| constraints += "_and_#{key}" }
    "find_by_#{@options[:username_column]}#{constraints}!"
  end

  def user_by_constraints(username)
    args = [username]
    args += @options.fetch(:constraint_columns, {}).values
    @model.send(find_by_query, *args)
  end

  def user_data(user)
    { username: user.send(@options[:username_column]), extra_attributes: extra_attributes(user) }
  end

  def valid_password?(password, password_from_database)
    return false if password_from_database.blank?
    magic = password_from_database.split('$')[1]
    case magic
    when /\A2a?\z/
      valid_password_with_bcrypt?(password, password_from_database)
    when /\AH\z/, /\AP\z/
      valid_password_with_phpass?(password, password_from_database)
    else
      valid_password_as_plaintext?(password, password_from_database) ||
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

  def valid_password_with_phpass?(password, password_from_database)
    Phpass.new().check(password, password_from_database)
  end

  def valid_password_as_plaintext?(password, password_from_database)
    password == password_from_database
  end

  def extra_attributes(user)
    attributes = {}
    @options.fetch(:extra_attributes, {}).each do |attribute_name, database_column|
      attributes[attribute_name] = user.send(database_column)
    end
    attributes
  end
end

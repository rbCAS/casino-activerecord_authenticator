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
    raise ArgumentError, "Table name is missing" unless @options[:table]

    resolver = ActiveRecord::ConnectionAdapters::ConnectionSpecification::Resolver.new(
      { 'default' => @options[:connection] }
    )
    spec = resolver.spec(:default)
    @pool = ActiveRecord::ConnectionAdapters::ConnectionPool.new(spec)
  end

  def validate(username, password)
    user_hash = find_user_hash(username)

    return false unless user_hash.present?

    password_from_database = user_hash[@options[:password_column].to_s]

    if valid_password?(password, password_from_database)
      user_data(user_hash)
    else
      false
    end
  end

  def load_user_data(username)
    user_hash = find_user_hash(username)
    return nil unless user_hash.present?
    user_data(user_hash)
  end

  private

  def find_user_hash(username)
    @pool.with_connection { |conn|
      sql = "SELECT * FROM #{@options[:table]} WHERE #{@options[:username_column]}=#{conn.quote(username)} LIMIT 1"
      user_hash = conn.exec_query(sql)[0]
    }
  end

  def user_data(user_hash)
    {
      username: user_hash[@options[:username_column].to_s],
      extra_attributes: extra_attributes(user_hash)
    }
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

  def extra_attributes(user_hash)
    attributes = {}
    extra_attributes_option.each do |attribute_name, database_column|
      attributes[attribute_name] = user_hash[database_column.to_s]
    end
    attributes
  end

  def extra_attributes_option
    @options[:extra_attributes] || {}
  end
end

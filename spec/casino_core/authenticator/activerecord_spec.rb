require 'spec_helper'
require 'casino_core/authenticator/activerecord'

describe CASinoCore::Authenticator::ActiveRecord do

  let(:options) do
    {
      connection: {
        adapter: 'sqlite3',
        database: ':memory:'
      },
      table: 'users',
      username_column: 'username',
      password_column: 'password',
      extra_attributes: {
        email: 'mail_address'
      }
    }
  end

  before do

    @authenticator = CASinoCore::Authenticator::ActiveRecord.new(options)

    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string :username
          t.string :password
          t.string :mail_address
        end
      end
    end

    CASinoCore::Authenticator::ActiveRecord::User.create!(
      username: 'test',
      password: '$5$cegeasjoos$vPX5AwDqOTGocGjehr7k1IYp6Kt.U4FmMUa.1l6NrzD', # password: testpassword
      mail_address: 'mail@example.org')
  end

  describe '#validate' do

    context 'valid username' do
      context 'valid password' do
        it 'returns the username' do
          @authenticator.validate('test', 'testpassword')[:username].should eq('test')
        end

        it 'returns the extra attributes' do
          @authenticator.validate('test', 'testpassword')[:email].should eq('mail@example.org')
        end
      end

      context 'invalid password' do
        it 'returns false' do
          @authenticator.validate('test', 'wrongpassword').should eq(false)
        end
      end
    end

    context 'invalid username' do
      it 'returns false' do
        @authenticator.validate('does-not-exist', 'testpassword').should eq(false)
      end
    end

    context 'support for bcrypt' do
      before do
        CASinoCore::Authenticator::ActiveRecord::User.create!(
          username: 'test2',
          password: '$2a$10$dRFLSkYedQ05sqMs3b265e0nnJSoa9RhbpKXU79FDPVeuS1qBG7Jq', # password: testpassword2
          mail_address: 'mail@example.org')
      end

      it 'is able to handle bcrypt password hashes' do
        @authenticator.validate('test2', 'testpassword2').should be_instance_of(Hash)
      end
    end

  end

end

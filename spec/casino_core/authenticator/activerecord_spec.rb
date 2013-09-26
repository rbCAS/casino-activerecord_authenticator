require 'spec_helper'
require 'casino_core/authenticator/activerecord'

describe CASinoCore::Authenticator::ActiveRecord do

  let(:pepper) { nil }
  let(:extra_attributes) {{ email: 'mail_address' }}
  let(:options) do
    {
      connection: {
        adapter: 'sqlite3',
        database: '/tmp/casino-test-auth.sqlite'
      },
      table: 'users',
      username_column: 'username',
      password_column: 'password',
      pepper: pepper,
      extra_attributes: extra_attributes
    }
  end

  before do
    @authenticator = CASinoCore::Authenticator::ActiveRecord.new(options)

    ::ActiveRecord::Base.establish_connection options[:connection]

    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string :username
          t.string :password
          t.string :mail_address
          t.string :salt
        end
      end
    end

    CASinoCore::Authenticator::ActiveRecord::User.create!(
      username: 'test',
      password: '$5$cegeasjoos$vPX5AwDqOTGocGjehr7k1IYp6Kt.U4FmMUa.1l6NrzD', # password: testpassword
      mail_address: 'mail@example.org')
  end

  after do
    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        drop_table :users
      end
    end
  end

  describe '#validate' do

    context 'valid username' do
      context 'valid password' do
        it 'returns the username' do
          @authenticator.validate('test', 'testpassword')[:username].should eq('test')
        end

        it 'returns the extra attributes' do
          @authenticator.validate('test', 'testpassword')[:extra_attributes][:email].should eq('mail@example.org')
        end

        context 'when no extra attributes given' do
          let(:extra_attributes) { nil }

          it 'returns an empty hash for extra attributes' do
            @authenticator.validate('test', 'testpassword')[:extra_attributes].should eq({})
          end
        end
      end

      context 'invalid password' do
        it 'returns false' do
          @authenticator.validate('test', 'wrongpassword').should eq(false)
        end
      end

      context 'NULL password field' do
        it 'returns false' do
          user = CASinoCore::Authenticator::ActiveRecord::User.first
          user.password = nil
          user.save!

          @authenticator.validate('test', 'wrongpassword').should eq(false)
        end
      end

      context 'empty password field' do
        it 'returns false' do
          user = CASinoCore::Authenticator::ActiveRecord::User.first
          user.password = ''
          user.save!

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

    context 'support for bcrypt with pepper' do
      let(:pepper) { 'abcdefg' }

      before do
        CASinoCore::Authenticator::ActiveRecord::User.create!(
          username: 'test3',
          password: '$2a$10$ndCGPWg5JFMQH/Kl6xKe.OGNaiG7CFIAVsgAOJU75Q6g5/FpY5eX6', # password: testpassword3, pepper: abcdefg
          mail_address: 'mail@example.org')
      end

      it 'is able to handle bcrypt password hashes' do
        @authenticator.validate('test3', 'testpassword3').should be_instance_of(Hash)
      end
    end

    context 'support for sha1 restful-authentication' do
      let(:pepper) { '9df92c193273ae9adf804195641b50828dee0088' }
      before do
        CASinoCore::Authenticator::ActiveRecord::User.create!(
          username: 'test4',
          password: '$sha$a5a2725edcb9f8f5764047dc37c0a0c279dba699',
          mail_address: 'mail@example.org',
          salt: 'b1676d830c1558b584491089239f3ff448e5277e')
      end

      it 'is able to handle sha1 restful-authentication password hashes' do
        @authenticator.validate('test4', 'kapastry').should be_instance_of(Hash)
      end
    end

  end

end

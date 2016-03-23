require 'spec_helper'
require 'casino/activerecord_authenticator'

describe CASino::ActiveRecordAuthenticator do

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
  let(:faulty_options){ options.merge(table: nil) }
  let(:connection_as_string) { options.merge(connection: 'sqlite3:/tmp/casino-test-auth.sqlite') }
  let(:user_class) { described_class::TmpcasinotestauthsqliteUser }

  subject { described_class.new(options) }

  before do
    subject # ensure everything is initialized

    ::ActiveRecord::Base.establish_connection options[:connection]

    ActiveRecord::Migration.suppress_messages do
      ActiveRecord::Schema.define do
        create_table :users do |t|
          t.string :username
          t.string :password
          t.string :mail_address
        end
      end
    end

    user_class.create!(
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

  describe 'custom model name' do
    let(:model_name) { 'DongerRaiser' }
    before do
      options[:model_name] = model_name
    end

    it 'should create the model with the name specified' do
      described_class.new(options)
      expect(described_class.const_get(model_name)).to be_a Class
    end
  end

  describe 'invalid yaml input' do
    context 'no hash input' do
      it 'throws an argument error if the supplied input was not hash' do
        expect{described_class.new("string")}.to raise_error ArgumentError
      end
      it 'does not throw an error if the correct hash was supplied' do
        expect{described_class.new(options)}.not_to raise_error
      end
    end
    context 'invalid table name' do
      it 'throws an argument error if the table was nil/not supplied' do
        expect{described_class.new(faulty_options)}.to raise_error ArgumentError
      end
    end
  end

  describe '#load_user_data' do
    context 'valid username' do
      it 'returns the username' do
        subject.load_user_data('test')[:username].should eq('test')
      end

      it 'returns the extra attributes' do
        subject.load_user_data('test')[:extra_attributes][:email].should eq('mail@example.org')
      end
    end

    context 'invalid username' do
      it 'returns nil' do
        subject.load_user_data('does-not-exist').should eq(nil)
      end
    end
  end

  describe '#validate' do

    context 'valid username' do
      context 'valid password' do
        it 'returns the username' do
          subject.validate('test', 'testpassword')[:username].should eq('test')
        end

        it 'returns the extra attributes' do
          subject.validate('test', 'testpassword')[:extra_attributes][:email].should eq('mail@example.org')
        end

        context 'when no extra attributes given' do
          let(:extra_attributes) { nil }

          it 'returns an empty hash for extra attributes' do
            subject.validate('test', 'testpassword')[:extra_attributes].should eq({})
          end
        end
      end

      context 'invalid password' do
        it 'returns false' do
          subject.validate('test', 'wrongpassword').should eq(false)
        end
      end

      context 'NULL password field' do
        it 'returns false' do
          user = user_class.first
          user.password = nil
          user.save!

          subject.validate('test', 'wrongpassword').should eq(false)
        end
      end

      context 'empty password field' do
        it 'returns false' do
          user = user_class.first
          user.password = ''
          user.save!

          subject.validate('test', 'wrongpassword').should eq(false)
        end
      end
    end

    context 'invalid username' do
      it 'returns false' do
        subject.validate('does-not-exist', 'testpassword').should eq(false)
      end
    end

    context 'support for bcrypt' do
      before do
        user_class.create!(
          username: 'test2',
          password: '$2a$10$dRFLSkYedQ05sqMs3b265e0nnJSoa9RhbpKXU79FDPVeuS1qBG7Jq', # password: testpassword2
          mail_address: 'mail@example.org')
      end

      it 'is able to handle bcrypt password hashes' do
        subject.validate('test2', 'testpassword2').should be_instance_of(Hash)
      end
    end

    context 'support for bcrypt with pepper' do
      let(:pepper) { 'abcdefg' }

      before do
        user_class.create!(
          username: 'test3',
          password: '$2a$10$ndCGPWg5JFMQH/Kl6xKe.OGNaiG7CFIAVsgAOJU75Q6g5/FpY5eX6', # password: testpassword3, pepper: abcdefg
          mail_address: 'mail@example.org')
      end

      it 'is able to handle bcrypt password hashes' do
        subject.validate('test3', 'testpassword3').should be_instance_of(Hash)
      end
    end

    context 'support for phpass' do
      before do
        user_class.create!(
          username: 'test4',
          password: '$P$9IQRaTwmfeRo7ud9Fh4E2PdI0S3r.L0', # password: test12345
          mail_address: 'mail@example.org')
      end

      it 'is able to handle phpass password hashes' do
        subject.validate('test4', 'test12345').should be_instance_of(Hash)
      end
    end

    context 'support for unencrypted' do
      before do
        user_class.create!(
            username: 'test5',
            password: 'testpassword5',
            mail_address: 'mail@example.org')
      end

      it 'is able to handle plaintext passwords' do
        subject.validate('test5', 'testpassword5').should be_instance_of(Hash)
      end

      it 'returns false when plaintext password is invalid' do
        subject.validate('test5', 'testpassword').should eq(false)
      end

      it 'returns false when bcrypt password hash is used as plaintext password' do
        subject.validate('test5', '$2a$10$ndCGPWg5JFMQH/Kl6xKe.OGNaiG7CFIAVsgAOJU75Q6g5/FpY5eX6').should eq(false)
      end

      it 'returns false when phpass password hash is used as plaintext password' do
        subject.validate('test5', '$P$9IQRaTwmfeRo7ud9Fh4E2PdI0S3r.L0').should eq(false)
      end
    end

    context 'support for connection string' do

      it 'should not raise an error' do
        expect{described_class.new(connection_as_string)}.to_not raise_error
      end

      it 'returns the username' do
        described_class.new(connection_as_string).load_user_data('test')[:username].should eq('test')
      end
    end

  end

end

# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'casino/activerecord_authenticator/version'

Gem::Specification.new do |s|
  s.name        = 'casino-activerecord_authenticator'
  s.version     = CASino::ActiveRecordAuthenticator::VERSION
  s.authors     = ['Nils Caspar', 'Raffael Schmid']
  s.email       = ['ncaspar@me.com', 'raffael@yux.ch']
  s.homepage    = 'http://rbcas.org/'
  s.license     = 'MIT'
  s.summary     = 'Provides mechanism to use ActiveRecord as an authenticator for CASino.'
  s.description = 'This gem can be used to allow the CASino backend to authenticate against an SQL server using ActiveRecord.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_development_dependency 'rake', '~> 10.0'
  s.add_development_dependency 'rspec', '~> 2.12'
  s.add_development_dependency 'simplecov', '~> 0.7'
  s.add_development_dependency 'sqlite3', '~> 1.3.7'
  s.add_development_dependency 'coveralls'

  s.add_runtime_dependency 'activerecord', '~> 4.1.0'
  s.add_runtime_dependency 'unix-crypt', '~> 1.1'
  s.add_runtime_dependency 'bcrypt', '~> 3.0'
  s.add_runtime_dependency 'casino', '~> 3.0.0.pre.1'
  s.add_runtime_dependency 'phpass-ruby', '~> 0.1'
end

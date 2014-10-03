# casino-activerecord_authenticator [![Build Status](https://travis-ci.org/rbCAS/casino-activerecord_authenticator.png?branch=master)](https://travis-ci.org/rbCAS/casino-activerecord_authenticator) [![Coverage Status](https://coveralls.io/repos/rbCAS/casino-activerecord_authenticator/badge.png)](https://coveralls.io/r/rbCAS/casino-activerecord_authenticator)

Provides mechanism to use ActiveRecord as an authenticator for [CASino](https://github.com/rbCAS/CASino).

ActiveRecord supports many SQL databases such as MySQL, PostgreSQL, SQLite, ...

To use the ActiveRecord authenticator, configure it in your cas.yml:

    authenticators:
      my_company_sql:
        authenticator: "ActiveRecord"
        options:
          connection:
            adapter: "mysql2"
            host: "localhost"
            username: "casino"
            password: "secret"
            database: "users"
          table: "users"
          username_column: "username"
          password_column: "password"
          pepper: "suffix of the password"            # optional
          extra_attributes:
            email: "email_database_column"
            fullname: "displayname_database_column"

Example of configuration for SQLite:
            
    authenticators:
        sqlite:
          authenticator: "ActiveRecord"
          options:
            connection:
              adapter: sqlite3
              pool: 5
              timeout: 5000
              database: db/development.sqlite3
            table: "casino_users"
            username_column: "username"
            password_column: "authenticator"

## Contributing to casino-activerecord_authenticator

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Nils Caspar. See LICENSE.txt
for further details.


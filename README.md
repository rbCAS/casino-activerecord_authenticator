# casino_core-authenticator-activerecord [![Build Status](https://travis-ci.org/rbCAS/casino_core-authenticator-activerecord.png?branch=master)](https://travis-ci.org/rbCAS/casino_core-authenticator-activerecord)

Provides mechanism to use ActiveRecord as an authenticator for [CASinoCore](https://github.com/rbCAS/CASinoCore).

ActiveRecord supports many SQL databases such as MySQL, PostgreSQL, SQLite, ...

To use the ActiveRecord authenticator, configure it in your cas.yml:

    authenticators:
      my_company_sql:
        authenticator: "activerecord"
        options:
          connection:
            adapter: "mysql"
            host: "localhost"
            username: "casino"
            password: "secret"
            database: "users"
          table: "users"
          username_column: "username"
          password_column: "password"
          extra_attributes:
            email: "email_database_column"
            fullname: "displayname_database_column"

## Contributing to casino_core-authenticator-activerecord

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


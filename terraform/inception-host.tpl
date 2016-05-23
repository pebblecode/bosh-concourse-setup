#cloud-config
package_update: true
package_upgrade: true

packages:
  - build-essential
  - zlibc
  - zlib1g-dev
  - ruby2.0
  - ruby2.0-dev
  - openssl
  - libxslt-dev
  - libxml2-dev
  - libssl-dev
  - libreadline6
  - libreadline6-dev
  - libyaml-dev
  - libsqlite3-dev
  - sqlite3
  - libxslt1-dev
  - libpq-dev
  - libmysqlclient-dev
output : { all : '| tee -a /var/log/cloud-init-output.log' }


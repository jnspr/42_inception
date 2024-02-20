#!/bin/sh

set -e

# Log with colored prefix :)
function log()
{
    echo -e "\e[33minception-mariadb\e[0m | $@"
}

# Run this if the container is unprepared
if [ ! -e /etc/.inception_firstrun ]; then
    # Allow outside connections to the database server
    log 'Adjusting server configuration'
    cat << EOF >> /etc/my.cnf.d/mariadb-server.cnf
[mysqld]
bind-address=0.0.0.0
skip-networking=0
EOF

    # Mark the container as prepared
    touch /etc/.inception_firstrun
fi

# Run this if the database volume is unpopulated
if [ ! -e /var/lib/mysql/.inception_firstrun ]; then
    # Refuse to continue if any environment variable is missing
    if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
        log 'Please set MYSQL_ROOT_PASSWORD, refusing to continue'
        exit 1
    fi
    if [ -z "$MYSQL_USER" ]; then
        log 'Please set MYSQL_USER, refusing to continue'
        exit 1
    fi
    if [ -z "$MYSQL_PASSWORD" ]; then
        log 'Please set MYSQL_PASSWORD, refusing to continue'
        exit 1
    fi
    if [ -z "$MYSQL_DATABASE" ]; then
        log 'Please set MYSQL_DATABASE, refusing to continue'
        exit 1
    fi

    # Install the database
    log 'Installing database'
    mysql_install_db \
        --auth-root-authentication-method=socket \
        --datadir=/var/lib/mysql \
        --skip-test-db \
        --user=mysql \
        --group=mysql >/dev/null

    # Start the server as a background process and wait for it to be ready
    log 'Bringing up temporary server'
    mysqld_safe &
    mysqladmin ping -u root --silent --wait >/dev/null

    # Perform database and user initialization
    log "Performing initial configuration"
    cat << EOF | mysql --protocol=socket -u root -p=
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
GRANT ALL PRIVILEGES on *.* to 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

    # Shutdown the background server
    log 'Shutting down temporary server'
    mysqladmin shutdown

    # Mark the database volume as populated
    touch /var/lib/mysql/.inception_firstrun
fi

# Start the server as the only process in the container
log 'Starting server'
exec mysqld_safe

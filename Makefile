VERSION ?= 0.0.2

MARIADB_VERSION := 10.11.5
MARIADB_FOLDER := mariadb-${MARIADB_VERSION}-linux-systemd-x86_64
OS := $(shell uname -s)

.PHONY: prep
prep:
	@echo "Preparing build/bin for usage..."
	@-cd build/bin && unlink assets
	@echo "(if you get an unlink error above, ignore)"
	@cd build/bin && ln -s ../../base/assets assets
	@wget https://raw.githubusercontent.com/EQEmu/Server/master/utils/scripts/eqemu_server.pl -O build/bin/eqemu_server.pl
	@cp -R -u -p base/eqemu_config.json build/bin/eqemu_config.json
	@mkdir -p build/bin/logs
	@mkdir -p build/bin/shared
	@echo "Done"

binaries:
	wget https://github.com/EQEmu/Server/releases/latest/download/eqemu-server-linux-x64.zip
	unzip eqemu-server-linux-x64.zip -d build/bin
	-rm eqemu-server-linux-x64.zip

source-mariadb:
	cd build/bin && perl eqemu_server.pl source_peq_db
	cd build/bin && perl eqemu_server.pl check_db_updates
source-opcodes:
	cd build/bin && perl eqemu_server.pl opcodes
	

# Runs loginserver binary
.PHONY: loginserver
loginserver:
	cd build/bin && ./loginserver

# Runs shared_memory binary
.PHONY: shared
shared:
	cd build/bin && ./shared_memory

# Runs zone binary
.PHONY: zone
zone:
	@-rm build/bin/logs/zone/zone*.log
	cd build/bin && ./zone

# Runs world binary
.PHONY: world
world:
	@-rm build/bin/logs/world*.log
	cd build/bin && ./world

# Runs ucs binary
.PHONY: ucs
ucs:
	@-rm build/bin/logs/ucs*.log
	cd build/bin && ./ucs

# Runs queryserv binary
.PHONY: queryserv
queryserv:
	@-rm build/bin/logs/query_server*.log
	cd build/bin && ./queryserv

# Start mariaDB standalone
.PHONY: mariadb
mariadb:
	@-killall mariadbd
	cd build/bin/db/${MARIADB_FOLDER}/bin && ./mysqld_safe --defaults-file=${PWD}/build/bin/db/my.cnf &

mariadb-stop:
	@-killall mariadb
# Backs up the database
.PHONY: backup-db
backup-db:
	@echo "Backing up the database and zipping it..."
	@-rm -rf build/bin/db/backup
	@-mkdir -p build/bin/db/backup
	cd build/bin/db/${MARIADB_FOLDER}/bin && ./mariabackup --defaults-file=${PWD}/build/bin/db/my.cnf --backup --user=${USER} --socket=${PWD}/build/bin/db/mysql/mysqld.sock --target-dir=${PWD}/build/bin/db/backup
	cd build/bin/db && tar -czvf backup.tar.gz backup
	@-rm -rf build/bin/db/backup
	@echo "Backup complete. The file is located at build/bin/db/backup.tar.gz"

# Restores the database
.PHONY: restore-db
restore-db:
	@echo "Restoring the database from backup..."
	@-mkdir -p build/bin/db/backup
	cd build/bin/db && tar -xf backup.tar.gz
	cd build/bin/db/${MARIADB_FOLDER}/bin && ./mariabackup --defaults-file=${PWD}/build/bin/db/my.cnf --prepare --user=${USER} --socket=${PWD}/build/bin/db/mysql/mysqld.sock --target-dir=${PWD}/build/bin/db/backup
	cd build/bin/db && rm -rf backup.tar.gz
	@echo "Restore complete."

# Initializes a standalone copy of mariadb-server
.PHONY: init-db
init-mariadb:
	@echo "Initializing a standalone copy of mariadb-server..."
	@-mkdir -p build/bin/db
	@mkdir -p build/bin/logs
	cd build/bin/db && wget https://mirrors.xtom.com/mariadb//mariadb-${MARIADB_VERSION}/bintar-linux-systemd-x86_64/${MARIADB_FOLDER}.tar.gz
	cd build/bin/db && tar -xf ${MARIADB_FOLDER}.tar.gz
	cd build/bin/db && rm -rf ${MARIADB_FOLDER}.tar.gz
	cp -R -u -p base/my.cnf build/bin/db/my.cnf
	cd build/bin/db/${MARIADB_FOLDER}/scripts && ./mariadb-install-db --defaults-file=${PWD}/build/bin/db/my.cnf --datadir=${PWD}/build/bin/db/data --basedir=${PWD}/build/bin/db/${MARIADB_FOLDER}
	@#cd build/bin/db/${MARIADB_FOLDER}/bin && ./mysqld_safe --initialize-insecure --datadir=${PWD}/build/bin/db/data --defaults-file=${PWD}/build/bin/db/my.cnf
	@echo "MariaDB is now initialized. Use 'make mariadb' to run it."


.PHONY: inject-mariadb
inject-mariadb:
	-mysql -u vscode -S build/bin/db/mysql/mysqld.sock -e 'CREATE DATABASE takp;'
	-mysql -u vscode -S build/bin/db/mysql/mysqld.sock -e "CREATE USER 'takp'@'127.0.0.1' IDENTIFIED BY 'takppass';"
	-mysql -u vscode -S build/bin/db/mysql/mysqld.sock -e "GRANT ALL PRIVILEGES ON *.* TO 'takp'@'127.0.0.1';"
	@#-unzip -p base/db.sql.zip | mysql -u vscode -S build/bin/db/mysql/mysqld.sock --database takp

.PHONY: update-version
update-version:
	sed -i 's/#define VERSION ".*/#define VERSION "$(VERSION)"/g' common/version.h

# CICD triggers this
.PHONY: set-version
set-version: update-version
	sed -i 's/#define VERSION ".*/#define VERSION "$(VERSION)"/g' common/version.h
	@echo "VERSION=${VERSION}" >> $$GITHUB_ENV
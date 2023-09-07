# Server Snap

Snaps a server over with a docker container

## Usage

**Editor**

- Download [Visual Studio Code](https://code.visualstudio.com/)
- Open your project in vscode.
- You should get a prompt to reopen the project in a dev container. Say yes. If you miss the prompt, click the bottom left area and a drop down will appear that lets you reopen in dev container.
- Once in the dev container, open a terminal using shift+~

**Initial Setup**

- We'll be using a standalone binary mysql install for dev purposes.
- `make init-mariadb`. This will create build/bin/db and download/create a standalone copy of mariadb.
- `make mariadb`. This will start a mysql server. May have to press enter to get prompt after it starts.
- `make inject-mariadb`. This sets up a takp user and such. If you get an error "mysql not found", try running `sudo apt install mariadb-client`
- `make prep` This will create a build subfolder, and copy files from base. This can be ran multiple times, files are checked prior to copying.
- `make binaries` This will download the latest binaries for the server and client. This can be ran multiple times, files are checked prior to downloading.
- `make source-mariadb` This will source the database with latest peq. May take a while. If you get an error `Can't locate JSON.pm` use `sudo apt install libjson-perl`

- `make shared` Run shared memory. See if any errors
- `make world` Start world. This will lock up the terminal, you can create a new one for additional processes.
- `make zone` Spawn a zone. This will lock up the terminal, you can create a new one for additional processes.

**Debugging**

Use the (gdb) prefixed debuggers to start each process.

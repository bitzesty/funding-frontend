# funding-frontend

## Running locally on Ubuntu WSL2 

### Setting up WSL2 with Ubuntu 

Open a new windows terminal or powershell instance.

#### Install WSL 

`wsl --update --web-download`

#### Install Ubuntu 

This will install Ubuntu by default. 

Then run  

`wsl --install--web-download` 

Alternatively, list the available distros to install explicitly 

`wsl --list –online` 

`wsl –install –d Ubuntu` 

When installed.  Create a username and password (whatever you like) 

Then update: 

`sudo apt-get update` 

`sudo apt-get upgrade`

#### Allow WSL2 internet access 

Note for managed machines. To allow the virtual linux machine to access the internet, the DNS config will need to be amended to the address 8.8.8.8. This is because the local DNS server on managed machines does not work. 8.8.8.8 is Google's public DNS server. Run the commands below to amend the config and preserve it after the host machine is rebooted.

To prevent this, amend with: 

```bash 
sudo rm /etc/resolv.conf` 
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf' 
sudo bash -c 'echo "[network]" > /etc/wsl.conf' 
sudo bash -c 'echo "generateResolvConf = false" >> /etc/wsl.conf' 
sudo chattr +i /etc/resolv.conf
```

### Install Homebrew 

`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` 

then followed on screen instructions for adding to path and installing brew dependencies,  

Adding to a bash path: 

`(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/<user>/.profile` 

`eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` 

`sudo apt get install build essential `

`Brew install gcc` 
 
Test with: 

`brew –help` 

### Install ZShell (optional) 


Z Shell is an extension of the Bourne Shell that supports custom plugins and customisation not possible with the given Bash Shell. It allows for the integration of git and other tools directly into the cmd line with oh-my-zsh.  

To install ZShell as the default terminal: 

`sudo apt-get install zsh` 

`sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" `

 
Configuring zsh/oh-my-zsh by adding the following line under the first comment of the `~/.bash.rc` file. 

Run:  

`vim  ~/.bashrc`  

and add 

```bash
if test -t 1; then 
  exec zsh 
fi 
```

Then restart your terminal instance. You should see a newly styled ZSH terminal. An example guide on how to customise the shell further to your needs can be found [here](https://blog.joaograssi.com/windows-subsystem-for-linux-with-oh-my-zsh-conemu/).  


### Install rbenv 

Note: There are options to install via apt, git or homebrew.  

It was found that homebrew (the recommended option) had path issues, and as such `apt` provided the easiest installation. 


`sudo apt install rbenv` 

To install rbenv, then 

`rbenv init` 

Then add to your relevant profile as instructed, then  

`brew install ruby-build` 

Which is required to install ruby,  then 

`rbenv install 2.6.5` 

Which installs ruby, then  

If you receive an error with Zlib, install the missing header libraries with  

`sudo apt-get install -y libreadline-dev zlib1g-dev` 

(Needed when adding ruby 2.6.5 to Ubuntu v20.*) 

Finally, if you want to set a particular ruby version across the machine 

`rbenv global 2.6.5` 

You can test by opening a ruby console

`irb` 

`puts("a string")` 


### Install and setup Postgres 

#### Installation 

If Postgres has been installed directly onto windows, consider removing.  It could reserve port 5432 for itself and  prevent the Ubuntu version from using the default port.  This means rails yml config would need to be changed, for your setup, to use the different port. 

See: https://learn.microsoft.com/en-us/windows/wsl/tutorials/wsl-database#install-postgresql 

To install: 

`sudo apt install postgresql postgresql-contrib` 

Then test with 

`psql –version`

Start postgres with the command below. See link for other commands: 

`sudo service postgresql start`

Note: This may need manually starting after reboot – check. 

#### Create a Postgres User  

The username should match your Ubuntu username, for which you installed Rails. 

`sudo -u postgres createuser -s <username>` 

Check the user by logging into psql with 

`sudo –u postgres psql`  

and running the list describe users cmd in the psql terminal 

```psql
 # \du; 
```

Then while still in PSQL, create the database 

```psql
 # create database funding_frontend_development;  
```

### Installing & Running Rails 

#### Postgres gem dependency 

libpq-fe.h is needed to run the pg gem on Ubuntu.  These are psql devtools. 

`sudo apt-get install libpq-dev` 


#### bundler 

`gem install bundler` 

Now update bundler to support our old version of rails: 

`gem update --system 3.2.3` 


#### Rails 

At the time of writing we use Rails 6.1.3.2.  This needs an old version of nokogiri to be installed first 

`gem install nokogiri -v 1.13.10` 

`gem install rails -v 6.1.3.2` 


#### Spinning up FFE 

Firstly, add the .env file.  Get this from another dev or from 1password.  Copy to the root of your cloned folder and ensure you have completed the database steps from the postres section above. 

Next install gems 

`bundle install` 

Next install node.js so that the Yarn dependencies can be met 
 
`sudo apt-get install nodejs` 

Next install Yarn 

`brew install yarn` 

And run the yarn install: 

`yarn install --check-files` 

Next setup the database for FFE with  

`bundle exec rails db:setup` 

`bundle exec rails db:migrate` 

Then run FFE with 

`bundle exec rails server`

The application will now be running locally and can be accessed by navigating to https://localhost:3000 in your browser. 



## Running locally on macOS

### Install Homebrew

Check to see if [Homebrew](https://brew.sh) is installed by running `which brew` in a terminal. If already 
installed you'll get output similar to `/usr/local/bin/brew`, otherwise the command will return `brew not found`.

If Homebrew is already installed, update it by running `brew update`. 

If Homebrew is not already installed, run 
`/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"` to install it.

### Install rbenv

Run `brew install rbenv` to install the latest version of [rbenv](https://github.com/rbenv/rbenv).

Run `rbenv init`, which will run some commands to allow `rbenv` to work with `zsh`, like updating the path.

Add `eval "$(rbenv init -)"` to your `~/.zshrc` profile.

### Install PostgreSQL

Run `brew install postgres` to install the latest version of [PostgreSQL](https://www.postgresql.org).

### Install the recommended version of Ruby

We specify a recommended version of Ruby in the [`.ruby-version`](.ruby-version) file in funding-frontend. 
To install this recommended version of Ruby, use rbenv by running `rbenv install x.y.z` inside the application 
directory (where `x.y.z` is replaced with the version number specified in [`.ruby-version`](.ruby-version)).


You may need to run `rbenv global x.y.z` to switch your terminal to use the new version.

### Install the PostgreSQL app

Download and install [Postgres.app](https://postgresapp.com).

Run the Postgres app.

### Configure the necessary environment variables

Create an empty `.env` file in your application directory by running `touch .env` in a terminal.

The necessary environment variables in order to run the application are stored in the team's shared
1Password vault. If you don't have access to the shared 1Password vault, contact @stuartmccoll or @ptrelease.

With access to the vault, copy the contents of `funding-frontend.env` into your own `.env` file.

### Install the PostgreSQL Gem

Install the PostgreSQL Gem, telling it the path of PostgreSQL. If PostgreSQL is installed in a default 
location, the command will look like:

```bash
gem install pg -- --with-pg-config=/Applications/Postgres.app/Contents/Versions/latest/bin/pg_config
```

### Install Bundler

Run `gem install bundler` to install [Bundler](https://bundler.io).

### Install Yarn

Run `brew install yarn` to install [Yarn]((https://yarnpkg.com/lang/en/docs/install/#mac-stable)).

### Install necessary application dependencies

Run `bundle install` to install the Ruby dependencies necessary for the application to run. These are 
specified in the application's `Gemfile`.

Run `yarn install` to install the Yarn dependencies necessary for the application to run. These are
specified in the application's `package.json` and `yarn.lock` files.

### Initialise the database

Run `bundle exec rails db:setup` in your terminal.  If the database needs creating, run
`psql` then `create database funding_frontend_development;`.

Run `bundle exec rails db:seed` in your terminal. This will have the effect of populating
relevant database tables with the necessary rows to run the application.

### Running the funding-frontend application

Run `bundle exec rails server` (or `bundle exec rails s` for a shorter command) in your terminal. 
The application will now be running locally and can be accessed by navigating to 
`https://localhost:3000` in your browser.

---

## Running the automated test suite

### RSpec

Server-side code is tested using [RSpec](https://rspec.info).

To run the RSpec test suite, run `bundle exec rspec` in your terminal.

### Jest

Client-side code is tested using [Jest](https://jestjs.io).

To run the Jest test suite, run `yarn jest` in your terminal.

---

## Caching

Addresses are cached after searching by postcode so that they can be referred to later in the user journey. 
By default, Ruby-on-Rails in development mode runs with caching disabled. In order to see caching work in 
development, run `bundle exec rails dev:cache` in your terminal.

---

## Toggling feature flags

Some elements of functionality are sat behind feature flags, which have been implemented using 
[Flipper](https://github.com/jnunemaker/flipper).

To toggle functionality, a Flipper needs to exist. Flipper rows exist within the `flipper_features` and 
`flipper_gates` tables on the database. The `flipper_gates` are populated with a database migration. 
The `flipper_features` are populated at app runtime, provided rows exist in `flipper.rb`.

Update a `flipper_gates` row by running a SQL statement such as (after running 
`psql funding_frontend_development` in your terminal to connect to the database):

```postgresql
UPDATE flipper_gates SET value = true WHERE feature_key = '<key_name>';   
```

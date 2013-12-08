The Humon Wiki
==============

Getting Started
---------------

To get started, you will need to be running either a posix operating
system (linux, osx, bsd).  Instructions are provided here for setting
up a development environment under Ubuntu (13.10).

The basic things one needs to develop are:
 - nodejs (v0.10)
 - npm (node package manager)
 - meteorite

To install these, the following process can be followed (google to
determine analogous steps for other environments):

Step 1: Install nodejs (recent)/npm from chris-lea ppa:

    $ sudo apt-get update
    $ sudo apt-get install -y python-software-properties python g++ make curl
    $ sudo add-apt-repository -y ppa:chris-lea/node.js
    $ sudo apt-get update
    $ sudo apt-get install nodejs

Step 2: Install meteorite using npm

    $ sudo -H npm install -g meteorite

Step 3: Install meteor from meteor install site

    $ curl https://install.meteor.com | /bin/sh

Step 4: Install meteorite dependencies

    $ cd path/to/wiki/source
    $ mrt install

Step 5: Run the wiki!

    $ meteor

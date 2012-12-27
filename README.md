Fsq2mixi (4sq2mixi) [![Build Status](https://secure.travis-ci.org/mugifly/Fsq2mixi.png?branch=master)](http://travis-ci.org/mugifly/Fsq2mixi)
========

When you check-in to foursquare, automation-post to mixi.

https://s1.mpnets.net/services/fsq2mixi

***

* perl 5.10 (or later)

* Mojolicious 3.70 (or later)

* Foursquare UserPush API

* mixi Graph API

***

__This application is still a test version.__

***

### Environment setting by using Config::Pit

~/.pit/default.yaml

    "fsq2mixi":
        "fsq_client_id": 'FOURSQUARE_CONSUMER_KEY'
        "fsq_client_secret": 'FOURSQUARE_CONSUMER_SECRET'
        "fsq_push_secret": 'FOURSQUARE_PUSH_SECRET'
        "mixi_consumer_key": 'MIXI_CONSUMER_KEY'
        "mixi_consumer_secret": 'MIXI_CONSUMER_SECRET'
        "secret": 'COOKIE_SECRET'
        "basepath": '/fsq2mixi'
        "dbpath": 'SQLITE_DATABASE_SAVEPATH'


### Running on Mojo::Server::Hypnotoad
(Mojolicious 3.70)

#### Start:

    hypnotoad /PATHTO_fsq2mixi/script/fsq2mixi -f /PATHTO_fsq2mixi/script/fsq2mixi

#### Setting: (optionally)

/PATHTO_fsq2mixi/fsq2mixi.conf

    {hypnotoad => {listen => ['http://*:80'], workers => 10}};

see detail: http://mojolicio.us/perldoc/Mojo/Server/Hypnotoad#SETTINGS

### License and Author

 Copyright (c) 2012 Masanori Ohgita (http://ohgita.info/).
 This program is free software distributed under the terms of the MIT license.
 See LICENSE.txt for details.



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

## Libraries and Materials
Many thanks :)

### Mojolicious

https://github.com/kraih/mojo

### Data::Model

http://github.com/yappo/p5-Data-Model/

### Bootstrap (Twitter Bootstrap)

https://github.com/twitter/bootstrap

Copyright 2012 Twitter, Inc.

> Apache License 2.0 https://github.com/twitter/bootstrap/blob/master/LICENSE

### jQuery

https://github.com/jquery/jquery

Copyright 2012 jQuery Foundation and other contributors. http://jquery.com/

> MIT License https://github.com/jquery/jquery/blob/master/MIT-LICENSE.txt

### Glyphicons Free

http://glyphicons.com/


> GLYPHICONS FREE are released under the Creative Commons Attribution 3.0 Unported (CC BY 3.0).
	The GLYPHICONS FREE can be used both commercially and for personal use, 
	but you must always add a link to glyphicons.com in a prominent place (e.g. the footer of a website), 
	include the CC-BY license and the reference to glyphicons.com on every page using GLYPHICONS.

### etc...

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



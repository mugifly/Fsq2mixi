Fsq2mixi (4sq2mixi)
========

When you check-in to foursquare, automation-post to mixi.

***

* Perl

* Mojolicious

* Foursquare UserPush API

* mixi Graph API

***

__This application is still a test version.__

***

### Environment-setting by using Config::Pit

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


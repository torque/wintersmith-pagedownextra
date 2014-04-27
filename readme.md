# wintersmith-pagedownextra

[pagedown](https://code.google.com/p/pagedown/) with [extras](https://github.com/jmcmanus/pagedown-extra) plugin for [wintersmith](https://github.com/jnordberg/wintersmith). Desirable for gfm parity with editors such as [stackedit.io](https://stackedit.io/)

I have done bad things.

### install:

    npm install "torque/wintersmith-pagedownextra"

then add `./node_modules/wintersmith-pagedownextra/` to `config.json` like this:

    {
      "locals": {
        "url": "http://localhost:8080",
        "name": "The Wintersmith's blog",
        "owner": "The Wintersmith",
        "description": "-32°C ain't no problems!",
        "index_articles": 3
      },
      "plugins": [
        "./node_modules/wintersmith-pagedownextra/"
      ]
    }

### Per-page extensions: do not exist yet.

# wintersmith-pagedownextra

[pagedown](https://code.google.com/p/pagedown/) with [extras](https://github.com/jmcmanus/pagedown-extra) plugin for [wintersmith](https://github.com/jnordberg/wintersmith). Desirable for gfm parity with editors such as [stackedit.io](https://stackedit.io/)

### install:

```
npm install "torque/wintersmith-pagedownextra"
```

then add `./node_modules/wintersmith-pagedownextra/` to your `config.json`

```json
"plugins": [
  "./node_modules/wintersmith-pagedownextra/"
]
```

If you want to specify the extensions for pagedownExtra to use site-
wide, add something like the following to your `config.json`:

```json
"pagedownextra": {
	"extensions": ["fenced_code_gfm", "tables", "def_list", "attr_list", "footnotes", "smartypants", "strikethrough"]
}
```

The extensions can also be overridden on a per-article basis by using
something like the following in your article's front matter:

```yaml
pagedownextraExtensions: ["fenced_code_gfm", "tables", "def_list", "attr_list", "footnotes", "strikethrough"]
```

async = require 'async'
pagedown = require 'pagedown'
pagedownExtra = require('pagedown-extra').Extra
hljs = require 'highlight.js'
fs = require 'fs'
path = require 'path'
url = require 'url'

# monkey patch in highlighting for fenced code blocks
pagedownExtra.prototype.fencedCodeBlocks = (text) ->
  encodeCode = (code) ->
    # These were escaped by PageDown before postNormalization
    code.replace( /~D/g, "$$" )
      .replace( /~T/g, "~" )

  text = text.replace /(?:^|\n)```[ \t]*(\S*)[ \t]*\n([\s\S]*?)\n```[ \t]*(?=\n)/g, (match, m1, m2) =>
    language = m1
    codeblock = m2;

    # adhere to specified options
    preclass = ''
    codeclass = ''
    if language
      preclass = ' class="language-' + language + ' hljs"'
      codeclass = ' class="language-' + language + '"'
      code = hljs.highlight(language, codeblock).value
    else
      code = encodeCode codeblock

    html = ['<pre', preclass, '><code', codeclass, '>', code, '</code></pre>'].join('');

    # replace codeblock with placeholder until postConversion step
    @hashExtraBlock html

  text

# This is what you get when you attempt to make compressed javascript
# readable with minimal effort. It doesn't work so well. This crock of
# shit comes from stackoverflow by way of benweet/stackedit. It replaces
# blocks deemed to be probably math with @@index@@ so that they don't
# get mutilated during markdown parsing. However, it only looks for $,
# $$, and \begin{env}...\end{env}. I don't feel like screwing with all
# the weird regexy logic right now to add support for \(\) and \[\].
# Even better, $ as a math delimiter doesn't work with MathJax by
# default, on account of it being, y'know, a currency symbol. Super
# cool! I will unfuck this for real at some point in the future. Its
# behavior could/should probably be integrated into pagedown-extra.

g = false
q = false
t = null
s = "$"
k = ""
i = null
o = null
l = null
n = null
m = null
h = null

b = (a, f, b) ->
  c = k.slice( a, f + 1 )
    .join( "" )
    .replace( /&/g, "&amp;" )
    .replace( /</g, "&lt;" )
    .replace( />/g, "&gt;" )

  while f > a
    k[f] = ""
    f--

  k[a] = "@@" + m.length + "@@"
  if b
    c = b(c)

  m.push(c)
  i = o = l = null

p = (a) ->
  i = o = l = null
  m = []
  if /`/.test(a)
    a = a.replace(/~/g, "~T").replace /(^|[^\\])(`+)([^\n]*?[^`\n])\2(?!`)/gm, (a) ->
      a.replace /\$/g, "~D"
    f = (a) ->
      a.replace /~([TD])/g, (a, c) ->
        {T: "~",D: "$"}[c]
  else
    f = (a) ->
      a

  k = a.replace(/\r\n?/g, "\n").split u
  d = k.length
  a = 1
  while a < d
    c = k[a];
    if "@" is c.charAt 0
      k[a] = "@@" + m.length + "@@"
      m.push c
    else
      if i
        if c is o
          if n
            l = a
          else
            b i, a, f
        else
          if c.match(/\n.*\n/)
            if l
              a = l
              b i, a, f
            i = o = l = null
            n = 0
          else
            if "{" is c
              n++
            else
              if "}" is c and n
                n--
      else
        if c is s or "$$" is c
          i = a
          o = c
          n = 0
        else
          if "begin" is c.substr 1, 5
            i = a
            o = "\\end" + c.substr 6
            n = 0
    a+=2
  if l
    b i, l, f

  f k.join ""

d = (a) ->
  a = a.replace /@@(\d+)@@/g, (a, b) -> m[b]
  m = null
  a

u = /(\$\$?|\\(?:begin|end)\{[a-z]*\*?\}|\\[\\{}$]|[{}]|(?:\n\s*)+|@@\d+@@)/i

pagedownRender = ( page, globalOptions, callback ) ->
  # convert the page
  extensions = page.metadata.pagedownextraExtensions or globalOptions.extensions or "all"
  converter = new pagedown.Converter( )
  pagedownExtra.init converter, {extensions: extensions}

  converter.hooks.chain "preConversion", p

  # typogr's smartypants implementation fucks with \\, which causes a
  # problem in some equation environments, such as align. However,
  # pagedownExtra already runs a smartypants pass on the markdown when
  # it is converting it to html. So running typogr as typogr(text).
  # chain().amp().widont().caps().initQuotes().ord().value() adds nice
  # markup and doesn't ruin everything.

  converter.hooks.chain "postConversion", d

  page._html = converter.makeHtml page.markdown
  callback null, page

module.exports = ( env, callback ) ->

  class PagedownPage extends env.plugins.MarkdownPage

    getHtml: ( base = env.config.baseUrl ) ->
      return @_html

  PagedownPage.fromFile = ( filepath, callback ) ->
    async.waterfall [
      (callback) ->
        fs.readFile filepath.full, callback
      (buffer, callback) ->
        PagedownPage.extractMetadata buffer.toString(), callback
      (result, callback) =>
        {markdown, metadata} = result
        page = new this filepath, metadata, markdown
        callback null, page
      (page, callback) =>
        pagedownRender page, env.config.pagedownextra, callback
      (page, callback) =>
        callback null, page
    ], callback

  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', PagedownPage

  callback( )

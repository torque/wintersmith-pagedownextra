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
      .replace( /&/g, "&amp;" )
      .replace( /</g, "&lt;" )
      .replace( />/g, "&gt;" )
      .replace( /~T/g, "~" )

  text = text.replace(/(?:^|\n)```[ \t]*(\S*)[ \t]*\n([\s\S]*?)\n```[ \t]*(?=\n)/g, (match, m1, m2) =>
    language = m1
    codeblock = m2;

    preclass = ''
    codeclass = ''
    if language
      preclass = ' class="language-' + language + ' hljs"'
      codeclass = ' class="language-' + language + '"'
      code = hljs.highlight(language, encodeCode codeblock).value
    else
      code = encodeCode codeblock

    html = ['<pre', preclass, '><code', codeclass, '>', code, '</code></pre>'].join('');

    # replace codeblock with placeholder until postConversion step
    @hashExtraBlock html
  )

  text

pagedownRender = (page, callback) ->
  # convert the page
  # extensions = page.metadata.pagedownExtensions or ['github', 'table', 'math', 'smartypants', 'footnotes']
  converter = new pagedown.Converter()
  pagedownExtra.init(converter)
  page._htmlraw = converter.makeHtml(page.markdown)

  callback null, page

module.exports = (env, callback) ->

  class pagedownPage extends env.plugins.MarkdownPage

    getHtml: (base=env.config.baseUrl) ->
      # TODO: cleaner way to achieve this?
      # http://stackoverflow.com/a/4890350
      name = @getFilename()
      name = name[name.lastIndexOf('/')+1..]
      loc = @getLocation(base)
      fullName = if name is 'index.html' then loc else loc + name
      # handle links to anchors within the page
      @_html = @_htmlraw.replace(/(<(a|img)[^>]+(href|src)=")(#[^"]+)/g, '$1' + fullName + '$4')
      # handle relative links
      @_html = @_html.replace(/(<(a|img)[^>]+(href|src)=")(?!http|\/)([^"]+)/g, '$1' + loc + '$4')
      # handles non-relative links within the site (e.g. /about)
      if base
        @_html = @_html.replace(/(<(a|img)[^>]+(href|src)=")\/([^"]+)/g, '$1' + base + '$4')
      return @_html

    getIntro: (base=env.config.baseUrl) ->
      @_html = @getHtml(base)
      idx = ~@_html.indexOf('<span class="more') or ~@_html.indexOf('<h2') or ~@_html.indexOf('<hr')
      # TODO: simplify!
      if idx
        @_intro = @_html.toString().substr 0, ~idx
        hr_index = @_html.indexOf('<hr')
        footnotes_index = @_html.indexOf('<div class="footnotes">')
        # ignore hr if part of pagedown's footnote section
        if hr_index && ~footnotes_index && !(hr_index < footnotes_index)
          @_intro = @_html
      else
        @_intro = @_html
      return @_intro

    @property 'hasMore', ->
      @_html ?= @getHtml()
      @_intro ?= @getIntro()
      @_hasMore ?= (@_html.length > @_intro.length)
      return @_hasMore

  pagedownPage.fromFile = (filepath, callback) ->
    async.waterfall [
      (callback) ->
        fs.readFile filepath.full, callback
      (buffer, callback) ->
        pagedownPage.extractMetadata buffer.toString(), callback
      (result, callback) =>
        {markdown, metadata} = result
        page = new this filepath, metadata, markdown
        callback null, page
      (page, callback) =>
        pagedownRender page, callback
      (page, callback) =>
        callback null, page
    ], callback

  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', pagedownPage

  callback()

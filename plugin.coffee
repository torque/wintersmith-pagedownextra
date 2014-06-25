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

  text = text.replace /(?:^|\n)```[ \t]*(\S*)[ \t]*\n([\s\S]*?)\n```[ \t]*(?=\n)/g, (match, m1, m2) =>
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

  text

pagedownRender = ( page, globalExtensions, callback ) ->
  # convert the page
  extensions = page.metadata.pagedownExtensions or globalExtensions or "all"
  converter = new pagedown.Converter( )
  pagedownExtra.init converter, {extensions: extensions}


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
        pagedownRender page, env.config.pagedownExtensions, callback
      (page, callback) =>
        callback null, page
    ], callback

  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', PagedownPage

  callback( )

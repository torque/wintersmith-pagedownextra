async = require 'async'
Showdown = require 'showdown'
fs = require 'fs'
path = require 'path'
url = require 'url'

showdownRender = (page, callback) ->
  # convert the page
  extensions = page.metadata.showdownExtensions or ['github', 'table', 'math', 'smartypants', 'footnotes']
  converter = new Showdown.converter(extensions: extensions)
  page._htmlraw = converter.makeHtml(page.markdown)

  callback null, page

module.exports = (env, callback) ->

  class ShowdownPage extends env.plugins.MarkdownPage
    
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
        # ignore hr if part of Showdown's footnote section
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
  
  ShowdownPage.fromFile = (filepath, callback) ->
    async.waterfall [
      (callback) ->
        fs.readFile filepath.full, callback
      (buffer, callback) ->
        ShowdownPage.extractMetadata buffer.toString(), callback
      (result, callback) =>
        {markdown, metadata} = result
        page = new this filepath, metadata, markdown
        callback null, page
      (page, callback) =>
        showdownRender page, callback
      (page, callback) =>
        callback null, page
    ], callback
   
  env.registerContentPlugin 'pages', '**/*.*(markdown|mkd|md)', ShowdownPage

  callback()

define ['jquery', 'backbone', 'underscore', 'app'], ($, Backbone, _, App) ->
  App.Models.Album = Backbone.Model.extend(

    parse: (response) ->
      # A bit of hack to use the same model for both normal album list
      # and album view. In different cases different models are received.
      if (response.songs)
        @songs = _.map(response.songs, (song) ->
                                          return new App.Models.Song(song)
        )
        response.album
      else
        response

    url: ->
      url = "/albums/#{@id}/songs.json"
      url

    type: "Album"
  )

  # Pagination idea taken from:
  # http://weblog.bocoup.com/backbone-live-collections/
  # Currently, we dont let paginate as such. Just keep adding
  # from homepage. Once we have better search, people are just going
  # to use that honestly
  #
  App.Collections.AlbumCollection = Backbone.Collection.extend(
    model: App.Models.Album

    initialize: (models, options) ->
      @offset = 1

    url: ->
      # This could be wrong if the ajax failed and we will have incorrect offset
      # but really this does not need to be foolproof.
      x = "/albums.json?page=#{@offset}"
      @offset += 1
      x

  )

  App.Collections.TrendingAlbumCollection = App.Collections.AlbumCollection.extend(
    initialize: (models, options) ->
      @offset = 1

    url: ->
      # This could be wrong if the ajax failed and we will have incorrect offset
      # but really this does not need to be foolproof.
      x = "/browse/trending.json?page=#{@offset}"
      @offset += 1
      x
    #url: "/browse/trending.json"
  )

  App.Views.AlbumView = Backbone.View.extend(
    manage: true
    template: "#album-row"
    className: "album"
    tagName: "li"

    events:
      "click > .art > .play-button": "playAlbum"
      "click > .details > .album-name > a.name": "showAlbum"
      "click > .details > .label-name > a.name": "showLabel"

    showAlbum: (evt) ->
      evt.preventDefault()
      App.router.navigate('/albums/' + @model.get('slug'), {
            trigger: true
          })

    showLabel: (e) ->
      e.preventDefault()
      App.router.navigate('/labels/' + @model.get('label_slug'), {trigger: true})

    playAlbum: (evt) ->
      album_id = @model.get('id')

      songCollection = new App.Collections.SongCollection([],
        albumId: album_id
      )
      songCollection.fetch().success ->
        App.player.collection.gotoQueueEnd()
        App.player.collection.add(songCollection.models)
        App.player.playFirstValidSong()

    serialize: ->
      @model.toJSON()

  )

  App.Views.AlbumCollectionView = Backbone.View.extend(
    manage: true
    template: "#album-list"
    className: "mainpage-top-list"

    initialize: ->
      _.bindAll @
      @collection.bind('add', @onAdd)
      #when route changes we destroy old event scroll
      @end_scroll = new App.EndScroll(@.showMoreAlbums)

    # Insert all subViews prior to rendering the View.
    beforeRender: ->
      # Iterate over the passed collection and create a view for each item.
      @collection.each ((model) ->
        @insertView("ul.album-list", new App.Views.AlbumView(
          model: new App.Models.Album(model)
        ))
      ), this

    showMoreAlbums: (evt=null) ->
      if evt
        evt.preventDefault()
      count_old = @collection.length
      @collection.fetch({add: true, async:false})
      if @collection.length != count_old
        #if count of albums change; else loading albums don't repeat
        @end_scroll.isLoading = false;

    onAdd: (model) ->
      @insertView("ul.album-list", new App.Views.AlbumView(
        model: new App.Models.Album(model)
      )).render()

    serialize: ->
      #console.log @collection.toJSON()
  )

  App.Views.AlbumCollectionCarouselView = Backbone.View.extend(
    manage: true
    limit: 6
    album_on_page : 3
    className: "carousel slide"
    template: "#album-list-carousel"

    initialize: ->
      _.bindAll @
      #@collection.bind('add', @onAdd)

    #events:
      #"click > .albums-pager": "showMoreAlbums"

    # Insert all subViews prior to rendering the View.
    beforeRender: ->
      # Iterate over the passed collection and create a view for each item.
      count = 0
      @collection.each ((model) ->
        if count < @limit
          if count < @album_on_page
            @insertView(".slide_0 ul.album-list", new App.Views.AlbumView(
              model: new App.Models.Album(model)
            ))
          else
            @insertView(".slide_1 ul.album-list", new App.Views.AlbumView(
              model: new App.Models.Album(model)
            ))
        count += 1
      ), this

    afterRender:->
      #$("#AlbumListCarousel").carousel("next")

    #showMoreAlbums: (evt) ->
      #evt.preventDefault()
      #@collection.fetch({add: true})

    serialize: ->
      ("carousel_id" : @id)

  )

  App.Views.AlbumDetailView = Backbone.View.extend(
    manage: true,
    template: "#album-catalog",
    className: "album-catalog",

    events:
      "click .art > .play-button": "playAlbum"
      "click .label-link": "showLabel"
      "click .artist-link": "showArtist"
      "click .genre-link": "showGenre"
      "click .add": "addToCart"

    addToCart: (e) ->
      e.preventDefault()
      App.cart.add @model

    beforeRender: ->
      songs = new App.Collections.SongCollection(@model.songs)
      @setView('.song-list-container', new App.Views.SongCollectionView(
        collection: songs)
      ) #.render()
      @similar_albums = new App.Collections.SimilarAlbumCollection({},
        'albumId': @model.get('id')
      )
      similar_albums_view = new App.Views.SimilarAlbumsCarouselView(
        collection: @similar_albums,
        'albumId': @model.get('id')
      ) #.render()
      @setView('.similar-albums', similar_albums_view)
      @

    afterRender: ->
      # Load up share icons dynamically
      # http://www.ovaistariq.net/447/how-to-dynamically-create-twitters-tweet-button-and-facebooks-like-button/
      # https://dev.twitter.com/discussions/13184
      twttr.widgets.load()
      @similar_albums.fetch()
      @

    playAlbum: (evt) ->
      # This code is duplicate of AlbumView playAlbum method
      App.player.collection.gotoQueueEnd()
      App.player.collection.add(@model.songs)
      App.player.playFirstValidSong()

    #FIXME: Use MainLayout.navigateToHref style
    showLabel: (e) ->
      e.preventDefault()
      App.router.navigate($(e.target).attr('href'), {trigger: true})

    showArtist: (e) ->
      e.preventDefault()
      App.router.navigate($(e.target).attr('href'), {trigger: true})

    showGenre: (e) ->
      e.preventDefault()
      App.router.navigate($(e.target).attr('href'), {trigger: true})

    serialize: ->
      @model.toJSON()
      #{}
  )

  App.Collections.SimilarAlbumCollection = Backbone.Collection.extend(
    model: App.Models.Album

    initialize: (models, options) ->
      @album_id = options['albumId']

    url: ->
      "/similar_albums/#{@album_id}.json"

    parse: (response) ->
      response.albums

  )

  App.Views.SimilarAlbumsView = App.Views.AlbumCollectionView.extend (

    template: "#similar-album-list",

    initialize: (options) ->
      _.bindAll @
      @albumId = options['albumId']
      @collection.bind('reset', @renderAll)

    # Hack because beforeRender does stuff AlbumCollection page
    beforeRender:
      @

    renderAll: (models) ->
      @collection.each ((model) ->
        if model.id != @albumId
          @insertView("ul.album-list", new App.Views.AlbumView(
            model: new App.Models.Album(model)
          )).render()
      ), this

  )

  App.Views.SimilarAlbumsCarouselView = Backbone.View.extend(
    manage: true
    limit: 6
    album_on_page : 3
    className: "carousel slide span8"
    id : "similaralbumscarouselview"
    template: "#similar-album-list-carousel"

    initialize: (options)->
      _.bindAll @
      @albumId = options['albumId']
      @collection.bind('reset', @renderAll)

    renderAll: (models) ->
      count = 0
      console.log "@collection.length", @collection.length
      if @collection.length > 0 and @collection.length > 3
        @$el.find("a.carousel-control").removeClass("hide")

      if @collection.length <= 3
        @$el.find(".item.slide_1").remove()

      @collection.each ((model) ->
        if count < @limit and model.id != @albumId
          if count < @album_on_page
            @insertView(".slide_0 ul.album-list", new App.Views.AlbumView(
              model: new App.Models.Album(model)
            )).render()
          else
            @insertView(".slide_1 ul.album-list", new App.Views.AlbumView(
              model: new App.Models.Album(model)
            )).render()
          count += 1
      ), this

    serialize: ->
      ("carousel_id" : @id)

  )

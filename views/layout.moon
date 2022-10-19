
import Widget from require "lapis.html"
import to_json from require "lapis.util"

buster = require "cache_buster"

config = require("lapis.config").get!

class Layout extends Widget
  content: =>
    html_5 ->
      head ->
        meta charset: "UTF-8"
        title "Sight Reading Trainer"
        if config._name == "production" or @params.prod_assets
          link rel: "stylesheet", href: "/static/style.min.css?#{buster}"
        else
          link rel: "stylesheet", href: "/static/style.css?#{buster}"

        -- link rel: "stylesheet", href: "https://fonts.googleapis.com/css?family=Raleway"
        link rel: "icon", sizes: "144x144", href: "/static/img/icon-144.png"
        link rel: "manifest", href: @build_url "/static/manifest.json", scheme: config.default_scheme

        meta name: "viewport", content: "width=device-width, initial-scale=1"
        meta id: "csrf_token", name: "csrf_token", content: @csrf_token

        meta_description = "Practice sight reading right with your MIDI keyboard directly in your browser. Customizable note generation to always give you a challenge. Completely free."

        meta property: "og:description", content: meta_description
        meta name: "description", content: meta_description

        @google_analytics!
        meta name: "theme-color", content: "#727290"

      body ->
        div id: "page", ->
          div class: "page_layout", ->
            div class: "header_spacer", ->
              div class: "header", ->
                a class: "logo_link", href: "/", ->
                  img {
                    class: "logo"
                    src: "/static/img/logo.svg"
                    height: 35
                    alt: ""
                  }

                  img {
                    class: "logo_small"
                    src: "/static/img/logo-small.svg"
                    height: 35
                    alt: ""
                  }

        script type: "text/javascript", ->
          raw "window.ST_initial_session = #{to_json @initial_state!}"

        @include_js "main"

  initial_state: =>
    out = { }
    if @current_user
      out.currentUser = @flow("formatter")\user @current_user

    out.cacheBuster = buster

    out

  include_js: (...) =>
    for lib in *{...}
      unless type(lib) == "table"
        lib = {lib, "#{lib}.min"}

      path = if config._name == "production" or @params.prod_assets
        lib[2]
      else
        lib[1]

      script type: "text/javascript", src: "/static/#{path}.js?#{buster}"

  google_analytics: =>
    script type: "text/javascript", ->
      raw [[
        if (window.location.hostname != "localhost") {
          (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
          (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
          m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
          })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

          ga('create', 'UA-136625-15', 'auto');
          ga('send', 'pageview');
        }
      ]]

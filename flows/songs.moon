db = require "lapis.db"

import preload from require "lapis.db.model"

import trim_filter from require "lapis.util"
import assert_valid from require "lapis.validate"
import assert_error from require "lapis.application"

import Songs from require "models"
import Flow from require "lapis.flow"

import types from require "tableshape"

types = require "lapis.validate.types"
shapes = require "helpers.shapes"

arrayify = ((types.equivalent({}) / nil) + types.any)\transform

class SongsFlow extends Flow
  preload_songs: (songs) =>
    preload songs, "user"
    if @current_user and next songs
      import SongUserTime from require "models"
      song_user_times = SongUserTime\select "where user_id = ?", @current_user.id, db.list [s.id for s in *songs]
      by_song_id  = {sut.song_id, sut for sut in *song_user_times}

      for song in *songs
        song.current_user_time = by_song_id[song.id]

    songs

  format_song: (song, for_render=false) =>
    user = song\get_user!

    {
      id: song.id
      url: @url_for "song", song_id: song.id, slug: song\get_slug!
      title: song.title

      song: for_render and song.song or nil

      notes_count: song.notes_count
      beats_duration: song.beats_duration
      publish_status: Songs.publish_statuses\to_name song.publish_status

      current_user_time: if cut = song.current_user_time
        {
          created_at: cut.created_at
          updated_at: cut.updated_at
          time_spent: cut.time_spent
        }

      user_id: song.user_id
      allowed_to_edit: not not song\allowed_to_edit @current_user
      artist: song.artist
      album: song.album
      source: song.source
      created_at: song.created_at
      updated_at: song.updated_at
      user: {
        id: user.id
        name: user\name_for_display!
      }
    }

  list_played_songs: =>
    assert_error @current_user, "not logged in"

    res = db.query "
      select songs.*
        from song_user_time

      inner join songs on songs.id = song_id
      where song_user_time.user_id = ?
      order by updated_at desc
      limit 50
    ", @current_user.id

    songs = for r in *res
      Songs\load r

    @preload_songs songs

    json: {
      success: true
      songs: arrayify [@format_song song for song in *songs]
    }


  list_songs: =>
    pager = Songs\paginated "where publish_status = ?",
      Songs.publish_statuses.public, {
        per_page: 10
        order: "id desc"
        prepare_results: (songs) ->
          @preload_songs songs
          songs
      }

    page = @params.page and tonumber(@params.page) or 0

    my_songs = if @current_user
      Songs\select "where user_id = ? order by updated_at desc", @current_user.id

    if my_songs
      @preload_songs my_songs

    songs = pager\get_page page

    json: {
      success: true
      my_songs: if my_songs
        arrayify [@format_song song for song in *my_songs]

      songs: arrayify [@format_song song for song in *songs]
    }

  find_song: =>
    assert_valid @params, {
      {"song_id", exists: true, is_integer: true}
    }

    song = Songs\find @params.song_id
    assert_error song, "could not find song"
    song

  get_song: =>
    trim_filter @params
    song = @find_song!

    json: {
      success: true
      song: @format_song song, true
    }

  validate_song_params: (create=false) =>
    params = assert_valid @params, types.params_shape {
      {"song", types.params_shape {
        {"title",  types.truncated_text(160)}
        {"song", types.truncated_text(1024*10)}

        {"source", shapes.db_nullable types.truncated_text(250)}
        {"album", shapes.db_nullable types.truncated_text(250)}
        {"artist", shapes.db_nullable types.truncated_text(250)}

        {"has_autochords", types.one_of {
          types.literal("true") / true
          types.any / false
        }}

        {"publish_status", types.db_enum(Songs.publish_statuses)}

        {"notes_count", shapes.db_nullable shapes.integer}
        {"beats_duration", shapes.db_nullable shapes.number}

        create and {"original_song_id", shapes.db_nullable(types.db_id)} or nil
      }}
    }

    params.song


  update_song: =>
    song = @find_song!
    assert_error song\allowed_to_edit(@current_user), "you are not allowed to edit this song"
    update = @validate_song_params!

    diff = shapes.difference update, song
    if next diff
      song\update {k, update[k] for k in pairs diff}

    json: {
      success: true
    }

  delete_song: =>
    song = @find_song!
    assert_error song\allowed_to_edit @current_user
    song\delete!

    json: {
      success: true
      redirect_to: @url_for "play_along"
    }

  create_song: =>
    song_params = @validate_song_params true
    song_params.user_id = @current_user.id
    song = Songs\create song_params

    json: {
      success: true
      song: @format_song song
    }

  update_song_user_time: =>
    song = @find_song!
    import SongUserTime from require "models"
    user_time = SongUserTime\find {
      user_id: @current_user.id
      song_id: song.id
    }

    assert_valid @params, {
      {"time_spent", optional: true, is_integer: true}
    }

    time_spent = tonumber @params.time_spent or 30
    assert_error time_spent <= 30, "Time can only be incremented in 30 second intervals"

    assert_error not user_time or not user_time\just_updated!,
      "time just updated"

    out = SongUserTime\increment {
      user_id: @current_user.id
      song_id: song.id
      time_spent: 30
    }

    json: {
      success: true
      time_spent: out.time_spent
      added: if user_time
        out.time_spent - user_time.time_spent
    }



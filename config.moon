import config from require "lapis.config"

config {"development", "production", "test"}, ->
  app_name "sightreading.training"
  session_name "mursic"

  daemon "off"
  notice_log "stderr"
  port 8081

  postgres {
    database: "sightreading"
  }

config "production", ->
  daemon "on"
  notice_log "logs/notice.log"
  code_cache "on"
  num_workers 3
  port 10007

  default_scheme "https"


config "test", ->
  code_cache "on"

  postgres {
    database: "sightreading_test"
  }

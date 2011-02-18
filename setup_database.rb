#!/usr/env/ruby
#(__FILE__)
require "write_templated_file.rb"

# TODO: Interpolate database credentials
# source the database credentials.
# Expect $CI_DB_NAME, $CI_DB_USER, $CI_DB_PASSWORD

ENV[:PROJECT_DIR]
CI_BRANCH
CI_JOB

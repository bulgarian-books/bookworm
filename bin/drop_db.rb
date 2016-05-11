#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.join(__dir__, '..', 'lib'))

require 'bookworm/settings'

settings = Bookworm::Settings.instance

settings.connection.exec(File.read("#{settings.root}/sql/drop.sql"))

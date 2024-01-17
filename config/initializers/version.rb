
VERSION = `rails version:read`.strip
BUILD   = `rails version:build`.strip
puts "Loading MudClub version #{VERSION} (##{BUILD})"
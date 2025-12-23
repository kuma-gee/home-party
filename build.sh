#!/bin/sh

mkdir -v -p ./build/web
sed -i 's|^run/main_scene=".*"|run/main_scene="res://player-client/player_client.tscn"|' project.godot
godot --export-release --headless web ./build/web/index.html

if [ -z "$1" ]; then
  echo "Build complete. No deployment target specified."
  exit 0
fi

sudo rm /srv/http/home-party -rf
sudo cp ./build/web /srv/http/home-party -r
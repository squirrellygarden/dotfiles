#!/bin/sh

# Restore git configuration
echo "Restoring git files..."
cp git/.gitignore ~/.gitignore
cp git/.gitconfig ~/.gitconfig

echo "Restoring .config..."
cp -r .config/ ~/.config/

echo "Restoring gtk theme..."
cp -r gtk/catppuccin-mocha-mauve-standard ~/.local/share/themes
cp -r gtk/gtk-3.0 ~/.config
cp -r gtk/gtk-4.0 ~/config

echo "Restoring krita scheme..."
cp -r krita/color-schemes/ ~/.local/share/krita


#!/bin/sh

# Restore git configuration
echo "Restoring git files..."
cp git/.gitignore ~/.gitignore
cp git/.gitconfig ~/.gitconfig

echo "Restoring .config..."
cp -r .config/ ~/.config/

echo "Restoring gtk theme..."
cp -r gtk/catppuccin-mocha-mauve-standard ~/.local/share/themes

echo "Restoring krita scheme..."
cp -r krita/color-schemes/ ~/.local/share/krita
#!/bin/sh

# Restore git configuration
echo "Restoring git files..."
mv git/.gitignore ~/.gitignore
mv git/.gitconfig ~/.gitconfig

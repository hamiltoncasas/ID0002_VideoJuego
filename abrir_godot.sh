#!/bin/bash
# Script para abrir Godot Engine en esta máquina
export DISPLAY=:0
cd "$(dirname "$0")/godot_project"
./Godot --path .

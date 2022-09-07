#!/bin/bash
set -e
shopt -s nullglob extglob

trap "echo -e '\033[31mInstall failed.\033[m'" ERR

# Theme will be built in this directory, relative to the repo's root.
dest="MC-Theme"

if [ $EUID -gt 0 ]; then
    install_dest="$HOME/.themes/MC-Theme"
else
    install_dest="/usr/share/themes/MC-Theme"
fi

# Where the script will search for the source textures.
# This is relative to the repo's root.
textures_dir="textures"

# Assets (keys) and their sources (values).
#
# The value syntax is a path (relative to textures/) optionally followed by a
# scale (@ followed by an integer base-10 number, followed by an x).
# ex: block/dirt.png
#     block/grass.png@16x
#
# A scale of N makes the destination asset N times larger than the source asset,
# multiplying its height and by N.
declare -A gtk3_asset_srcs=(
    ["headerbar.png"]="block/grass_block_side.png@5x"
    ["headerbar@2x.png"]="block/grass_block_side.png@10x"
    ["bg.png"]="block/stone.png@8x"
    ["bg@2x.png"]="block/stone.png@16x"
    ["button.png"]="block/oak_planks.png@4x"
    ["checkbutton_off.png"]="block/redstone_torch_off.png@2x"
    ["checkbutton_off@2x.png"]="block/redstone_torch_off.png@4x"
    ["checkbutton_on.png"]="block/redstone_torch.png@2x"
    ["checkbutton_on@2x.png"]="block/redstone_torch.png@4x"
    ["checkbutton_indeterminate.png"]="block/torch.png@2x"
    ["checkbutton_indeterminate@2x.png"]="block/torch.png@4x"
)

# Warn if the texture dir was not found
if [ ! -d "$textures_dir" ]; then
    echo -e "Textures directory not found!\nCopy the textures directory (located in /assets/minecraft/ from inside the game's .jar) to the repo's root and try again."
    exit
fi

# Delete previous build artifacts (not the installed theme)
if [ -d "$dest" ]; then
    rm -rf -- "$dest"
fi
mkdir -- "$dest"

# Generate assets
gtk3_assets_dest="$dest/gtk-3.0/assets"
mkdir -p -- "$gtk3_assets_dest"
for asset in "${!gtk3_asset_srcs[@]}"; do
    asset_rawsrc="$textures_dir/${gtk3_asset_srcs["$asset"]}"

    # Separate source from scale
    asset_src="${asset_rawsrc%@+([[:digit:]])x}"
    asset_scale="${asset_rawsrc#"$asset_src"}"
    asset_scale="${asset_scale:1:-1}"

    # Copy asset to destination, scaling if necessary
    asset_dest="$gtk3_assets_dest/$asset"
    if [[ -n "$asset_scale" ]]; then
        magick "$asset_src" -scale "$asset_scale"00% "$asset_dest"
    else
        cp -- "$asset_src" "$asset_dest"
    fi
done

# Compile Sass
for dir in src/sass/*; do
    styles_dest="$dest/$(basename "$dir")"
    sass --no-source-map -- "$dir:$styles_dest"
done

# Install theme
if [ -d "$install_dest" ]; then
    rm -rf -- "$install_dest"
fi
cp -r -- "$dest" "$install_dest"
echo Theme installed successfully.

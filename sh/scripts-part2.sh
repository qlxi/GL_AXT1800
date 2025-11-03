#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Fix rust build error
[ -e feeds/packages/lang/rust/Makefile ] && sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# Define target directory
TARGET_DIR="$PWD/package"

# Define repositories and branches to clone
declare -A REPOS=(
    ["https://github.com/chenmozhijin/turboacc"]="" # Used by: CONFIG_PACKAGE_luci-app-turboacc=y
    ["https://github.com/qlxi/fancontrol"]="" # Used by: CONFIG_PACKAGE_fancontrol=y
    ["https://github.com/sirpdboy/luci-app-partexp"]="" # Used by: CONFIG_PACKAGE_luci-app-partexp=y
)

# Clone repositories
clone_repo() {
    local repo_url=$1
    local repo_branch=${REPOS[$repo_url]}
    local repo_name=$(basename -s .git "$repo_url")
    local repo_dir="$TARGET_DIR/$repo_name"

    echo "Cloning repository: $repo_name, URL: $repo_url, Branch: $repo_branch"

    if [ -d "$repo_dir" ]; then
        echo "Directory $repo_dir already exists, skipping"
        return
    fi

    if [ -z "$repo_branch" ]; then
        echo "Executing git clone (default branch): git clone --single-branch --depth 1 \"$repo_url\" \"$repo_dir\""
        git clone --single-branch --depth 1 "$repo_url" "$repo_dir"
    else
        echo "Executing git clone (specific branch): git clone --single-branch --depth 1 -b \"$repo_branch\" \"$repo_url\" \"$repo_dir\""
        git clone --single-branch --depth 1 -b "$repo_branch" "$repo_url" "$repo_dir"
    fi

    if [ $? -eq 0 ]; then
        echo "Repository $repo_name cloned successfully"
    else
        echo "Error cloning repository $repo_name"
    fi
}

# Iterate over REPOS array and clone
echo "Starting repository cloning"
for repo in "${!REPOS[@]}"; do
    clone_repo "$repo"
done

echo "Cloning of all repositories finished"
cd $TARGET_DIR/turboacc/luci-app*
if [ "$(ls -la | grep -c "Makefile")" -eq '0' ]; then
    echo "Makefile not found, stopping GitHub Action"
    exit 1
else
    echo "Makefile found, continuing"
fi

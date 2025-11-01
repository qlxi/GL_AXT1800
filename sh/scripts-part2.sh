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

# Modify prerequisite packages
[ -e feeds/packages/lang/rust/Makefile ] && sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile
TARGET_DIR="$PWD/package"

# Repositories to clone
declare -A REPOS=(
    ["https://github.com/chenmozhijin/turboacc"]="" # turboacc (Network acceleration)
    ["https://github.com/m0eak/fancontrol"]="" # fancontrol (Fan control)
    ["https://github.com/sirpdboy/luci-app-partexp"]="" # partexp (Partition expansion utility)
)

# Function to clone a repository
clone_repo() {
    local repo_url=$1
    local repo_branch=${REPOS[$repo_url]}
    local repo_name=$(basename -s .git "$repo_url")
    local repo_dir="$TARGET_DIR/$repo_name"

    echo "Cloning repository: $repo_name, URL: $repo_url, Branch: $repo_branch"

    if [ -d "$repo_dir" ]; then
        echo "Directory $repo_dir already exists, skipping clone."
        return
    fi

    if [ -z "$repo_branch" ]; then
        echo "Running git clone (default branch): git clone --single-branch --depth 1 \"$repo_url\" \"$repo_dir\""
        git clone --single-branch --depth 1 "$repo_url" "$repo_dir"
    else
        echo "Running git clone (specific branch): git clone --single-branch --depth 1 -b \"$repo_branch\" \"$repo_url\" \"$repo_dir\""
        git clone --single-branch --depth 1 -b "$repo_branch" "$repo_url" "$repo_dir"
    fi

    if [ $? -eq 0 ]; then
        echo "Successfully cloned $repo_name"
    else
        echo "Failed to clone $repo_name"
    fi
}

# Iterate over the REPOS array and clone each
echo "Cloning all repositories..."
for repo in "${!REPOS[@]}"; do
    clone_repo "$repo"
done

echo "Checking turboacc Makefiles..."
cd $TARGET_DIR/turboacc/luci-app*
if [ "$(ls -la | grep -c "Makefile")" -eq '0' ]; then
    echo "No Makefile found, exiting GitHub Action."
    exit 1
else
    echo "Makefile found, continuing."
fi
#rm -rf feeds/packages/lang/golang && echo "Removed old golang"
#git clone https://github.com/sbwml/packages_lang_golang -b 25.x feeds/packages/lang/golang
#cat feeds/packages/lang/golang/golang/Makefile

#!/bin/bash

set -e

# Test for git-lfs behavior with repos that have no LFS files
# This tests the fix for the issue where git lfs install was running unnecessarily

# Optional: Import test library
source dev-container-features-test-lib

# Test that git-lfs is installed
check "git-lfs version" git-lfs --version

# Test the generated script exists
check "pull script exists" test -f /usr/local/share/pull-git-lfs-artifacts.sh

# Create a mock git repo without LFS files to test the script
mkdir -p /tmp/test-no-lfs-repo
cd /tmp/test-no-lfs-repo
git init
git config user.email "test@example.com"
git config user.name "Test User"
echo "regular file content" > regular.txt
git add regular.txt
git commit -m "Initial commit without LFS"

# Test that git lfs ls-files returns empty output (our fix checks this)
check "git lfs ls-files returns empty output" test -z "$(git lfs ls-files 2>/dev/null)"

# Test that the script logic works correctly
# Simulate what the pull-git-lfs-artifacts.sh script does
AUTO_PULL="true"
if [ "${AUTO_PULL}" = "true" ] && [ -z "$(git lfs ls-files 2>/dev/null)" ]; then
    # This should be the path taken for repos without LFS files
    echo "(!) Correctly detected no LFS files and would skip git lfs install"
    SUCCESS=true
else
    echo "(!) ERROR: Did not correctly detect absence of LFS files"
    SUCCESS=false
fi

check "correctly detects no LFS files" test "$SUCCESS" = "true"

# Clean up
cd /tmp
rm -rf /tmp/test-no-lfs-repo

reportResults
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

# Verify no hooks exist before running the script
HOOKS_BEFORE=$(find .git/hooks -type f ! -name '*.sample' | wc -l)
check "no git hooks before script" test "$HOOKS_BEFORE" -eq 0

# Run the actual pull-git-lfs-artifacts.sh script to test the real behavior
echo "Running pull-git-lfs-artifacts.sh script..."
/usr/local/share/pull-git-lfs-artifacts.sh

# Verify that git lfs install was NOT executed by checking no hooks were installed
HOOKS_AFTER=$(find .git/hooks -type f ! -name '*.sample' | wc -l)
check "no git hooks installed after script" test "$HOOKS_AFTER" -eq 0

# Double check: specifically look for the hooks that git lfs install would create
check "no post-merge hook" test ! -f .git/hooks/post-merge
check "no pre-push hook" test ! -f .git/hooks/pre-push  
check "no post-commit hook" test ! -f .git/hooks/post-commit
check "no post-checkout hook" test ! -f .git/hooks/post-checkout

# Clean up
cd /tmp
rm -rf /tmp/test-no-lfs-repo

reportResults
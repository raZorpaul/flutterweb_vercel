#!/bin/bash
set -e  # stop on any error

flutter build web

git add .

# Prompt for commit message
echo "Enter commit message: "
read commit_message

# Check if commit_message is empty, if so, abort commit
if [ -z "$commit_message" ]; then
  echo "Aborting commit due to empty commit message."
  exit 1
fi

# Commit with the entered message
git commit -m "$commit_message"

git push

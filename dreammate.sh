#!/bin/bash

function fetch_login {
  if [ ! -f ~/.github_login ];
  then
    echo "File ~/.github_login not present."
    echo "Set it with dreammate me <github_login>"
    exit
  fi

  LOGIN=$(cat ~/.github_login)

  if [ -z $LOGIN ];
  then
    echo "Github login not present!"
    exit 1
  fi

  echo "Using login $LOGIN"
}

function list {
  fetch_login

  gh issue list -a $LOGIN | grep -v review | grep -v doing | cut -d$'\t' -f1,3
}

function start {
  if [ $# -lt 1 ];
  then
    echo "Missing issue number"
    echo "Usage: dreammate start <issue_number>"
    exit 1
  fi

  ISSUE_NUMBER=$1

  fetch_login

  FOUND_ISSUE_NUMBER=$(gh issue list -a $LOGIN | cut -d$'\t' -f1 | grep $ISSUE_NUMBER)

  if [ -z $FOUND_ISSUE_NUMBER ];
  then
    echo "Issue $ISSUE_NUMBER not found"
    exit 1
  fi

  ISSUE_NAME=$(gh issue view $FOUND_ISSUE_NUMBER | head -n1 | cut -d$'\t' -f2 | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
  BRANCH_NAME="$ISSUE_NAME"-#$FOUND_ISSUE_NUMBER

  git checkout -b $BRANCH_NAME
  git status
}

function push {
  fetch_login

  BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

  ISSUE_NUMBER=$(echo $BRANCH_NAME | cut -d# -f2)

  if [ -z $ISSUE_NUMBER ];
  then
    echo "Cannot get issue number from current branch"
    exit 1
  fi

  echo "Creating PR for issue: $ISSUE_NUMBER"

  PR_TITLE=$(gh issue list -a $LOGIN | grep $ISSUE_NUMBER | cut -d$'\t' -f 3)
  PR_BODY="fixes #"$ISSUE_NUMBER

  git push -u origin "$BRANCH_NAME"
  gh pr create -Bdevelopment -b "$PR_BODY" -t"$PR_TITLE"
}

function me {
  GITHUB_LOGIN=$1

  if [ -z "$GITHUB_LOGIN" ];
  then
    echo "Enter you gihub login: "
    read GITHUB_LOGIN
  fi

  echo "Saving $GITHUB_LOGIN as Dreammate login"

  echo $GITHUB_LOGIN > ~/.github_login

  echo "Github login saved to ~/.github_login"
}

function install {
  DREAMMATE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/dreammate.sh"
  DREAMMATE_BIN_PATH="~/.local/bin/dm"

  cp $DREAMMATE_PATH ~/.local/bin/dm

  echo "Dreammate correctly installed in $DREAMMATE_BIN_PATH"
}

function usage {
  echo "Usage: ./dreammate.sh action"

  echo "Possible actions:
    install     Install the script in the ~/local/bin directory
    me          Set the Github login
    list        List all the issues related to the current user
    help        Show this help message
    start       Create a branch based on an issue
    push        Create a PR based on the current issue branch
    version     Print the software version
  "
  exit 1
}

if [ $# -lt 1 ];
then
  echo "Missin action!";
  usage
fi

ACTION=$1

case "$ACTION" in
  help)
    usage
  me)
    me "${@:2}"
    ;;
  start)
    start "${@:2}"
    ;;
  install)
    install
    ;;
  list)
    list
    ;;
  push)
    push
    ;;
  version)
    version
  *)
    echo "Action not recognized"
    exit 1
esac

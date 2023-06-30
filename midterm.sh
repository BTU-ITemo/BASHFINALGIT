#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [[ "${BASH_TRACE:-0}" == "1" ]]; then
    set -o xtrace
fi

if env | grep -q '^GITHUB_PERSONAL_ACCESS_TOKEN='; then
    echo "GITHUB_PERSONAL_ACCESS_TOKEN is set"
else
    echo "GITHUB_PERSONAL_ACCESS_TOKEN is not set"
fi


# Check if all arguments are provided
if [ $# -ne 4 ]; then
  echo "Error: 4 arguments required."
  echo "Usage: ./mid-term.sh CODE_REPO_URL CODE_BRANCH_NAME REPORT_REPO_URL REPORT_BRANCH_NAME"
  exit 1
fi

CODE_REPO_URL="$1"
REPORT_REPO_URL="$3"
REPOSITORY_OWNER=$(basename "$(dirname "$CODE_REPO_URL")")
REPOSITORY_NAME_CODE=$(basename "$CODE_REPO_URL" .git)
REPOSITORY_NAME_REPORT=$(basename "$REPORT_REPO_URL" .git)
REPOSITORY_BRANCH_CODE="$2"
REPOSITORY_BRANCH_REPORT="$4"


# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed"
    exit 1
fi

# Check if pip is installed
if ! command -v pip &> /dev/null; then
    echo "pip is not installed"
    exit 1
fi

# Function to install a package using pip
install_package() {
    package=$1
    if ! python3 -c "import $package" &> /dev/null; then
        echo "$package is not installed, installing..."
        if ! pip install $package; then
            echo "Failed to install $package"
            exit 1
        fi
    else
        echo "$package is already installed"
    fi
}

# Check and install required packages
install_package black
install_package pytest
install_package pytest_html
install_package pygments
install_package jq

echo "All required packages are installed"



cd "$(dirname "$0")"

REPOSITORY_PATH_CODE=$(mktemp --directory)
REPOSITORY_PATH_REPORT=$(mktemp --directory)
PYTEST_REPORT_PATH=$(mktemp)
BLACK_OUTPUT_PATH=$(mktemp)
BLACK_REPORT_PATH=$(mktemp)
PYTEST_RESULT=0
BLACK_RESULT=0


# Function to check if a repository exists
check_repository_exists() {
  local repo_url=$1
  local response=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url")

  if [[ $response -eq 200 ]]; then
    echo "Repository exists: $repo_url"
  else
    echo "Repository does not exist: $repo_url"
    exit 1
  fi
}

# Function to check if a branch exists in a repository
check_branch_exists() {
  local repo_url=$1
  local branch_name=$2
  local response=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url/tree/$branch_name")

  if [[ $response -eq 200 ]]; then
    echo "Branch exists: $repo_url/tree/$branch_name"
  else
    echo "Branch does not exist: $repo_url/tree/$branch_name"
    exit 1
  fi
}


# Check CODE_REPO_URL
check_repository_exists "$CODE_REPO_URL"

# Check CODE_BRANCH_NAME within CODE_REPO_URL
check_branch_exists "$CODE_REPO_URL" "$REPOSITORY_BRANCH_CODE"

# Check REPORT_REPO_URL
check_repository_exists "$REPORT_REPO_URL"

# Check REPORT_BRANCH_NAME within REPORT_REPO_URL
check_branch_exists "$REPORT_REPO_URL" "$REPOSITORY_BRANCH_REPORT"




function github_api_get_request()
{
    curl --request GET \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --output "$2" \
        --silent \
        "$1"
        #--dump-header /dev/stderr \
}

function github_post_request()
{
    curl --request POST \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --header "Content-Type: application/json" \
        --silent \
        --output "$3" \
        --data-binary "@$2" \
        "$1"
        #--dump-header /dev/stderr \
}

function jq_update()
{
    local IO_PATH=$1
    local TEMP_PATH=$(mktemp)
    shift
    cat $IO_PATH | jq "$@" > $TEMP_PATH
    mv $TEMP_PATH $IO_PATH
}

git clone git@github.com:${REPOSITORY_OWNER}/${REPOSITORY_NAME_CODE}.git $REPOSITORY_PATH_CODE
pushd $REPOSITORY_PATH_CODE
git switch $REPOSITORY_BRANCH_CODE
COMMIT_HASH=$(git rev-parse HEAD)
AUTHOR_EMAIL=$(git log -n 1 --format="%ae" HEAD)

if pytest --verbose --html=$PYTEST_REPORT_PATH --self-contained-html
then
    PYTEST_RESULT=$?
    echo "PYTEST SUCCEEDED $PYTEST_RESULT"
else
    PYTEST_RESULT=$?
    echo "PYTEST FAILED $PYTEST_RESULT"
fi

echo "\$PYTEST_RESULT = $PYTEST_RESULT \$BLACK_RESULT=$BLACK_RESULT"

if black --check --diff *.py > $BLACK_OUTPUT_PATH
then
    BLACK_RESULT=$?
    echo "BLACK SUCCEEDED $BLACK_RESULT"
else
    BLACK_RESULT=$?
    echo "BLACK FAILED $BLACK_RESULT"
    cat $BLACK_OUTPUT_PATH | pygmentize -l diff -f html -O full,style=solarized-light -o $BLACK_REPORT_PATH
fi

echo "\$PYTEST_RESULT = $PYTEST_RESULT \$BLACK_RESULT=$BLACK_RESULT"

popd

git clone git@github.com:${REPOSITORY_OWNER}/${REPOSITORY_NAME_REPORT}.git $REPOSITORY_PATH_REPORT

pushd $REPOSITORY_PATH_REPORT

git switch $REPOSITORY_BRANCH_REPORT
REPORT_PATH="${COMMIT_HASH}-$(date +%s)"
mkdir --parents $REPORT_PATH
mv $PYTEST_REPORT_PATH "$REPORT_PATH/pytest.html"
mv $BLACK_REPORT_PATH "$REPORT_PATH/black.html"
git add $REPORT_PATH
git commit -m "$COMMIT_HASH report."
git push

popd

rm -rf $REPOSITORY_PATH_CODE
rm -rf $REPOSITORY_PATH_REPORT
rm -rf $PYTEST_REPORT_PATH
rm -rf $BLACK_REPORT_PATH

if (( ($PYTEST_RESULT != 0) || ($BLACK_RESULT != 0) ))
then
    AUTHOR_USERNAME=""
    # https://docs.github.com/en/rest/search?apiVersion=2022-11-28#search-users
    RESPONSE_PATH=$(mktemp)
    github_api_get_request "https://api.github.com/search/users?q=$AUTHOR_EMAIL" $RESPONSE_PATH

    TOTAL_USER_COUNT=$(cat $RESPONSE_PATH | jq ".total_count")

    if [[ $TOTAL_USER_COUNT == 1 ]]
    then
        USER_JSON=$(cat $RESPONSE_PATH | jq ".items[0]")
        AUTHOR_USERNAME=$(cat $RESPONSE_PATH | jq --raw-output ".items[0].login")
    fi

    REQUEST_PATH=$(mktemp)
    RESPONSE_PATH=$(mktemp)
    echo "{}" > $REQUEST_PATH

    BODY+="Automatically generated message

"

    if (( $PYTEST_RESULT != 0 ))
    then
        if (( $BLACK_RESULT != 0 ))
        then
            TITLE="${COMMIT_HASH::7} failed unit and formatting tests."
            BODY+="${COMMIT_HASH} failed unit and formatting tests.

"
            jq_update $REQUEST_PATH '.labels = ["ci-pytest", "ci-black"]'
        else
            TITLE="${COMMIT_HASH::7} failed unit tests."
            BODY+="${COMMIT_HASH} failed unit tests.

"
            jq_update $REQUEST_PATH '.labels = ["ci-pytest"]'
        fi
    else
        TITLE="${COMMIT_HASH::7} failed formatting test."
        BODY+="${COMMIT_HASH} failed formatting test.
"
        jq_update $REQUEST_PATH '.labels = ["ci-black"]'
    fi

    BODY+="Pytest report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/pytest.html

"
    BODY+="Black report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/black.html

"

    jq_update $REQUEST_PATH --arg title "$TITLE" '.title = $title'
    jq_update $REQUEST_PATH --arg body  "$BODY"  '.body = $body'

    if [[ ! -z $AUTHOR_USERNAME ]]
    then
        jq_update $REQUEST_PATH --arg username "$AUTHOR_USERNAME"  '.assignees = [$username]'
    fi

    # https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28#create-an-issue
    github_post_request "https://api.github.com/repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME_CODE}/issues" $REQUEST_PATH $RESPONSE_PATH
    #cat $RESPONSE_PATH
    cat $RESPONSE_PATH | jq ".html_url"
    rm $RESPONSE_PATH
    rm $REQUEST_PATH
else
    echo "EVERYTHING OK, BYE!"
fi

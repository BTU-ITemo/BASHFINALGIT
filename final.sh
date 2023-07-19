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
if [ $# -ne 5 ]; then
  echo "Error: 5 arguments required."
  echo "Usage: ./final.sh CODE_REPO_URL DEV_BRANCH_NAME RELEASE_BRANCH_NAME HTML_REPO_URL HTML_BRANCH_NAME"
  echo "Example:"
  echo "./final.sh git@github.com:BTU-ITemo/midterm-code2.git develop release git@github.com:BTU-ITemo/BASH_FINAL_GIT_TEST.git main"
  exit 1
fi

CODE_REPO_URL="$1"
echo 'CODE_REPO_URL="'$1'"'
DEV_BRANCH_NAME="$2"
echo 'DEV_BRANCH_NAME="'$2'"'
RELEASE_BRANCH_NAME="$3"
echo 'RELEASE_BRANCH_NAME="'$3'"'
HTML_REPO_URL="$4"
echo 'HTML_REPO_URL="'$4'"'
HTML_BRANCH_NAME="$5"
echo 'HTML_BRANCH_NAME="'$5'"'




# Check if Python is installed
# if ! command -v python &> /dev/null; then
#     echo "Python is not installed"
#     exit 1
# fi

# # Check if pip is installed
# if ! command -v pip &> /dev/null; then
#     echo "pip is not installed"
#     exit 1
# fi

# Function to install a package using pip
# install_package() {
#     package=$1
#     if ! python3 -c "import $package" &> /dev/null; then
#         echo "$package is not installed, installing..."
#         if ! pip install $package; then
#             echo "Failed to install $package"
#             exit 1
#         fi
#     else
#         echo "$package is already installed"
#     fi
# }

# # # Check and install required packages
# # install_package black
# # install_package pytest
# # install_package pytest_html
# # install_package pygments
# # install_package jq

# echo "All required packages are installed"



cd "$(dirname "$0")"

REPOSITORY_PATH_CODE=$(mktemp --directory)
REPOSITORY_PATH_REPORT=$(mktemp --directory)
PYTEST_REPORT_PATH=$(mktemp)
BLACK_OUTPUT_PATH=$(mktemp)
BLACK_REPORT_PATH=$(mktemp)
PYTEST_RESULT=0
BLACK_RESULT=0


# Function to check if a repository exists
# check_repository_exists() {
#   local repo_url=$1
#   local response=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url")

#   if [[ $response -eq 200 ]]; then
#     echo "Repository exists: $repo_url"
#   else
#     echo "Repository does not exist: $repo_url"
#     exit 1
#   fi
# }

# # Function to check if a branch exists in a repository
# check_branch_exists() {
#   local repo_url=$1
#   local branch_name=$2
#   local response=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url/tree/$branch_name")

#   if [[ $response -eq 200 ]]; then
#     echo "Branch exists: $repo_url/tree/$branch_name"
#   else
#     echo "Branch does not exist: $repo_url/tree/$branch_name"
#     exit 1
#   fi
# }


# Check CODE_REPO_URL
# check_repository_exists "$CODE_REPO_URL"

# # Check CODE_BRANCH_NAME within CODE_REPO_URL
# check_branch_exists "$CODE_REPO_URL" "$REPOSITORY_BRANCH_CODE"

# # Check REPORT_REPO_URL
# check_repository_exists "$REPORT_REPO_URL"

# # Check REPORT_BRANCH_NAME within REPORT_REPO_URL
# check_branch_exists "$REPORT_REPO_URL" "$REPOSITORY_BRANCH_REPORT"




# function github_api_get_request()
# {
#     curl --request GET \
#         --header "Accept: application/vnd.github+json" \
#         --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
#         --header "X-GitHub-Api-Version: 2022-11-28" \
#         --output "$2" \
#         --silent \
#         "$1"
#         #--dump-header /dev/stderr \
# }

# function github_post_request()
# {
#     curl --request POST \
#         --header "Accept: application/vnd.github+json" \
#         --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
#         --header "X-GitHub-Api-Version: 2022-11-28" \
#         --header "Content-Type: application/json" \
#         --silent \
#         --output "$3" \
#         --data-binary "@$2" \
#         "$1" | tee /dev/tty > /dev/null
#         #--dump-header /dev/stderr \
# }

# function jq_update()
# {
#     local IO_PATH=$1
#     local TEMP_PATH=$(mktemp)
#     shift
#     cat $IO_PATH | jq "$@" > $TEMP_PATH
#     mv $TEMP_PATH $IO_PATH
# }


# # Function to run pytest for a given commit
# run_pytest() {
#     local commit_hash=$1

#     # Checkout the commit
#     git checkout $commit_hash

#     # Run pytest and generate HTML report
#     if pytest --verbose --html=$PYTEST_REPORT_PATH --self-contained-html; then
#         PYTEST_RESULT=$?
#         echo "PYTEST SUCCEEDED $PYTEST_RESULT"
#     else
#         PYTEST_RESULT=$?
#         echo "PYTEST FAILED $PYTEST_RESULT"
#        # cat $PYTEST_REPORT_PATH | pygmentize -l html -f console256 -O style=solarized-light
#     fi


#     # Return pytest result
#     return $PYTEST_RESULT
# }

# # Function to run black for a given commit
# run_black() {
#     local commit_hash=$1

#     # Checkout the commit
#     git checkout $commit_hash

#     # Run black and generate HTML report
#     if black --check --diff *.py > $BLACK_OUTPUT_PATH; then
#         BLACK_RESULT=$?
#         echo "BLACK SUCCEEDED $BLACK_RESULT"
#     else
#         BLACK_RESULT=$?
#         echo "BLACK FAILED $BLACK_RESULT"
#         cat $BLACK_OUTPUT_PATH | pygmentize -l diff -f html -O full,style=solarized-light -o $BLACK_REPORT_PATH
#     fi
#     #echo "$BLACK_REPORT_PATH"
#     # Return black result
#     return $BLACK_RESULT
# }


# # Function to upload pytest and black reports to GitHub Pages
# upload_report_to_github_pages() {
#     local revision=$1

#     git clone git@github.com:${REPOSITORY_OWNER}/${REPOSITORY_NAME_REPORT}.git $REPOSITORY_PATH_REPORT

#     pushd $REPOSITORY_PATH_REPORT

#     git switch $REPOSITORY_BRANCH_REPORT
#     REPORT_PATH="${revision}-$(date +%s)"
#     mkdir -p $REPORT_PATH
#     mv $PYTEST_REPORT_PATH "$REPORT_PATH/pytest.html"
#     mv $BLACK_REPORT_PATH "$REPORT_PATH/black.html"
#     git add $REPORT_PATH
#     git commit -m "${revision} report."
#     git push

#     popd

#     rm -rf $REPOSITORY_PATH_REPORT
#     rm -rf $PYTEST_REPORT_PATH
#     rm -rf $BLACK_REPORT_PATH
# }

# # Function to create a GitHub issue for a failed commit
# create_github_issue() {
#     local revision=$1
#     local pytest_result=$2
#     local black_result=$3
#     local author_username=$4

#     # Prepare the issue title and body based on the test results
#     local title=""
#     local body="Automatically generated message"

#     if ((pytest_result != 0)) && ((black_result != 0)); then
#         title="${revision::7} failed unit and formatting tests."
#         body+="${revision} failed unit and formatting tests."
#         labels=("ci-pytest" "ci-black")
#     elif ((pytest_result != 0)); then
#         title="${revision::7} failed unit tests."
#         body+="${revision} failed unit tests."
#         labels=("ci-pytest")
#     else
#         title="${revision::7} failed formatting test."
#         body+="${revision} failed formatting test."
#         labels=("ci-black")
#     fi

#     # Add links to the pytest and black reports
#     local report_url="https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/${revision}/"
#     body+="Pytest report: ${report_url}pytest.html"
#     body+="Black report: ${report_url}black.html"

#     # Prepare the JSON payload for creating the GitHub issue
#     local request_path=$(mktemp)
#     local response_path=$(mktemp)
#     echo "{}" > $request_path

#     jq_update $request_path --arg title "$title" '.title = $title'
#     jq_update $request_path --arg body "$body" '.body = $body'
#     jq_update $request_path --argjson labels "$labels" '.labels = $labels'
#     jq_update $request_path --arg username "$author_username" '.assignees = [$username]'

#     # Create the GitHub issue
#     github_post_request "https://api.github.com/repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME_CODE}/issues" $request_path $response_path
#     cat $response_path | jq ".html_url"

#     rm $response_path
#     rm $request_path
# }


# get_github_username() {
#     local email=$1
#     local response=$(curl -s -H "Authorization: token $GITHUB_PERSONAL_ACCESS_TOKEN" \
#         "https://api.github.com/search/users?q=$email+in:email")

#     local username=$(echo "$response" | jq -r '.items[0].login')
#     echo "$username"
# }




git clone $CODE_REPO_URL $REPOSITORY_PATH_CODE
pushd $REPOSITORY_PATH_CODE
git switch $DEV_BRANCH_NAME


while true; do
    # Fetch latest changes from the code repository
    git fetch origin

    # Get the commit hash of the last processed revision
    last_commit_hash=$(git rev-parse HEAD)

    # Get the list of new revisions
    revisions=$(git rev-list $last_commit_hash..origin/$DEV_BRANCH_NAME --reverse)

    # Print the list of revisions
    echo "$revisions"

#     for revision in $revisions; do
#         # Run pytest for the revision
#         run_pytest $revision
#         pytest_result=$?

#         # Run black for the revision
#         run_black $revision
#         black_result=$?

#         if ((pytest_result != 0)) || ((black_result != 0)); then
#                     # Upload pytest and black reports to GitHub pages
#                     upload_report_to_github_pages "$revision"


#                     # Get the author email of the failed commit
#                     author_email=$(git log -n 1 --format="%ae" "$revision")
#                     echo "author email $author_email"
#                     AUTHOR_EMAIL=$author_email
#                     AUTHOR_USERNAME=""
#                     echo "username - $AUTHOR_USERNAME"
                    
#                     author_username=$(get_github_username "$author_email")
#                     echo "$author_username"
#                     COMMIT_HASH=$revision

#                     # Make API request to search for users
#                     RESPONSE_PATH=$(mktemp)
#                     github_api_get_request "https://api.github.com/search/users?q=$AUTHOR_EMAIL" "$RESPONSE_PATH"

#                     TOTAL_USER_COUNT=$(jq -r '.total_count' "$RESPONSE_PATH")

#                     if [[ $TOTAL_USER_COUNT == 1 ]]; then
#                         USER_JSON=$(jq '.items[0]' "$RESPONSE_PATH")
#                         AUTHOR_USERNAME=$(jq -r '.items[0].login' "$RESPONSE_PATH")
#                     fi

#                     echo "username gamotvili - $AUTHOR_USERNAME"

#                     #AUTHOR_USERNAME=$author_username

#                     echo "username statikur - $AUTHOR_USERNAME"

#                     REQUEST_PATH=$(mktemp)
#                     RESPONSE_PATH=$(mktemp)
#                     echo "{}" > "$REQUEST_PATH"

#                     BODY+="Automatically generated message"

#                     if ((pytest_result != 0)); then
#                         if ((black_result != 0)); then
#                             TITLE="${COMMIT_HASH::7} failed unit and formatting tests.
#         "
#                             BODY+="${COMMIT_HASH} failed unit and formatting tests
#         "
#                             jq_update "$REQUEST_PATH" '.labels = ["ci-pytest", "ci-black"]'
#                         else
#                             TITLE="${COMMIT_HASH::7} failed unit tests.
#         "
#                             BODY+="${COMMIT_HASH} failed unit tests
#         "
#                             jq_update "$REQUEST_PATH" '.labels = ["ci-pytest"]'
#                         fi
#                     else
#                         TITLE="${COMMIT_HASH::7} failed formatting test."
#                         BODY+="${COMMIT_HASH} failed formatting test"
#                         jq_update "$REQUEST_PATH" '.labels = ["ci-black"]'
#                     fi

#                     BODY+="Pytest report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/pytest.html
#         "
#                     BODY+="Black report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/black.html
#         "

#                     jq_update "$REQUEST_PATH" --arg title "$TITLE" '.title = $title'
#                     jq_update "$REQUEST_PATH" --arg body "$BODY" '.body = $body'

#                     if [[ ! -z $AUTHOR_USERNAME ]]; then
#                         jq_update "$REQUEST_PATH" --arg username "$AUTHOR_USERNAME" '.assignees = [$username]'
#                     fi

#                     echo "aqane"
#                     echo "$REQUEST_PATH"
#                     echo "$AUTHOR_USERNAME"
#                     echo "$RESPONSE_PATH"
#                     echo "!!!!!!!!!!!!!"

#                     github_post_request "https://api.github.com/repos/${REPOSITORY_OWNER}/${REPOSITORY_NAME_CODE}/issues" "$REQUEST_PATH" "$RESPONSE_PATH"
#                     cat "$RESPONSE_PATH" | jq -r '.html_url'

#                     rm "$RESPONSE_PATH"
#                     rm "$REQUEST_PATH"
             

#             # # Find the author's GitHub username
#             # author_username=$(get_github_username $author_email)

#             # # Create a GitHub issue with detailed description of the failure
#             # create_github_issue $revision $pytest_result $black_result $author_username

#         else
#                     # All checks passed
#                     echo "aqane vart8"
#                     # Mark the commit with a "${CODE_BRANCH_NAME}-ci-success" tag
#                     git tag --force "${REPOSITORY_BRANCH_CODE}-ci-success" $revision
#                     git push --force --tags
#         fi
    done

            # Sleep for 15 seconds before checking for new revisions again
            sleep 15
done

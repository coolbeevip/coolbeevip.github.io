---
title: "Batch Deleting GitHub Actions Records with a Bash Script"
date: 2024-08-04T13:24:14+08:00
tags: [github]
categories: [gh, actions]
draft: false
---

As automation becomes an integral part of the development process, GitHub Actions has become an essential component for managing CI/CD workflows in many projects. However, over time, you might accumulate a large number of workflow run records, which can not only take up storage space but also potentially impact performance. In such cases, periodically cleaning up these records becomes crucial. Today, we'll demonstrate how to batch delete GitHub Actions records using a simple Bash script.

## Prerequisites

Before we begin, ensure that you meet the following requirements:

1. **Install `gh` CLI**: Make sure you have the GitHub Command Line Interface (`gh`) installed. You can find installation instructions on the [GitHub CLI website](https://cli.github.com/).
2. **Install `jq`**: This tool is used for processing JSON data. You can install it using the following commands:
    - On macOS: `brew install jq`
    - On Ubuntu: `sudo apt-get install jq`
3. **Generate a GitHub Personal Access Token**: You'll need a GitHub Personal Access Token with the appropriate permissions. Visit the [GitHub Settings](https://github.com/settings/tokens) page to generate one, ensuring that you select the `repo` scope.
4. **Set the Environment Variable**: To keep things secure, we will store the access token in the environment variable `GPA_TOKEN`.

## Script Implementation

Here's our example Bash script, named `delete_github_actions.sh`:

```bash
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Read Github personal access tokens from environment variable
if [[ -z "$GPA_TOKEN" ]]; then
    echo "Error: GPA_TOKEN environment variable is not set."
    exit 1
fi

# Set the repository information
REPO="your_github_username/your_repository_name"  # Replace with your repository information

# Fetch the databaseId list
echo "Fetching GitHub Actions run IDs..."
RUN_IDS=$(gh run list --limit 100 --json databaseId | jq -r '.[].databaseId')

# Check if there are any runs to delete
if [[ -z "$RUN_IDS" ]]; then
    echo "No GitHub Actions runs found."
    exit 0
fi

# Loop through and delete each run
echo "$RUN_IDS" | while read -r RUN_ID; do
    echo "Deleting run ID: $RUN_ID..."
    curl -X DELETE -H "Authorization: token $GPA_TOKEN" \
         "https://api.github.com/repos/$REPO/actions/runs/$RUN_ID" \
         -s
    
    if [[ $? -eq 0 ]]; then
        echo "Successfully deleted run ID: $RUN_ID."
    else
        echo "Failed to delete run ID: $RUN_ID."
    fi
done

echo "All specified GitHub Actions runs have been processed."
```

### How to Execute the Script

1. Copy the script code into a text editor and save it as `delete_github_actions.sh`.
2. Make the script executable with the following command:
   ```bash
   chmod +x delete_github_actions.sh
   ```
3. Set the `$GPA_TOKEN` environment variable in your terminal:
   ```bash
   export GPA_TOKEN="your_personal_access_token"
   ```
4. Run the script:
   ```bash
   ./delete_github_actions.sh
   ```

## Conclusion

With this script, you can easily batch delete unnecessary GitHub Actions records. However, please be cautious—this operation is irreversible! Regularly cleaning up workflow run records will help maintain a tidy and efficient GitHub repository.

I hope you find this script helpful! If you have any questions or need further assistance, feel free to reach out.
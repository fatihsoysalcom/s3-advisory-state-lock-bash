#!/bin/bash

# This script demonstrates an advisory locking mechanism for Terraform state
# stored in S3, without relying on DynamoDB. It uses S3 objects as a simple
# lock file to prevent concurrent operations.

# --- Configuration ---
# IMPORTANT: Replace 'your-terraform-state-bucket' with an actual S3 bucket name
# where your Terraform state would typically be stored.
S3_BUCKET="your-terraform-state-bucket"
LOCK_KEY="terraform-state/lock.advisory" # The S3 key for the lock object
LOCK_CONTENT="locked_by_$$" # Unique content for this process (PID) to identify its lock
LOCK_TIMEOUT_SECONDS=300 # How long to wait for a lock (e.g., 5 minutes)
POLL_INTERVAL_SECONDS=5 # How often to check for the lock

# --- Helper Functions ---

# Function to acquire the advisory lock using an S3 object.
# This is an advisory lock, meaning processes must cooperate to respect it.
acquire_lock() {
    echo "Attempting to acquire advisory lock: s3://${S3_BUCKET}/${LOCK_KEY}"
    local start_time=$(date +%s)

    while true; do
        # Check if the lock object already exists in S3
        if aws s3api head-object --bucket "${S3_BUCKET}" --key "${LOCK_KEY}" &>/dev/null; then
            echo "Lock already exists. Waiting for ${POLL_INTERVAL_SECONDS} seconds..."
            sleep "${POLL_INTERVAL_SECONDS}"
        else
            # Try to create the lock object. The content identifies the locker.
            if aws s3api put-object --bucket "${S3_BUCKET}" --key "${LOCK_KEY}" --body <(echo "${LOCK_CONTENT}") --content-type "text/plain" &>/dev/null; then
                echo "Advisory lock acquired successfully."
                return 0 # Success
            else
                echo "Failed to create lock object. Retrying..."
                sleep "${POLL_INTERVAL_SECONDS}"
            fi
        fi

        local current_time=$(date +%s)
        if (( current_time - start_time > LOCK_TIMEOUT_SECONDS )); then
            echo "Error: Timed out waiting to acquire lock."
            return 1 # Failure
        fi
    done
}

# Function to release the advisory lock.
# It verifies the lock content to ensure only the process that acquired it can release it.
release_lock() {
    echo "Releasing advisory lock: s3://${S3_BUCKET}/${LOCK_KEY}"
    # Retrieve the content of the lock object to verify ownership
    local current_lock_content=$(aws s3api get-object --bucket "${S3_BUCKET}" --key "${LOCK_KEY}" --query 'Body' --output text 2>/dev/null)
    if [[ "$current_lock_content" == "$LOCK_CONTENT" ]]; then
        # If the content matches, delete the lock object
        if aws s3api delete-object --bucket "${S3_BUCKET}" --key "${LOCK_KEY}" &>/dev/null; then
            echo "Advisory lock released."
            return 0
        else
            echo "Error: Failed to delete lock object. Manual intervention may be required."
            return 1
        fi
    else
        echo "Warning: Lock object content mismatch or lock not found. Not releasing."
        echo "Another process might have acquired/released the lock, or it was manually removed."
        return 1
    fi
}

# --- Main Script Logic ---

# Ensure AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed or not in PATH."
    echo "Please install and configure AWS CLI (e.g., 'aws configure')."
    exit 1
fi

# Ensure the specified S3 bucket exists and is accessible
if ! aws s3api head-bucket --bucket "${S3_BUCKET}" &>/dev/null; then
    echo "Error: S3 bucket '${S3_BUCKET}' does not exist or you don't have access."
    echo "Please create the bucket or update the S3_BUCKET variable in the script."
    exit 1
fi

# Use a trap to ensure the lock is released even if the script exits unexpectedly
trap release_lock EXIT

# Attempt to acquire the lock
if ! acquire_lock; then
    echo "Could not acquire lock. Exiting."
    exit 1
fi

echo "\n--- Simulating a critical Terraform operation (e.g., 'terraform apply') ---"
echo "Performing critical work for 15 seconds..."
sleep 15 # Simulate a long-running Terraform operation
echo "Critical work finished."

# The 'trap release_lock EXIT' command will automatically call release_lock
# when the script exits, ensuring the lock is cleaned up.

echo "\nScript finished successfully."
exit 0

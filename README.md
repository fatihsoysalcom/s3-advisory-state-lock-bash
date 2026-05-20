# s3-advisory-state-lock-bash
This example demonstrates an advisory locking mechanism for Terraform state stored in S3, without relying on DynamoDB. It uses S3 objects as a simple lock file to prevent concurrent operations, simulating how teams might coordinate when a dedicated locking service is unavailable. The script attempts to acquire a lock, simulates a long-running Terra

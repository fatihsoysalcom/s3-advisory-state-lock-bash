# S3 Advisory State Lock Bash

This example demonstrates an advisory locking mechanism for Terraform state stored in S3, without relying on DynamoDB. It uses S3 objects as a simple lock file to prevent concurrent operations, simulating how teams might coordinate when a dedicated locking service is unavailable. The script attempts to acquire a lock, simulates a long-running Terraform task, and then releases the lock.

## Language

`bash`

## How to Run

1. Ensure AWS CLI is installed and configured with credentials (e.g., `aws configure`).
2. Replace `your-terraform-state-bucket` with an actual S3 bucket name in the `lock_s3_state.sh` script.
3. Run the script: `bash lock_s3_state.sh`
4. To observe the locking mechanism, open another terminal and try to run the script concurrently while the first instance is running.

## Original Article

This example accompanies the Turkish article: [Terraform Durum Kilitleme Mekanizmalarını Anlamak: S3 Üzerinde DynamoDB Olmadan Güvenli Yönetim](https://fatihsoysal.com/blog/terraform-durum-kilitleme-mekanizmalarini-anlamak-s3-uzerinde-dynamodb-olmadan-guvenli-yonetim/).

## License

MIT — see [LICENSE](LICENSE).

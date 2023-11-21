#!/bin/bash

# Parameter Storeからキーペアの秘密鍵を取得
PARAMETER_ID="key-XXXXXXXXXXXXX"
OUTPUT_FILE="ec2_secret_key.pem"
KEY_PREFIX="/ec2/keypair"
OUTPUT_DIR="${HOME}/Develop/aws/secret"

# AWS CLIを使用して秘密鍵を取得し、ファイルに書き込む
aws ssm get-parameter --name $KEY_PREFIX/$PARAMETER_ID --with-decryption --query "Parameter.Value" --output text >$OUTPUT_DIR/$OUTPUT_FILE

# ファイルの権限を設定（chmod 600）
chmod 600 $OUTPUT_DIR/$OUTPUT_FILE

echo finish

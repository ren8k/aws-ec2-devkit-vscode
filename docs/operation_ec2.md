# EC2 インスタンスの運用

Cloud9 などで開発する場合，自動シャットダウン機能がデフォルトで提供されているため，インスタンスの消し忘れを防ぐことができる．しかし，VSCode Remote Development を利用して EC2 で開発する場合，自動シャットダウン機能が提供されていないため，消し忘れが発生しやすい．そこで，Lambda と EventBridge を利用し，夜 12 時に全ての EC2 インスタンスを停止させるように運用している.また，特定のインスタンスは停止の対象外にできるようにしている．

## 実行コード

`./ops_ec2/lambda_function.py`を夜 12 時に定期実行している．コードでは，指定のリージョンのインスタンスを全て停止させている．

## 工夫点

環境変数`EXCLUDED_INSTANCE_IDS`に特定のインスタンスは停止の対象外にできるように工夫している．

```python
# ./ops_ec2/lambda_function.py
import boto3
import os

# env_var-> EXCLUDED_INSTANCE_IDS: <instanceid, instanceid, ...>
excluded_instance_ids = os.environ['EXCLUDED_INSTANCE_IDS'].split(',')
region = 'ap-northeast-1'

def lambda_handler(event, context):
    ec2 = boto3.client('ec2', region_name=region)

    # Describe EC2 Instances
    instances = ec2.describe_instances()

    # Check the EC2 Instances ID and State
    for reservation in instances['Reservations']:
        for instance in reservation['Instances']:
            if instance['InstanceId'] not in excluded_instance_ids and instance['State']['Name'] == 'running':
                # Stop EC2 Instances that not equal to instance_id_excluded and in running state
                ec2.stop_instances(InstanceIds=[instance['InstanceId']])
                print('Stopping instance: ', instance['InstanceId'])

    return 'Complete stopping instances except ' + ', '.join(excluded_instance_ids)

```

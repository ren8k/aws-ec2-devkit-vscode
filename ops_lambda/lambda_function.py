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

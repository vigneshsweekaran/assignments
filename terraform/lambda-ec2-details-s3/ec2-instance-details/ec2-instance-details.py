import boto3
import csv
import datetime
import os
from botocore.exceptions import ClientError
import logging
import json

bucket_name = os.environ['BUCKET_NAME']
sns_topic_arn = os.environ['SNS_TOPIC_ARN']

required_tags = ["Data", "Processing", "Web"]
header = ['Id', 'Name', 'State', 'Type', 'Image-id']
data = []

date_time = datetime.datetime.now()
unique_no = date_time.strftime("%y%m%d%H%M%S")
file_name = "ec2-instances-"+unique_no+".csv"
file_path = "/tmp/"+file_name

def ec2_instance_details(event, context):
    
    ec2_resource = boto3.resource('ec2')
    
    for instance in ec2_resource.instances.all():
        id    = instance.instance_id
        state = instance.state["Name"]
        type = instance.instance_type
        image = instance.image.id
        for tag in instance.tags:
            if tag['Key'] == "Name":
                name  = tag['Value']
            if tag['Key'] == "Service":
                service_tag = tag['Value']
            else:
                service_tag = None
        if state == "running" and service_tag == None and service_tag not in required_tags:
            data.append([id,name,state,type,image])
    if data:
      create_csv_file(data)
      publish_to_s3()
      notify_sns()

def create_csv_file(data):
    with open(file_path, 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f)
        # write the header
        writer.writerow(header)
        # write multiple rows
        writer.writerows(data)

def publish_to_s3():
    s3 = boto3.client('s3')
    try:
        response = s3.upload_file(file_path, bucket_name, file_name)
    except ClientError as e:
        logging.error(e)
        
def notify_sns():
    client = boto3.client('sns')
    response = client.publish (
       TargetArn = sns_topic_arn,
       Message = json.dumps({'default': "Some EC2 Instances are not having service tag or dosen't match of Data, Processin or Web"}),
       MessageStructure = 'json'
    )
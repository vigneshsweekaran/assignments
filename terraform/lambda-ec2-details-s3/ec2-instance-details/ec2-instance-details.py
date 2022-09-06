import boto3
import csv

header = ['Name', 'Type', 'Image-id']
data = []

def ec2_instance_details(event, context):
    
    ec2_resource = boto3.resource('ec2')
    for instance in ec2_resource.instances.all():
        state = instance.state["Name"]
        type = instance.instance_type
        image = instance.image
        print(f"Instance State : {state}, Instance Type : {type}, Instance Image : {image}")

def craete_csv_file(data):
    with open('ec2-instances.csv', 'w', encoding='UTF8', newline='') as f:
        writer = csv.writer(f)
        # write the header
        writer.writerow(header)
        # write multiple rows
        writer.writerows(data)
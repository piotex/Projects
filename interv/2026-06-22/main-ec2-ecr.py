

a = 0
print("hello")
b = 0
c = 243




# import boto3
#
#
# def get_ami(region: str):
#     ssm = boto3.client('ssm', region_name=region)
#     parameter = ssm.get_parameter(
#         Name="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
#     )
#     ami = parameter["Parameter"]["Value"]
#     return ami
#
# ami = get_ami('eu-central-1')
#
#
#
#
#
#
# region = "eu-central-1"
#
#
#
#
#
#
#
# ec2 = boto3.client("ec2", region_name=region)
#
# response = ec2.run_instances(
#     ImageId=ami,
#     InstanceType="t3.micro",
#     MinCount=1,
#     MaxCount=1,
#     KeyName="my-key",
#     SecurityGroupIds=[
#         "sg-123456"
#     ],
#     TagSpecifications=[
#         {
#             "ResourceType": "instance",
#             "Tags": [
#                 {
#                     "Key": "Name",
#                     "Value": "python-app"
#                 }
#             ]
#         }
#     ]
# )
#
# instance_id = response["Instances"][0]["InstanceId"]
#
# print(instance_id)
#
# instances = ec2.describe_instances()
#
# for reservation in instances["Reservations"]:
#     for instance in reservation["Instances"]:
#         print(
#             instance["InstanceId"],
#             instance["State"]["Name"]
#         )
#
#
#
# # === ecr
#
#
# import boto3
#
# ecr = boto3.client(
#     "ecr",
#     region_name="eu-central-1"
# )
#
# response = ecr.create_repository(
#     repositoryName="python-app"
# )
#
# print(
#     response[
#         "repository"
#     ][
#         "repositoryUri"
#     ]
# )
#
#
# # aws ecr get-login-password \
# # | docker login \
# # --username AWS \
# # --password-stdin \
# # 123456.dkr.ecr.eu-central-1.amazonaws.com
#
# # docker build -t app .
#
# # docker tag \
# # app \
# # 123456.dkr.ecr.eu-central-1.amazonaws.com/app
#
# # docker push \
# # 123456.dkr.ecr.eu-central-1.amazonaws.com/app
#
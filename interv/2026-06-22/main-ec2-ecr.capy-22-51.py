import boto3

import boto3


def delete_resources(vpc_id: str, region: str):
    ec2 = boto3.client("ec2", region_name=region)

    # 1. Znajdź instancję w podanym VPC
    instances = ec2.describe_instances(
        Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}]
    )
    instance_ids = []
    for res in instances['Reservations']:
        for inst in res['Instances']:
            instance_ids.append(inst['InstanceId'])

    # 2. Usuń instancje
    if instance_ids:
        print(f"Zatrzymywanie instancji: {instance_ids}")
        ec2.terminate_instances(InstanceIds=instance_ids)
        waiter = ec2.get_waiter('instance_terminated')
        waiter.wait(InstanceIds=instance_ids)

    # 3. Usuń podsieci
    subnets = ec2.describe_subnets(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for subnet in subnets['Subnets']:
        ec2.delete_subnet(SubnetId=subnet['SubnetId'])

    # 4. Usuń tablice routingu (z wyjątkiem głównej)
    rts = ec2.describe_route_tables(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for rt in rts['RouteTables']:
        # Nie można usunąć głównej tablicy routingu (Main)
        if not any(assoc.get('Main', False) for assoc in rt['Associations']):
            ec2.delete_route_table(RouteTableId=rt['RouteTableId'])

    # 5. Odłącz i usuń Internet Gateway
    igws = ec2.describe_internet_gateways(Filters=[{'Name': 'attachment.vpc-id', 'Values': [vpc_id]}])
    for igw in igws['InternetGateways']:
        ec2.detach_internet_gateway(InternetGatewayId=igw['InternetGatewayId'], VpcId=vpc_id)
        ec2.delete_internet_gateway(InternetGatewayId=igw['InternetGatewayId'])

    # 6. Usuń Security Groups (z wyjątkiem domyślnej)
    sgs = ec2.describe_security_groups(Filters=[{'Name': 'vpc-id', 'Values': [vpc_id]}])
    for sg in sgs['SecurityGroups']:
        if sg['GroupName'] != 'default':
            ec2.delete_security_group(GroupId=sg['GroupId'])

    # 7. Usuń VPC
    ec2.delete_vpc(VpcId=vpc_id)
    print(f"VPC {vpc_id} oraz wszystkie powiązane zasoby zostały usunięte.")


# Użycie:
delete_resources('vpc-0e2ad6f17a384f1e8', 'eu-central-1')


a = 5







AWS_REGION = 'eu-central-1'

def get_ami(region: str):
    ssm = boto3.client('ssm', region_name=region)
    parameter = ssm.get_parameter(
        Name="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
    )
    ami = parameter["Parameter"]["Value"]
    return ami

def create_ec2_instance(ami: str, region: str):
    ec2 = boto3.client("ec2", region_name=region)

    vpc = ec2.create_vpc(CidrBlock='10.0.0.0/16')
    vpc_id = vpc['Vpc']['VpcId']

    subnet = ec2.create_subnet(VpcId=vpc_id, CidrBlock='10.0.1.0/24')
    subnet_id = subnet['Subnet']['SubnetId']

    igw = ec2.create_internet_gateway()
    igw_id = igw['InternetGateway']['InternetGatewayId']
    ec2.attach_internet_gateway(InternetGatewayId=igw_id, VpcId=vpc_id)

    rt = ec2.create_route_table(VpcId=vpc_id)
    rt_id = rt['RouteTable']['RouteTableId']

    ec2.create_route(
        RouteTableId=rt_id,
        DestinationCidrBlock='0.0.0.0/0',
        GatewayId=igw_id
    )

    ec2.associate_route_table(SubnetId=subnet_id, RouteTableId=rt_id)

    sg = ec2.create_security_group(
        GroupName='web-server-sg',
        Description='SG z dostepem do portow 22, 80, 5000, 8080',
        VpcId=vpc_id
    )
    sg_id = sg['GroupId']

    ec2.authorize_security_group_ingress(
        GroupId=sg_id,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': port,
                'ToPort': port,
                'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
            }
            for port in [22, 80, 5000, 8080]
        ]
    )

    response = ec2.run_instances(
        ImageId=ami,
        InstanceType="t3.micro",
        MinCount=1,
        MaxCount=1,
        KeyName="lab-key",
        NetworkInterfaces=[{
            'SubnetId': subnet_id,
            'DeviceIndex': 0,
            'AssociatePublicIpAddress': True,
            'Groups': [sg_id]
        }],
        TagSpecifications=[{
            "ResourceType": "instance",
            "Tags": [{"Key": "Name", "Value": "python-app"}]
        }]
    )

    instance_id = response['Instances'][0]['InstanceId']

    # Czekamy aż instancja będzie działać
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[instance_id])

    # Pobieramy szczegóły instancji
    desc = ec2.describe_instances(InstanceIds=[instance_id])
    public_ip = desc['Reservations'][0]['Instances'][0].get('PublicIpAddress')

    return public_ip





def main():
    ami = get_ami(AWS_REGION)
    public_ip = create_ec2_instance(ami, AWS_REGION)
    print(public_ip)

    a = 0


if __name__ == "__main__":
    main()




#
#
#
#
#

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
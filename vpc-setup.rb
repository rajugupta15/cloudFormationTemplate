SparkleFormation.new(:test, :provider => :aws) do
  AWSTemplateFormatVersion '2010-09-09'
  description 'Plivo Vpc With one private subnet and one public subnet'
  parameters do
    amiId do
      type 'String'
      default 'ami-6e165d0e'
      description 'Enter WME AMI ID.'
    end
    instanceType do
      type 'String'
      default 't2.micro'
      allowedValues  ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge']
      description 'Enter t2 family Instance type. Default is t2.small.'
    end
    vpcCidr do
      type 'String'
      default '10.94.0.0/16'
      allowedPattern '(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})/(\\d{1,2})'
      description 'Enter VPC Cidr block.'
    end
    dnsSupport do
      type 'String'
      default 'False'
      allowedValues ["True", "False"]
      description 'Enter True if you want DNS support.'
    end
    dnsHostName do
      type 'String'
      default 'False'
      allowedValues ["True", "False"]
      description 'Enter True if you want DNS hostname to instance'
    end
    publicSubnetcidr do
      type 'String'
      default '10.94.24.0/22'
      allowedPattern '(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})/(\\d{1,2})'
      description 'Enter VPC public subnet cidr.'
    end
    privateSubnetcidr do
      type 'String'
      default '10.94.12.0/22'
      allowedPattern '(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})\\.(\\d{1,2})/(\\d{1,2})'
      description 'Enter VPC private subnet cidr.'
    end
    publicInstanceZone do
      type 'String'
      default 'us-west-1c'
      allowedValues ["us-west-1a", "us-west-1b", "us-west-1c"]
      description 'Enter public instance AvailabilityZone.'
    end
    privateInstanceZone do
      type 'String'
      default 'us-west-1a'
      allowedValues ["us-west-1a", "us-west-1b", "us-west-1c"]
      description 'Enter private instance availabilityZone.'
    end
    publicIP do
      type 'String'
      default '10.94.24.10'
      allowedPattern '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,2})\\.(\\d{1,2})'
      description 'Enter Public ip.'
    end
    privateIP do
      type 'String'
      default '10.94.12.10'
      allowedPattern '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,2})\\.(\\d{1,2})'
      description 'Enter Private ip.'
    end
    sshKeyPair do
      type 'String'
      default 'Plivo-Raju'
      description 'key pair.'
    end
  end
  resources do
    myVpc do
      type 'AWS::EC2::VPC'
      properties do
        cidrBlock ref!(:vpcCidr)
        enableDnsSupport ref!(:dnsSupport)
        enableDnsHostnames ref!(:dnsHostName)
        instanceTenancy 'default'
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestVPC'
          })
      end
    end
    internateGateway do
      type 'AWS::EC2::InternetGateway'
      properties do
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestInternateGateway'
          })
      end  
    end
    attachGateway do
      type 'AWS::EC2::VPCGatewayAttachment'
      dependsOn myVpc
      properties do
        vpcId ref!(:myVpc)
        internetGatewayId ref!(:internateGateway)
      end
    end
    nat do
      type 'AWS::EC2::NatGateway'
      dependsOn  publicSubnet eip
      properties do
        allocationId  attr!(:eip,'AllocationId')
        subnetId ref!(:publicSubnet)
      end
    end
    publicSubnet do
      type 'AWS::EC2::Subnet'
      dependsOn myVpc
      properties do
        vpcId ref!(:myVpc)
        cidrBlock ref!(:publicSubnetcidr)
        availabilityZone ref!(:publicInstanceZone)
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestPublicSubnet'
          })
      end
    end
    eip do
      type 'AWS::EC2::EIP'
      properties do
        domain 'vpc'
      end
    end
    privateSubnet do
      type 'AWS::EC2::Subnet'
      dependsOn  eip publicSubnet
      properties do
        vpcId ref!(:myVpc)
        cidrBlock ref!(:privateSubnetcidr)
        availabilityZone ref!(:privateInstanceZone)
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestPrivateSubnet'
          })
      end
    end
    publicRouteTable do
      type 'AWS::EC2::RouteTable'
      dependsOn myVpc
      properties do
        vpcId ref!(:myVpc)
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestPublicRouteTable'
          })
      end
    end
    privateRouteTable do
      type 'AWS::EC2::RouteTable'
      dependsOn myVpc
      properties do
        vpcId ref!(:myVpc)
        tags _array(
          -> {
            key 'Name'
            value 'PlivoTestPrivateRouteTable'
          })
      end
    end
    publicRoute do
      type 'AWS::EC2::Route'
      dependsOn publicRouteTable internateGateway
      properties do
        routeTableId ref!(:publicRouteTable)
        destinationCidrBlock '0.0.0.0/0'
        gatewayId ref!(:internateGateway)
      end
    end
    privateRoute do
      type 'AWS::EC2::Route'
      dependsOn privateRouteTable nat
      properties do
        routeTableId ref!(:privateRouteTable)
        destinationCidrBlock '0.0.0.0/0'
        natGatewayId ref!(:nat)
      end
    end
    priSubnetRouteTableAssociation do
      type 'AWS::EC2::SubnetRouteTableAssociation'
      dependsOn privateSubnet privateRouteTable
      properties do
        subnetId ref!(:privateSubnet)
        routeTableId ref!(:privateRouteTable)
      end
    end
    pubSubnetRouteTableAssociation do
      type 'AWS::EC2::SubnetRouteTableAssociation'
      dependsOn publicSubnet publicRouteTable
      properties do
        subnetId ref!(:publicSubnet)
        routeTableId ref!(:publicRouteTable)
      end
    end
    testSG do
      type 'AWS::EC2::SecurityGroup'
      dependsOn myVpc
      properties do
        groupDescription 'Security Group'
        vpcId ref!(:myVpc)
    	tags _array(
          -> {
            key 'Name'
            value 'PlivoTestSG'
          })
      end
    end
    testSGingress do
      type 'AWS::EC2::SecurityGroupIngress'
      properties do
        group_id ref!(:testSG)
        ip_protocol 'tcp'
        from_port 1
        to_port '65535'
        cidr_ip '0.0.0.0/0'
      end
    end
    publicInstance do
      type 'AWS::EC2::Instance'
      dependsOn myVpc testSG publicSubnet privateSubnet
      properties do
        instanceType ref!(:instanceType)
        imageId ref!(:amiId)
        keyName ref!(:sshKeyPair)
        sourceDestCheck 'true'
        networkInterfaces _array(
          -> {
            associatePublicIpAddress 'true'
            privateIpAddress ref!(:publicIP)
            deleteOnTermination 'true'
            deviceIndex '0'
            subnetId ref!(:publicSubnet)
            groupSet [ref!(:testSG)]
          })
        tags _array(
          -> {
            key 'Name'
            value 'Plivo-public-subnet-instance'
          })
      end
    end
    privateInstance do
      type 'AWS::EC2::Instance'
      dependsOn myVpc testSG publicSubnet privateSubnet
      properties do
        instanceType ref!(:instanceType)
        imageId ref!(:amiId)
        keyName ref!(:sshKeyPair)
        sourceDestCheck 'true'
        networkInterfaces _array(
          -> {
            privateIpAddress ref!(:privateIP)
            deleteOnTermination 'true'
            deviceIndex '0'
            subnetId ref!(:privateSubnet)
            groupSet [ref!(:testSG)]
          })
        tags _array(
          -> {
            key 'Name'
            value 'Plivo-private-subnet-instance-01'
          })
      end
    end
  end
  outputs do
    publicInstanceDnsName do
      description 'Public Instance DNS Name'
      value attr!(:publicInstance, :PublicDnsName)
    end
    publicInstancePrivateIP do
      description 'Public Instance private IP'
      value attr!(:publicInstance, :PrivateIp)
    end
    privateInstancePrivateIP do
      description 'private Instance private IP'
      value attr!(:privateInstance, :PrivateIp)
    end
    publicInstanceAvailabilityZone do
      description 'Public Instance Availability Zone'
      value attr!(:publicInstance, :AvailabilityZone)
    end
    privateInstanceAvailabilityZone do
      description 'private Instance Availability Zone'
      value attr!(:privateInstance, :AvailabilityZone)
    end
  end
end

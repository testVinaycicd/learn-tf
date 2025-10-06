1.eks cluster
endpoint_private_access = true
endpoint_public_access = false
subset private in at least 2 AZS

2.managed node groups with 3 permissions

3.Security groups
    1.cluster sg: inbound tpc 443 from ec2 instance (host)
    2.node sg rules for kubelet (10250),node-to-node (all),nodes-to-api (443)

4.Transit Gateway
    1.attach default vpc and eks vpc or in general all the vpcs u want to communicate with withing the same region
    2.Routes
        Default vpc RTs -> 10.0.0.0/16 via TGW
        eks private RTs -> 172.3.0.0./16 via TGW

steps
    first u create a transit gateway 
    attach vpcs(here 2) to the transit gateway
    default vpc route to eks cidr on every RT
    eks vpc to default vpc cidr on each private subnets rt(because we want to connect t0 private instance that are present in eks)
    (In the default VPC, every route table used by any subnet must know “to reach 10.0.0.0/16, send traffic to TGW”.
    In the EKS VPC, every route table used by your private subnets must know “to reach 172.31.0.0/16, send traffic to TGW”.)

    cluster sg ingress rule (ec2 -> api 443)( add this rules in host ec2 sg )
    create route 53 resolver end points and rules
        1) create ingress resolver for eks think as dns receiver create ingress resolver with 2 private subnets with the help of dns_inbound.id we allow dns traffic from other VPCS
        2) create outbound resolver for default vpc or from any other vpc u want to access eks with its subnet
        3) create a forwarding rule saying if anyone hits “When someone in the default VPC asks for anything under us-east-2.eks.amazonaws.com, send that DNS question to the inbound resolver in the EKS VPC.”
        4) attach this rule to VPC
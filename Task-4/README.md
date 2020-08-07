<b>Task-4</b> :
Perform task-3 with an additional feature to be added that is NAT Gateway to provide the internet access to instances running in the private subnet.

Performing the following steps:
1.  Write an Infrastructure as code using terraform, which automatically creates a VPC.
2.  In that VPC we have to create 2 subnets:
    1.   public  subnet [ Accessible for Public World! ] 
    2.   private subnet [ Restricted for Public World! ]
3. Create a public facing internet gateway to connect our VPC/Network to the internet world and attach this gateway to our VPC.
4. Create  a routing table for Internet gateway so that instance can connect to outside world, update and associate it with public subnet.
5.  Create a NAT gateway for connect our VPC/Network to the internet world  and attach this gateway to our VPC in the public network
6.  Update the routing table of the private subnet, so that to access the internet it uses the nat gateway created in the public subnet
7.  Launch an ec2 instance which has Wordpress setup already having the security group allowing  port 80 so that our client can connect to our wordpress site. Also attach the key to instance for further login into it.
8.  Launch an ec2 instance which has a MYSQL setup already with a security group allowing  port 3306 in a private subnet so that our wordpress vm can connect with the same. Also attach the key with the same.

Note: Wordpress instances have to be part of a public subnet so that our client can connect to our site. 
mysql instance has to be part of a private  subnet so that the outside world can't connect to it.
Don't forgot to add auto ip assign and auto dns name assignment option to be enabled.

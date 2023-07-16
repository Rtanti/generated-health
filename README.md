# Generated Health
## Getting Started - Prerequisites
You can run the script `start.sh` to creathe the ssh key needed for the bastion host. We assume you are using an Ubuntu OS as it will use apt to install terraform and aws cli.

In the `variables.tf` it is important to change the values of what you need, such as the region, whitelisted_IPs, and the group your access user
belongs to. Also, uncomment the list of users that need to be created for the cloudwatch dashboard.

Once that is done you can build the infrastructure in your own AWS account. Please note that you need to give your user the needed
permissions. For simplicity's sake I gave my user Full Access to the EC2, S3, CloudWatch, IAM, and SNS( I know it is not the best way, but I had very little time to work with so apologies for that.)

The instance's IP will be printed in the end with the necessary command to connect.
### Monitoring and Logging
I couldn't get the cloudwatch dashboards to work properly with terraform unfortunately. This was for both the data usage and connections. 
I did test out a couple of different patterns for the log metric filter which worked correctly in the test, but I couldn't get data to actually
be sent to the stream.

Alerting of files added to the s3 bucket are sent to the emails of the users in the variable `users`. Also logging of changes to the s3 bucket
where files are stored (bucket-files) are also logged on to (bucket-logs).

### EC2
The EC2 instance comes up and gets aws-cli installed on it so one can immediately start using the S3 buckets. The list of IPs that can access it
are in the `whitleisted_ips` variable.tf

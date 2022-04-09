# Serverless Link Resolver
This is a Terraform provisioning system for the basis of a serverless link resolver written in python.

In this demonstration, two lambda functions are created. The first populates a DynamoDB with a single link resolver entry for the DOI 10.1080/10436928.2020.1709713. The second resolves DOIs into URLs and redirects a web client to the endpoint. 

## Details
Provisioning is via Terraform.

    terraform init
    terraform apply
    terraform destroy

### Web Gateway
The lambda functions are wired to a gateway so that you can trigger them via the web. Once you have run "terraform apply" you will be given a base URL. Use "terraform show" to ascertain the arn of the put-doi and resolve-doi commands. 

Then visit (for example):

    https://1asi8afxqc.execute-api.us-east-1.amazonaws.com/doi/arn:aws:lambda:us-east-1:659226691704:function:put-doi

then with the querystring:

    https://1asi8afxqc.execute-api.us-east-1.amazonaws.com/doi/arn:aws:lambda:us-east-1:659226691704:function:resolve-doi?doi=10.1080/10436928.2020.1709713

Note that these function addresses aren't real/won't work. You need to use the addresses provided by your setup/provisioning.

&copy; Martin Paul Eve 2022
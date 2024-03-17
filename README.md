# Terraform modules and scripts

This repository provides some modules to ease deployments of various resources. It is divided into 2 sections:
* [modules](./modules "modules"): Terraform modules that can be used to deploy various resources
* [deployments](./deployments "deployments"): Terraform scripts that use the modules to deploy a full stack

Each deployment has an associated README file with instructions on how to deploy it, and with additional information about the resources that are being deployed.

## Full mongo serverless atlas deployment with data-api
The provided Terraform modules enable a full MongoDB Atlas deployment, encompassing a range of configurations aimed at optimizing the integration between AWS and MongoDB Atlas. Key features include:

- **MongoDB Atlas CloudFormation Custom Resources**: Automate the creation of database users and roles using MongoDB Atlas CloudFormation custom resources.
- **Developer Access Configuration**: Set up IP whitelisting for developers access, including the automatic configuration of NAT Gateway IPs for the Data API IP whitelist.
- **Private Endpoint Connectivity**: Establish private endpoints between AWS and MongoDB Atlas to allow backend Lambda functions to access the database securely without traversing the public internet.
- **IP Whitelisting for Data API**: Although private connectivity for app services was not available at the time of deployment, this setup includes IP whitelisting as a secure alternative.
- **Alerts and Monitoring**: Configure comprehensive alerts, including pricing alerts, to be delivered to a designated email address. The setup supports adjustments for notifications through Slack and other channels.
- **Data API Configuration**: Includes full configuration of the Data API, with JWT authentication and filtering mechanisms for tenant separation.

Run and deploy it [here](./deployments/mongodb_atlas)

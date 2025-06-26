# Basic Example: CloudWatch Alarms to Slack

This example demonstrates the minimal usage of the `terraform-aws-cw-alarms-to-slack` module. It provisions the required AWS resources to send CloudWatch alarm notifications to a Slack channel using a Lambda function.

## Files
- `main.tf`: Terraform configuration for the example.
- `alarms.json`: Example CloudWatch alarm configuration file.

## Usage
To run this example:

```bash
terraform init
terraform plan
terraform apply
```

> **Note:** This example may create resources which cost money. Run `terraform destroy` when you don't need these resources.

## Requirements
| Name      | Version |
|-----------|---------|
| terraform | >= 1.0  |
| aws       | >= 4.0  |

## What this example creates
- An SNS topic for alarm notifications
- A Lambda function to forward alerts to Slack
- A sample CloudWatch alarm (from `alarms.json`)
- All required IAM roles and permissions

## Inputs
All values are pre-configured in the `main.tf` and `alarms.json` files for this example. See the module's documentation for all available variables.

## Outputs
See the module's documentation for available outputs.

---

*This example is maintained by Senora.dev.* 
[toc]
#### [Click on this link to visit repo](https://github.com/bejarane/c-assesment)

# Flow description
Based on build, push and run methodology, this Docker + Terraform project helps to deploy a Python based Flask application into AWS Elastic Container Service (ECS) consuming images pushed on AWS Elastic Container Registry (ECR). 

Briefly explained, the first step is to create the basic infrastructure for ECR. After this, a Docker image is built. Once the image is pushed into registry, the ECS underlying infrastructure is created and endpoint connection tested.

# Steps
## Pre-requisites
The following requirements must be fulfilled before deploying this application:
1. An IAM credential must be generated for Terraform and Docker to create required resources and push images. Credentials should not be stored on local files. This example uses environment variables at run-time and are never stored:
```
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```
2. A Docker and Terraform ready environment. Check guides to [install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) or [install Docker (Docker Desktop is recommended)](https://docs.docker.com/get-docker/) as needed.
3. An AWS S3 resource is required to store the terraform state description files as these are not being stored on local machine for credential security.

## Pre-build
The following steps will create the AWS ECR resources required to store our Docker image:
1. cd into `pre-deploy` terraform project (`cd terraform/pre-deploy`) and run command `terrafom init` to initialize providers. Note: AWS providers is set to fixed version as latest version (4.56.0) is currently failing to deploy.
2. Run `terraform apply` to generate new infrastructure. ECR name and region can be set in the `variables.tf` file. 
3. The terraform manifest will create an ECR repository and an ECR security policy to grant push access. Images are flagged as *immutable* to [comply with security](https://docs.bridgecrew.io/docs/bc_aws_general_24).
4. With this, the ECR resources should be generated and ready to store new images.

## Docker build
Provided Python Flask project already comes with a valid Docker file that can be run to build the image. It is important to note that Python image selected has multiple critital and high risk vulnerabilities identified. It is recommended to increase base image version or target latest version. Source is not modified and it is consumed *as-is* from original repository.

Steps to build our docker image:
1. Authenticate Docker against AWS by asking for an ECR token key (most secure). `aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <aws_account_id>.dkr.ecr.<region>.amazonaws.com`. The region and AWS account id values will be required.
2. cd back to project main folder and clone [python-api](https://github.com/mransbro/python-api) project with command `git clone https://github.com/mransbro/python-api`. A new folder called `python-api` will be created.
3. Build the docker image with command `docker build --name python-api .`. This will create a new image called `python-api` following the manifest in provided `Dockerfile`.
4. Run vulnerability scan on image using free service Snyk: `docker scan --file Dockerfile --accept-license python-api`. The `--exclude-base` option can be set to bypass scanning base image. [Grype](https://github.com/anchore/grype) can also be used to scan images.
5. Update docker image name to meet AWS requirements. Name should be the same as ECR name: 
`docker tag python-api:latest <aws_account_id>.dkr.ecr.$region.amazonaws.com/<registry_name>:<image_id>`
5. Publish to AWS ECR with command `docker push <aws_account_id>.dkr.ecr.<region>.amazonaws.com/<registry_name>:<image_id>`
6. New image should be now available on ECR.

## Post-build
Having now the AWS Elastic Container Registry ready, the next step is to crate the AWS Elastic Container Service resource and all its networking and permissions dependencies. To do so:
1. cd to `terraform/post-build` folder and run command `terrafom init` to initialize providers. Note: AWS providers is set to fixed version as latest version (4.56.0) is currently failing to deploy.
2. Run `terraform apply` to generate new infrastructure. The following main resources will be created:
    - The ECS resource, its tasks and service to run container listening on `port 5000`. Including health checks based on *python3* commands to test container port listening and application availability. (*python3* is used as *curl* or *wget* are not included on provided image).
    - Two EC2 subnets, security groups, target groups and load balancer listeners on `port 80`.
    - An Application Load Balancer (ALB) that will help to expose the containerized application for public access.
3. Once completed, the load balancer URL will be printed to allow testing. Now the deployment is completed.

## Post-deploy testing
A simple cURL test can be run from local devices to test application availability. Consider new containers take time for initialization. Container is deployed with internal auto health check.

# Infrastructure diagram
As infrasctructre is deployed on a two-step process to avoid usage of provisioners and maintan Terraform scope to infrastrcutre-related tasks only, following will be found two different graphs to ilustrate Terraform project architecture.

## AWS Elastic Container Registry
![ECR](./img/cer-diagram.png)

## AWS Elastic Container Service
![ECS](./img/ces-diagram.png)

## Explore project
It is highly recommended to analyze deployment structure by means of a dynamic graphical tool as [Rover](https://github.com/im2nguyen/rover). This can be easily achieved by running command `docker run --rm -it -p 8080:9000 -v $(pwd):/src --env-file <env_AWS_credentials_file> im2nguyen/rover -tfVar region=<region> -tfVar registry-name=<registry_name>`

# Scripts
Two scripts are provided that assist to deploy and destroy the infrastructure. These can be found under the root directory, `deploy_docker_flask.sh` and `destroy_docker_flask.sh`

Scripts require variables to configure resources correcly, recommended commands are:
- Deploy
```
./deploy_docker_flask.sh -r <region> -a <account>
```

- Destroy
```
./destroy_docker_flask.sh -r <region> -a <account>
```
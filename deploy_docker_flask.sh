#! /bin/bash
set -e
MAIN_DIR=$PWD;
echo "############## Arguments #############";
while getopts a:r: flag
do
    case "${flag}" in
        a) account=${OPTARG};;
        r) region=${OPTARG};;
    esac
done
echo "$region"
echo "$account"

echo "############## Start terrafrom prebuild #############";
cd $MAIN_DIR/terraform/prebuild
terraform init && terraform apply --auto-approve
echo "############## AWS sign-in #############";
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $account.dkr.ecr.$region.amazonaws.com
echo "############## Docker build and push #############"
cd $MAIN_DIR
rm -r -f ./python-api
git clone https://github.com/mransbro/python-api
cd $MAIN_DIR/python-api
docker build -t python-api .
TAG=$(docker images -q python-api:latest)
docker tag python-api:latest $account.dkr.ecr.$region.amazonaws.com/docker-repo:$TAG
docker push $account.dkr.ecr.$region.amazonaws.com/docker-repo:$TAG

docker image remove python-api:latest
docker image remove $account.dkr.ecr.$region.amazonaws.com/docker-repo:$TAG

cd $MAIN_DIR
rm -r -f ./python-api
echo "############## Start terraform post build #############";
cd $MAIN_DIR/terraform/postbuild
terraform init && terraform apply --auto-approve -var image_version=$TAG

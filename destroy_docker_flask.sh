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

echo "############## Destroy all #############";
cd $MAIN_DIR/terraform/postbuild
terraform destroy --auto-approve

cd $MAIN_DIR/terraform/prebuild
terraform destroy --auto-approve

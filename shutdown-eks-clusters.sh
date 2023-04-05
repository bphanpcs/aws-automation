#!/bin/bash

#This script is written for the purpose of maintaing cost in my AWS lab setup for short-term testing only
#Do not use it in production as you might accidentally shutdown clusters unintentionally
#Author: Binh Phan

# Set the AWS profile to use
export AWS_PROFILE="myprofile"

# Check if AWS CLI and eksctl are installed
if ! command -v aws &> /dev/null || ! command -v eksctl &> /dev/null; then
    echo "ERROR: AWS CLI and/or eksctl are not installed. Please install them and try again."
    exit 1
fi

# Login to AWS account using pre-configured credentials
echo "Logging in to AWS account..."
aws sts get-caller-identity

# Get a list of all AWS regions
echo "Getting the list of AWS regions..."
regions=$(aws ec2 describe-regions --query 'Regions[].RegionName' --output text)

# Initialize an empty string for storing cluster information
clusters=""

# Iterate through all regions and get a list of EKS clusters in each region
for region in $regions; do
    echo "Checking for EKS clusters in region: $region"
    regional_clusters=$(aws eks list-clusters --region "$region" --query 'clusters' --output text)

    if [ -n "$regional_clusters" ]; then
        clusters="$clusters $regional_clusters"
        for cluster in $regional_clusters; do
            echo "Found EKS cluster: $cluster in region: $region"
        done
    fi
done

if [ -z "$clusters" ]; then
    echo "No EKS clusters found in your AWS account."
    exit 0
fi

# Shutdown all EKS clusters
echo "Shutting down EKS clusters..."
for region in $regions; do
    regional_clusters=$(aws eks list-clusters --region "$region" --query 'clusters' --output text)
    for cluster in $regional_clusters; do
        echo "Deleting EKS cluster: $cluster in region: $region"
        eksctl delete cluster --name "$cluster" --region "$region" --wait
    done
done

echo "All EKS clusters have been shut down."

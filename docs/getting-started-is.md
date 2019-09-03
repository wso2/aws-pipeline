## Getting Started with AWS Pipeline for WSO2 Identity and Access Management

Setting up a basic pipeline for WSO2 Identity Server on AWS is quick and simple.

You can set up a simple, CI/CD pipeline for WSO2 Identity Server in a few steps.

### Prerequisites:

* Create and upload an SSL certificate to AWS, which is required to initiate the SSL handshake for HTTPS.
Please see the [AWS official documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/ssl-server-cert.html) for further details.

* Create a key pair for the desired region, which is required to SSH to instances (Skip this step if you want to use an existing key pair).
See [AWS official documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) for further details.

Once you have got the above prerequisites satisfied, let’s get started with the deployment.

- **Step 1**: Use the `jenkins.yaml` file in `cfn` folder, to create the Stack which has the Jenkins.

- **Step 2**: Enter the parameters in the Stack details, to create the Stack. Specify below values for `ProductName` and `DeploymentPattern` parameters.

    `ProductName` : wso2is
    
    `DeploymentPattern` : is

  **Note**: If you do not possess a [WSO2 Subscription](https://wso2.com/subscription), you may leave the `WSO2 Subscription Credentials` empty.

  **Note**: If you do not want to configure a Git Hook to the Pipeline, you may leave the GitHub credentials empty. `Git Hook Repository Name`
  should be a repository used in the pipeline.
  
  You can specify below values for the repository parameters. *Artifacts Repository* can be one of your own repository following the structure of
  [cicd-test-artifacts](https://github.com/wso2-incubator/cicd-test-artifacts.git) Git repository.
    
  - Artifacts Repository (Git) : [https://github.com/wso2-incubator/cicd-test-artifacts.git](https://github.com/wso2-incubator/cicd-test-artifacts.git)
    
  - CloudFormation scripts (Git) : [https://github.com/wso2/aws-cicd-deployment-scripts.git](https://github.com/wso2/aws-cicd-deployment-scripts.git)
    
  - Configuration Repository (Git) : [https://github.com/wso2/aws-cicd-is-configurations.git](https://github.com/wso2/aws-cicd-is-configurations.git)
    
- **Step 3**: Once the Stack is created, get the Jenkins Management Console URL from `Outputs` Tab of AWS Console.

- **Step 4**: Log in to the `JenkinsManagementConsoleURL`, with below username and the password you provided.
    
    Username: admin

- **Step 5**: Once you have logged in, click `Run` on the pop-up window to start the Pipeline.

- **Step 6**: Approve and select `OK` on the `Approve Staging` and `Approve Production` pop-ups to deploy the product into staging and production environments. 

Once the deployment to each environment is completed, you can get the Management Console URL for each environment from the `Outputs` tab of each Stack.

If you have given the valid Github Credentials you can trigger the subsequent builds by pushing a commit to the repository.

# Rapid RNA sequencing data analysis using serverless computing

This document summarizes steps (with detailed screenshots) required to manually set up the RNA-seq serverless pipeline on Amazon Web Services (AWS).  Following these steps for the first time could take a couple of hours even for a technical user. Our graphical frontend using the BioDepot-workflow-builder (Bwb) allows users to skip most of these steps, thus enhances the accessibility of the latest cloud computing platforms for biomedical scientists. 

- AWS Platform
  - Create AWS Account
  - Get AWS Access Key Pair
- Google Cloud Platform
  - Create Google Cloud Account
  - Get Google Cloud Key Pair

### I. Create AWS Account

1. Go [https://aws.amazon.com](https://aws.amazon.com)
2. Create a new AWS account ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws1.png)
3. Fill in the information and continue ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws2.png)
4. Input the account information ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws3.png)
5. And finally the payment information ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws4.png)


### II. Get AWS Access Key Pair

1. Go to My Security Credentials ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws5.png)
2. Click on Create New Access Key and your key pair will be created ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws6.png)
3. This is the last chance you can record Secret Access Key. Either download to save it or record it somewhere ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/aws7.png)

### III. Create Google Cloud Account 

1. Go [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. Sign in Google using any email, click Getting Started ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp1.jpg)
3. Agree and Continue ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp2.jpg)
4. Launch a NEW PROJECT ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp3.jpg)
5. Set a Project name. NO ORGANIZATION if using personal email, and the organization is automatically specified if using institution email ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp4.jpg) 
6. Project created. Go IAM&Admin ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp5.jpg)
7. Service Accounts, CREATE SERVICE ACCOUNT ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp6.jpg)
8. Create service account ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp7.jpg)
9. Get a key pair (See IV. Get Google Cloud Key Pair) ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp8.jpg)
10. Navigate to any computing resource, which requires signing up a billing account ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp9.jpg)
11. Input payment information ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp10.jpg)
12. Personal information and finish ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp11.jpg)

### IV. Get Google Cloud Key Pair

1. Switch to a project ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp14.png)
2. Add service account ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp15.png)
3. Create account ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp16.png)
4. Add permission ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp17.png)
5. Create key as json file ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp18.png)
6. Download and save the key file ![image](https://github.com/BioDepot/serverless-UMI/raw/master/img/gcp19.png)

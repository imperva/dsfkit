# Request access to DSF installation software on Azure

Imperva’s Data Security Fabric product, aka DSF, consists of four sub-products:
1. DSF Hub and Agentless Gateway (formerly Sonar)
2. DAM MX and Agent Gateway
3. DRA Admin and Analytics 
4. DAM Agent audit resource for POC purposes

The following links allow you to request access to the installation software of the three subproducts for the Azure account where you want to deploy DSF.

Following your request, you are automatically granted access after a period of time specified in each link.

**Clarification**: After the DSF installation files are copied, configure the relevant terraform variables and run eDSF Kit.

1. [eDSF Kit - Copy DSF installation to Azure storage account](https://docs.google.com/forms/d/e/1FAIpQLSfCBUGHN04u2gK8IoxuHl4TLooBWUl7cK7ihS9Q5ZHwafNBHA/viewform) (Google form)
   1. **Open only to Imperva employees**
   2. Includes:
      1. DSF Hub and Agentless Gateway (formerly Sonar)
      2. DRA Admin and Analytics 
      3. DAM Agent audit resource for POC purposes

2. _eDSF Kit - Configure programmatic deployment for DAM image and DAM Agent operating system machine_ (In Azure Marketplace)
   1. Make sure you are logged in the Azure account and the Azure subscription 
   2. Configure programmatic deployment for the desired version of Imperva DAM by enabling it on the relevant DAM image from the Azure Marketplace:
      1. For DAM image - click [here](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22imperva%22%2C%22offerId%22%3A%22imperva-dam-v14%22%2C%22planId%22%3A%22securesphere-imperva-dam-14%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D)
      2. For the DAM LTS image - click [here](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22imperva%22%2C%22offerId%22%3A%22imperva-dam-v14-lts%22%2C%22planId%22%3A%22securesphere-imperva-dam-14%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D)
      3. For DAM Agent audit resource for POC purposes, configure programmatic deployment also for [Ubuntu Pro 20.04 LTS image](https://portal.azure.com/#view/Microsoft_Azure_Marketplace/LegalTermsSkuProgrammaticAccessBlade/legalTermsSkuProgrammaticAccessData~/%7B%22product%22%3A%7B%22publisherId%22%3A%22canonical%22%2C%22offerId%22%3A%220001-com-ubuntu-pro-focal%22%2C%22planId%22%3A%22pro-20_04-lts%22%2C%22standardContractAmendmentsRevisionId%22%3Anull%2C%22isCspEnabled%22%3Atrue%7D%7D)


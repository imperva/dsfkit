aws_profile="default"
workstation_cidr=["10.0.0.0/8"]

aws_region_hub="us-west-2"
subnet_hub_primary="subnet-hub-primary"
subnet_hub_secondary="subnet-hub-secondary"
hub_instance_profile_name="hub-primary-instance-profile"
hub_key_pem_details={private_key_pem_file_path = "~/babakama.pem", public_key_name = "babakama"}
web_console_admin_password_secret_name="web_console_admin_password_106_v2"
internal_hub_private_key_secret_name="internal_gw_private_key_106_v2"
internal_hub_public_key_file_path="sonarw.pub"

GROUPA_aws_region="us-west-2"
GROUPA_subnet_gw="subnet-a"
GROUPA_gw_instance_profile_name="gw-primary-instance-profile"
GROUPA_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPA_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPA_web_console_admin_password_secret_name="web_console_admin_password_106_v2"
GROUPA_internal_gw_public_key_file_path="sonarw.pub"
GROUPA_security_group_ids_gw=[]
GROUPA_gw_count=0

GROUPB_aws_region="us-west-1"
GROUPB_subnet_gw="subnet-b"
GROUPB_gw_instance_profile_name="gw-primary-instance-profile"
GROUPB_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPB_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPB_web_console_admin_password_secret_name="web_console_admin_password_106_v2"
GROUPB_internal_gw_public_key_file_path="sonarw.pub"
GROUPB_security_group_ids_gw=[]
GROUPB_gw_count=0

GROUPC_aws_region="us-east-1"
GROUPC_subnet_gw="subnet-c"
GROUPC_gw_instance_profile_name="gw-primary-instance-profile"
GROUPC_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPC_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPC_internal_gw_public_key_file_path="sonarw.pub"
GROUPC_web_console_admin_password_secret_name="web_console_admin_password_106_v2"
GROUPC_security_group_ids_gw=[]
GROUPC_gw_count=0

GROUPD_aws_region="us-east-2"
GROUPD_subnet_gw="subnet-d"
GROUPD_gw_instance_profile_name="gw-primary-instance-profile"
GROUPD_gw_key_pem_details={private_key_pem_file_path = "~/key_pair.pem", public_key_name = "key_pair"}
GROUPD_internal_gw_private_key_secret_name="internal_gw_private_key_106_v2"
GROUPD_web_console_admin_password_secret_name="web_console_admin_password_106_v2"
GROUPD_internal_gw_public_key_file_path="sonarw.pub"
GROUPD_security_group_ids_gw=[]
GROUPD_gw_count=0
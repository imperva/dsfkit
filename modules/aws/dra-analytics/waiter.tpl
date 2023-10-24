  while true; do
    response=$(curl -k -s -o /dev/null -w "%%{http_code}" --request GET 'https://${dra_admin_adress_for_api_access}:8443/mvc/login')
    if [ $response -eq 200 ]; then
      exit 0
    else
      sleep 60
    fi
  done
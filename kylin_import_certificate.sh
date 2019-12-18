set -eux

function validateParams () {
    if [ "$#" -ne 3 ]; then
        echo "Illegal numbers of parameters"
        echo "Environment/Path OF CERTIFICATE/REGION is not defined in parameters"
        echo "kylin_import_certificate.sh [ENV] [PATH OF CERTIFICATE] [REGION]"
        exit 1
    fi
}

function importSingedCertificateWithPrivateKey () {
  validateParams $*
  site_name=kylin-$1.sensity.com
  certificate_path=$2
  region=$3
  pkcs_file=${site_name}-import.p12
  secret_id_for_site_name_keypair=${site_name}.keypair
  private_key_file=${site_name}.private.key
  secret_id_for_tomcat_certificate=kylin-$1-tomcat-certificate

  private_key=$(aws secretsmanager get-secret-value --secret-id ${secret_id_for_site_name_keypair} --version-stage AWSCURRENT --region ${region} | jq -r .SecretString | jq -r .private_key)

  echo "$private_key" > ${private_key_file}


  #Convert certificate to p12 (PKCS12) format
  openssl pkcs12 -export -in ${certificate_path} -inkey ${private_key_file} -out ${site_name}.p12 -passout pass:""

  aws secretsmanager create-secret --name ${secret_id_for_tomcat_certificate} --description "pkcs12 file with certificate and private key for domain "${site_name} --secret-binary fileb://${site_name}.p12


  rm $(pwd)/${private_key_file}
  rm $(pwd)/${site_name}.p12

importSingedCertificateWithPrivateKey $*

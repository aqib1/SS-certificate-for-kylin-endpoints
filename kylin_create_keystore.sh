set -eux

function validateParams () {
    if [ "$#" -ne 1 ]; then
        echo "Illegal numbers of parameters"
        echo "Environment name is not defined in parameters"
        echo "kylin_create_keystore.sh [ENV]"
        exit 1
    fi
}


function create_keystore() {
    validateParams $*
    site_name=kylin-$1.sensity.com
    ou="VERIZON"
    country="US"
    state="CA"
    echo "Kylin endpoint received ["${site_name}+"]"

    # Generate private key, Certificate signing request request
    openssl req -out ${site_name}.csr -new -newkey rsa:2048 -nodes -keyout ${site_name}.private.key -subj "/CN=${site_name}/OU=${ou}/O=${ou}/C=${country}/ST=${state}"
    # Fetch public key from, CSR for storing that to aws secrete manager
    openssl req -in ${site_name}.csr -noout -pubkey -out ${site_name}.public.key

    private_key=$(cat ${site_name}.private.key);
    #echo "$private_key"
    public_key=$(cat ${site_name}.public.key);
    #echo "$public_key"
    keypair_json=$(jq -n \
                    --arg pk "$private_key" \
                    --arg pub "$public_key" \
                    '{private_key: $pk, public_key: $pub}'
    );
    echo "$keypair_json" > keystore.json

    aws secretsmanager create-secret --name ${site_name}.keypair --description "private/public key file for domain "${site_name} --secret-string file://keystore.json



    rm $(pwd)/${site_name}.private.key
    rm $(pwd)/${site_name}.public.key
    rm $(pwd)/keystore.json

create_keystore $*

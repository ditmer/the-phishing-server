#/bin/bash
##
## Install Script - Run This First
## Author: Rob Ditmer
##

GREEN='\033[0;92m'
RED='\033[0;31m'
YELLOW='\033[0;93m'
NC='\033[0m'

echo -e $YELLOW 
echo "###############################"
echo "#"
echo "#  Mail Server Install Script"
echo "#"
echo "###############################"
echo -e $NC

# functions
#
#

function createConfig(){
cat <<here >config/.global
MAILDOMAIN=
MAILHOSTNAME=
ADMINEMAIL=
MYSQL_DATABASE=mailserver
MYSQL_USER=
MYSQL_PASSWORD=
MYSQL_ROOT_PASSWORD=
here
echo "test1"
}

function startLetsEncrypt() {
	echo "Running certbot"
	if [ -n $( command -v certbot ) ]; then
		PKG_MANAGER=$( command -v yum || command -v apt-get )
		if [ ! -z "$PKG_MANAGER" ]; then
			echo "Installing cerbot, cause it ain't on this system"
			echo "Will need sudo rights, if you didn't run this as sudo"
			sudo ${PKG_MANAGER} install certbot
		else
			echo "Certbot isn't installed and I tried to do it for you but I can't identifiy your package manager. Please install it manually and run this script again"
			exit 1
		fi
	fi

	DOMAIN=$1
	HOSTNAME=$2
	EMAIL="admin@${DOMAIN}"
	BOTMAILHOSTNAME="${HOSTNAME}.${DOMAIN}"
	certbot certonly --standalone -d $BOTMAILHOSTNAME -m $EMAIL
	if [ ! $? -eq 0 ]; then
		echo "Certbot failed, it's dark and cold, i'm scared.."
		exit 1
	fi
	sudo cp "/etc/letsencrypt/live/${BOTMAILHOSTNAME}/cert.pem" certs/server.pem
	sudo cp "/etc/letsencrypt/live/${BOTMAILHOSTNAME}/privkey.pem" certs/server-key.pem
	sudo cp "/etc/letsencrypt/live/${BWOTMAILHOSTNAME}/chain.pem" certs/serverCA.pem
}

function startOpenSSL() {
	echo "test"
	DOMAIN=$1
	HOSTNAME=$2
	EMAIL="admin@${DOMAIN}"
	CERTMAILHOSTNAME="${HOSTNAME}.${DOMAIN}"
	myState=(AL AK AZ AR CA CO CT DE GA HI ID IL IN IA KS MD MI MN MS OH OK RI SC SD TN TX WV WY WI) 
	size=${#myState[@]}
	state=$(($RANDOM % $size))
	subj="/C=US/ST=${myState[$state]}/O=${DOMAIN}/localityName=${DOMAIN}/commonName=${CERTMAILHOSTNAME}/organizationalUnitName=${CERTMAILHOSTNAME}/emailAddress=${EMAIL}"
	PASSPHRASE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	# Generate the server private key
	openssl genrsa -des3 -out certs/server-key.pem -passout pass:$PASSPHRASE 2048

	# Generate the CSR
	openssl req \
		-new \
		-batch \
		-subj "$(echo -n "$subj")" \
		-key certs/server-key.pem \
		-out certs/server.csr \
		-passin pass:$PASSPHRASE

	# Strip the password so we don't have to type it every time we restart Apache
	openssl rsa -in certs/server-key.pem -out certs/server-key.pem -passin pass:$PASSPHRASE


	# Generate the cert (good for 10 years)
	openssl x509 -req -days 3650 -in certs/server.csr -signkey certs/server-key.pem -out certs/server.pem

	cp certs/server.pem certs/serverCA.pem
}

function getDomainName() {
	while true; do
		declare -a myarray
		let i=0
		echo "What TLD/domain are you going to use for this mail server, here are some options"
		echo -e $GREEN
		while IFS=$'\n' read -r line_data; do
			echo " $((i + 1)). ${line_data}"
			myarray[i]="${line_data}" # Populate array.
			((++i))
		done < domain_list
		echo " $((i + 1)). Specify a custom one"
		echo -e $NC
		read -p "You must choose, NOW: " DOMAINCHOICE
		if (($DOMAINCHOICE > 0 && $DOMAINCHOICE <= i)); then
			THEMAILDOMAIN=${myarray[$DOMAINCHOICE - 1]}
			break;
		fi
		if [ $((i + 1)) == $DOMAINCHOICE ]; then
			echo ""
			read -p "Please enter the domain name: " THEMAILDOMAIN
			break;
		fi
	done
}

function getHostName() {
	while true; do
		echo ""
		echo "What hostname are you going to use for this mail server?"
		echo -e "Some options could be${GREEN} mail, mail1, mail2,${NC} etc."
		echo -e "${YELLOW}--- Just make sure the mx and dns records match what hostname you are picking. ---${NC}"
		echo ""
		read -p "Please enter a hostname: " THEHOSTNAME
		if [ ! -z "$HOSTNAME" ]; then
			break;
		fi 
	done
}

function getCerts() {
	# Ask for certs location
	echo ""
	let d=0
	MMDOMAIN=$1
	HHNAME=$2
	while true; do
		echo "We need to generate certs first, here are the options"
		echo -e $GREEN
		echo " 1. Use letsencrypt to generate certs"
		echo " 2. Generate self signed certs for me"
		echo " 3. I got my own certs, I'll provide the path"
		echo -e $NC
		read -p "What say you: " CERTCHOICE
		case $CERTCHOICE in
			1)
				startLetsEncrypt $MMDOMAIN $HHNAME
				d=1
				;;
			2)
				startOpenSSL $MMDOMAIN $HHNAME
				d=1
				;;
			3)
				let c=0
				while true; do
					echo ""
					if (($c >= 3)); then
						echo -e $RED
						echo "I am having trouble finding your certificate files, it's over for us. You were great"
						echo "Please check paths and permissions, or use another option"
						echo $NC
						exit 1
					fi
					read -p "Please enter the full path to the server certificate file: " userCertFile
					read -p "Please enter the full path to the server key file: " userKeyFile
					read -p "Please enter the full path to the CA file: " userCaFile
						if [[ ! -f "$userCertFile" ]]; then
							echo -e "${RED}Can't find server certificate file, check path and try again${NC}"
						elif [[ ! -f "$userKeyFile" ]]; then
							echo -e "${RED}Can't find server key file, check path and try again${NC}"
						elif [[ ! -f "$userCaFile" ]]; then
							echo -e "${RED}Can't find CA file, check path and try again${NC}"
						else
							cp userCertFile "certs/server.pem"
							cp userKeyFile "certs/server-key.pem"
							cp userCaFile "certs/serverCA.pem"
							echo -e "${GREEN}Found all files, moving on...${NC}"
							break;
						fi
						((++c))
				done
				d=1	
				;;
		esac
		if (($d == 1)); then
			break;
		fi
	done
}

function initialInstall() {
	# Generate Password For MySQL User
	MAILDOMAIN=$1
	HOSTNAME=$2
	if [ $3 == "ReadGlobalConfigFile" ]; then
		ADMINEMAIL=$(awk -F "=" '/ADMINEMAIL/{print $2}' config/.global)
		ADMINPASS="$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 32 | head -n 1)"
		MYSQLUSER=$(awk -F "=" '/MYSQL_USER/{print $2}' config/.global)
		MYSQLPASSPHRASE=$(awk -F "=" '/MYSQL_PASSWORD/{print $2}' config/.global)
		MYSQLROOTPASSPHRASE=$(awk -F "=" '/MYSQL_ROOT_PASSWORD/{print $2}' config/.global)
		KEEPCONFIG=1
	else
		ADMINPASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		ADMINEMAIL="$(cat /dev/urandom | tr -dc 'a-zA-Z' | fold -w 6 | head -n 1)@${MAILDOMAIN}"
		MYSQLUSER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
		MYSQLPASSPHRASE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		MYSQLROOTPASSPHRASE=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		KEEPCONFIG=0
	fi	
	MAILHOSTNAME="${HOSTNAME}.${MAILDOMAIN}"

	echo -e "${GREEN}Rewriting config files with new info${NC}"
	# Rewrite global config files
	sed -i 's/^ADMINEMAIL=.*$/ADMINEMAIL='"$ADMINEMAIL"'/' config/.global
	sed -i 's/^MAILDOMAIN=.*$/MAILDOMAIN='"$MAILDOMAIN"'/' config/.global
	sed -i 's/^MAILHOSTNAME=.*$/MAILHOSTNAME='"$HOSTNAME"'/' config/.global
	sed -i 's/^MYSQL_USER=.*$/MYSQL_USER='"$MYSQLUSER"'/' config/.global
	sed -i 's/^MYSQL_PASSWORD=.*$/MYSQL_PASSWORD='"$MYSQLPASSPHRASE"'/' config/.global
	sed -i 's/^MYSQL_ROOT_PASSWORD=.*$/MYSQL_ROOT_PASSWORD='"$MYSQLROOTPASSPHRASE"'/' config/.global

	# Rewrite Postfix Config Files With New Certificate and Password Info
	# MySQL Files
	sed -i 's/^user = .*$/user = '"$MYSQLUSER"'/' config/postfix/mysql-virtual-*
	sed -i 's/^password = .*$/password = '"$MYSQLPASSPHRASE"'/' config/postfix/mysql-virtual-*

	# Postfix Main.cf
	#MAILHOSTNAME="${MAILHOSTNAME}.${MAILDOMAIN}"

	#echo "${certFile}"
	sed -i 's/^myhostname = .*$/myhostname = '"$MAILHOSTNAME"'/' config/postfix/main.cf
	sed -i 's/^mydomain = .*$/mydomain = '"$MAILDOMAIN"'/' config/postfix/main.cf

	echo "@${MAILDOMAIN}	${ADMINEMAIL}" > config/postfix/virtual

	# Rewrite Dovecot Config Files With Password Info
	# MySQL Files
	# connect = host=db dbname=mailserver user=mailuser password=mailuserpass
	sed -i 's/^connect = .*$/connect = host=db dbname=mailserver user='"${MYSQLUSER}"' password='"${MYSQLPASSPHRASE}"'/' config/dovecot/dovecot-sql.conf.ext

	echo -e "${GREEN}Rewriting docker-compose.yml with new info${NC}"
	sed -i 's/ini_domain: .*$/ini_domain: '"$MAILDOMAIN"'/' docker-compose.yml
    
	echo -e "${GREEN}Generating DKIM keys${NC}"
	#DKIM
	openssl genrsa -out config/dkim/private.key 1024
	openssl rsa -in config/dkim/private.key -out config/dkim/public.key -pubout -outform PEM
	sed -i 's/^Domain                  .*$/Domain                  '"$MAILDOMAIN"'/' config/dkim/opendkim.conf
	mkdir -p config/dkim/keys/$MAILDOMAIN
	mv config/dkim/private.key config/dkim/keys/$MAILDOMAIN/default
	
	#mail._dchmod 600 config/dkim/keys/$MAILDOMAIN/defaultomainkey.example.com example.com
	echo "mail._domainkey.${MAILDOMAIN} ${MAILDOMAIN}:mail:/etc/postfix/dkim/${MAILDOMAIN}/default" > config/dkim/keyfile
	echo "*@${MAILDOMAIN} mail._domainkey.${MAILDOMAIN}" > config/dkim/sigfile
	echo $MAILDOMAIN >> config/dkim/TrustedHosts
	echo "${HOSTNAME}.${MAILDOMAIN}" >> config/dkim/TrustedHosts
	# Rewrite Docker-Compose bits
	#sed -i 's/MYSQL_USER: .*$/MYSQL_USER: '"$MYSQLUSER"'/' docker-compose.yml
	#sed -i 's/MYSQL_PASSWORD: .*$/MYSQL_PASSWORD: '"$MYSQLPASSPHRASE"'/' docker-compose.yml
	#sed -i 's/MYSQL_ROOT_PASSWORD: .*$/MYSQL_ROOT_PASSWORD: '"$MYSQLROOTPASSPHRASE"'/' docker-compose.yml

	# Generate Password For Admin Mail Account
	echo -e "${GREEN}Generating password for admin/catchall email account - ${YELLOW}${ADMINEMAIL}${NC}"
	adminUserPass=$(lib/sha512gen.py ${ADMINPASS})

	# Update mail drive permissions
	sudo chown mail:mail -R user-mail/
	sudo chmod 760 -R user-mail/

	echo -e "${GREEN}Building dockers${NC}" 
	sudo docker-compose build
	sudo docker-compose up -d db
	#sudo docker-compose up db

	echo -e "${GREEN}Waiting for db docker to be up, so we can populate it with specifics - don't judge me${NC}"
	while [ "`sudo docker inspect -f {{.State.Health.Status}} mysql_db`" != "healthy" ]; do sleep 2; done

	echo -e "${GREEN}DB is ready, populating stuff with things${NC}"
	if [ $KEEPCONFIG -eq 0 ]; then
		cat config/mysql/init.sql | sudo docker exec -i mysql_db mysql -h db -u ${MYSQLUSER} -p${MYSQLPASSPHRASE} mailserver
	fi
	sudo docker exec -i mysql_db mysql -h db -u ${MYSQLUSER} -p${MYSQLPASSPHRASE} -e "INSERT INTO mailserver.virtual_domains (id, name) VALUES ('1', '${MAILDOMAIN}') ON DUPLICATE KEY UPDATE name='${MAILDOMAIN}';"
	sudo docker exec -i mysql_db mysql -h db -u ${MYSQLUSER} -p${MYSQLPASSPHRASE} -e "INSERT INTO mailserver.virtual_users (id, domain_id, password, email) VALUES('1', '1', '${adminUserPass}', '${ADMINEMAIL}') ON DUPLICATE KEY UPDATE password='${adminUserPass}';"

	sudo docker-compose up -d postfix web

	echo -e $YELLOW
	echo -e "##############################################################${NC}"
	echo "Here are all the good bits, please keep this for reference:"
	echo -e $GREEN
	echo " - Domain mail server running under:  ${MAILDOMAIN}"
	echo " - Hostname for mail server:          ${HOSTNAME}"
	echo " - Admin/catch all email address:     ${ADMINEMAIL}"
	echo " - Admin/catch all email password:    ${ADMINPASS}"
	echo " - MySQL username:                    ${MYSQLUSER}"
	echo " - MySQL user password:               ${MYSQLPASSPHRASE}"
	echo " - MYSQL root password:               ${MYSQLROOTPASSPHRASE}"
	echo ""
	echo -e "${YELLOW}##############################################################"
	echo -e $RED
	echo "*** Please go to https://127.0.0.1:8443/?admin and reset the rainloop admin password ASAP ***"
	echo "*** Current default rainloop admin credentials are admin:12345 ***"
	echo -e $GREEN
	echo " - Rainloop web mail can be found here: https://127.0.0.1:8443/"
	echo " - Log in with admin email shown above"
	echo "		*This email is a catch all, any email sent to ${MAILDOMAIN} will end up in this mailbox"
	echo " - Postfix is running on port 25 and 587"
	echo " - Dovecot is running on port 993"
	echo ""
	echo -e "${YELLOW}##############################################################"
	echo -e $GREEN
	echo " - Create a DNS record for this mail server: "
	echo "   type: A Record"
	echo "   host: ${HOSTNAME}"
	echo "   value: $(curl http://ifconfig.io)"
	echo ""
	echo " - Create the following MX record for ${MAILDOMAIN}: "
	echo "   type: MX Record"
	echo "   host: @"
	echo "   value: ${HOSTNAME}.${MAILDOMAIN}"
	echo " 	 priority: 10"
	echo ""
	echo " - Create the following SPF record for ${MAILDOMAIN}: "
	echo "   type: TXT Record"
	echo "   host: @"
	echo "   value: v=spf1 a:${HOSTNAME}.${MAILDOMAIN} -all"
	echo ""
	echo " - Create the following DKIM record for ${MAILDOMAIN}: "
	echo "   type: TXT Record"
	echo "   host: ${HOSTNAME}._domainkey"
	echo "   value: v=DKIM1; k=rsa; p=$(cat config/dkim/public.key | sed '1,1d;$ d')"
	echo ""
	echo " - Create the following DMARC record for ${MAILDOMAIN}: "
	echo "   type: TXT Record"
	echo "   host: _dmarc"
	echo "   value: v=DMARC1; p=none; rua=mailto:dmarc-reports@${HOSTNAME}.${MAILDOMAIN}"
	echo ""
 	echo -e $NC
}

#
# main app
#

# Check for global config
if [[ -f config/.global ]]; then
	while true; do
		echo -e $YELLOW
		echo "It looks like the global config file exists."
		read -p "Do you want to use that file for building everything (y/n)? " yn
		case $yn in
			[Yy]* )
				USEGLOBAL=true
				break
				;;
			[Nn]* )
				USEGLOBAL=false
				break
				;;
			* )
				echo -e "${RED}Bro...come on...y or n"
				;;
		esac
	done
	echo -e $NC
else
	USEGLOBAL=false
fi

if [ "$USEGLOBAL" = false ]; then
	createConfig
	getDomainName
	getHostName
	echo $THEMAILDOMAIN
	getCerts $THEMAILDOMAIN $THEHOSTNAME
	initialInstall $THEMAILDOMAIN $THEHOSTNAME "no"
else
	THEMAILDOMAIN=$(awk -F "=" '/MAILDOMAIN/{print $2}' config/.global)
	THEHOSTNAME=$(awk -F "=" '/MAILHOSTNAME/{print $2}' config/.global)
	if [ ! -f "certs/server.pem" ] || [ ! -f "certs/server-key.pem" ] || [ ! -f "certs/serverCA.pem" ]; then
		echo "${RED}No certs detected, going to create them${NC}"
		getCerts $THEMAILDOMAIN $THEHOSTNAME
		initialInstall $THEMAILDOMAIN $THEHOSTNAME "ReadGlobalConfigFile"
	else
		initialInstall $THEMAILDOMAIN $THEHOSTNAME "ReadGlobalConfigFile"
	fi
fi
#!/bin/bash

function die () {
  echo 2>&1 $1
  exit 1
}

if [ $(whoami) != "root" ] ; then
  sudo $0 $@ || die "Not run as root or cannot sudo to root"
  exit $?
fi

apt-get install -y memcached redis-server postgresql daemon unzip npm

# Create dev/test databases and users, set passwords
for user in $(whoami) cloudos cloudos_dns wizard_form ${CLOUDSTEAD_ADDITIONAL_DBS} ; do
  sudo -u postgres -H createuser ${user}
  for name in ${user} ${user}_test ; do
    sudo -u postgres -H createdb ${name}
  done
  sudo -u postgres -H bash -c "echo \"alter user ${user} with password '${user}'\" | psql -U postgres"
done

# Set passwords for db users (needed to generate schemas).
# If you changed the password generation above, then update the values below to match your passwords
echo "export CLOUDOS_DB_PASS=cloudos" >> ~/.cloudos-test.env
echo "export CLOUDOS_DNS_DB_PASS=cloudos_dns" >> ~/.cloudos-dns-test.env

KESTREL_HOME=/usr/local/kestrel

sudo useradd -d ${KESTREL_HOME} -s /usr/sbin/nologin kestrel

for dir in /usr/local /var/log /var/run /var/spool ; do
  sudo mkdir -p ${dir}/kestrel
done

wget -O /tmp/kestrel-2.4.1.zip http://robey.github.com/kestrel/download/kestrel-2.4.1.zip
cd ${KESTREL_HOME} && \
  sudo rm -rf ./* && \
  sudo unzip /tmp/kestrel-2.4.1.zip && \
  sudo ln -s kestrel-2.4.1 current && \
  sudo chmod +x current/scripts/* && \
  sudo mkdir -p ${KESTREL_HOME}/logs && \
  sudo mkdir -p ${KESTREL_HOME}/target && \
  cd ${KESTREL_HOME}/target && \
  KESTREL_JAR=$(find ../current/ -type f -name "kestrel*.jar" | grep -v javadoc | grep -v sources | grep -v test) && \
  if [ -z ${KESTREL_JAR} ] ; then
    echo "Kestrel jar not found"
    exit 1
  fi && \
  sudo ln -s ${KESTREL_JAR} kestrel-$(basename ${KESTREL_JAR}) && \
  sudo ln -s ../current/config && \
  sudo chown -R kestrel ${KESTREL_HOME} && \
  echo "Kestrel successfully installed." && \
  sudo _JAVA_OPTIONS=-Djava.net.preferIPv4Stack=true ${KESTREL_HOME}/current/scripts/devel.sh & \
  sleep 2s && echo "Kestrel successfully started: $(ps auxwww | grep kestrel_ | grep -v grep)"

# Install bcrypt
npm install -g bcryptjs
BCRYPT=/usr/local/lib/node_modules/bcryptjs/bin/bcrypt
TMP=$(mktemp /tmp/bcrypt.XXXXXX) || die "Error creating temp file"
cat ${BCRYPT} | tr -d '\r' > ${TMP}
cat ${TMP} > ${BCRYPT}
chmod a+rx ${BCRYPT}
ln -s ${BCRYPT} /usr/local/bin/bcrypt

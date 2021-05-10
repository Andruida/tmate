if [ -z "${HOST_UID}" ]; then
    echo "Host user ID not found in environment. Using default (1000)."
    export HOST_UID=1000
fi

if [ -z "${HOST_GID}" ]; then
    echo "Host group ID not found in environment. Using default (1000)."
    export HOST_GID=1000
fi

if [ -z "${HOST_USERNAME}" ]; then
    echo "Host username not found in environment. Using default (admin)."
    export HOST_USERNAME=admin
fi

if ! getent group "${HOST_GID}" | cut -d: -f1 | read; then 
    addgroup "${HOST_USERNAME}" --gid "${HOST_GID}"
    HOST_GROUPNAME="${HOST_USERNAME}"
else
    HOST_GROUPNAME=`getent group "${HOST_GID}" | cut -d: -f1`
fi

if getent passwd "$(id -u $HOST_USERNAME)" | cut -d: -f1 | read; then
    echo ""    
elif getent passwd "${HOST_UID}" | cut -d: -f1 | read; then 
    export HOST_USERNAME=`getent passwd "${HOST_UID}" | cut -d: -f1`
else
    #echo $HOST_GROUPNAME $HOST_UID $HOST_USERNAME
    useradd -m -p sKzEqcFhB5Zfo -s /bin/bash --gid "$HOST_GID" --uid "$HOST_UID" "$HOST_USERNAME" 
    passwd -e "$HOST_USERNAME" 
    usermod -aG sudo "$HOST_USERNAME"
fi

cd /home/admin

if [[ -z $1 ]]; then
    exec sudo -u "$HOST_USERNAME" -H env "PATH=$PATH" /build/tmate -F
else
    exec sudo -u "$HOST_USERNAME" -H env "PATH=$PATH" $@
fi

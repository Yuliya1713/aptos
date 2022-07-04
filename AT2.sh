#!/bin/bash

function aptos_username {
  if [ ! ${aptos_username} ]; then
  echo "Введите свое имя ноды(придумайте)"
  line
  read aptos_username
  fi
}

function install_ufw {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_ufw.sh | bash
}

function install_docker {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/tools/install_docker.sh | bash
}

function set_vars {
  echo "export aptos_username=${aptos_username}"  >> ${HOME}/.bash_profile
}

function update_deps {
  sudo apt update
  sudo apt install mc build-essential wget htop curl jq unzip -y
}

function download_aptos_cli {
  rm -f /usr/local/bin/aptos
  wget -O $HOME/aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-0.2.0/aptos-cli-0.2.0-Ubuntu-x86_64.zip
  sudo unzip -o aptos-cli -d /usr/local/bin
  sudo chmod +x /usr/local/bin/aptos
}

function prepare_config {
  mkdir ${HOME}/aptos_testnet
  wget -qO $HOME/aptos_testnet/docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
  wget -qO $HOME/aptos_testnet/validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml
}

function prepare_validator {
  mkdir -p $HOME/aptos_testnet/keys/

  aptos genesis generate-keys --output-dir $HOME/aptos_testnet

  aptos key generate --output-file $HOME/aptos_testnet/keys/root

  aptos genesis set-validator-configuration \
    --keys-dir $HOME/aptos_testnet --local-repository-dir $HOME/aptos_testnet \
    --username "$aptos_username" \
    --validator-host `wget -qO- eth0.me`:6180 \
    --full-node-host `wget -qO- eth0.me`:6182

  tee $HOME/aptos_testnet/layout.yaml > /dev/null <<EOF
root_key: "F22409A93D1CD12D2FC92B5F8EB84CDCD24C348E32B3E7A720F3D2E288E63394"
users:
 - $aptos_username
chain_id: 40
min_stake: 0
max_stake: 100000
min_lockup_duration_secs: 0
max_lockup_duration_secs: 2592000
epoch_duration_secs: 86400
initial_lockup_timestamp: 1656615600
min_price_per_gas_unit: 1
allow_new_validators: true
EOF

  wget -q https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.2.0/framework.zip
  unzip -o framework.zip -d $HOME/aptos_testnet/
  rm framework.zip

  aptos genesis generate-genesis --local-repository-dir $HOME/aptos_testnet --output-dir $HOME/aptos_testnet
}

function up_validator {
  docker compose -f ${HOME}/aptos_testnet/docker-compose.yaml up -d
}
function logo {
  curl -s https://raw.githubusercontent.com/razumv/helpers/main/doubletop.sh | bash
}

function line {
  echo "-----------------------------------------------------------------------------"
}

function colors {
  GREEN="\e[1m\e[32m"
  RED="\e[1m\e[39m"
  NORMAL="\e[0m"
}

colors
line
logo
line
aptos_username
set_vars
line
install_ufw
install_docker
update_deps
line
download_aptos_cli
prepare_config
prepare_validator
line
up_validator
line
echo "Готово"

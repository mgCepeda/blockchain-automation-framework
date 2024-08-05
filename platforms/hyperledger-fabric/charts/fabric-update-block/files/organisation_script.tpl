#!/bin/bash

set -x

CURRENT_DIR=${PWD}

echo "installing jq "
apt-get update
apt-get install -y jq
echo "installing configtxlator"
mkdir temp
cd temp/
wget https://github.com/hyperledger/fabric/releases/download/v{{ $.Values.global.version }}/hyperledger-fabric-linux-amd64-{{ $.Values.global.version }}.tar.gz
tar -xvf hyperledger-fabric-linux-amd64-{{ $.Values.global.version }}.tar.gz
mv bin/configtxlator ../
cd ../
rm -r temp
echo "converting the channel_config_block.pb to channel_config.json using configtxlator and jq"
configtxlator proto_decode --input {{ $.Values.channelName }}_config_block.pb --type common.Block | jq .data.data[0].payload.data.config > {{ $.Values.channelName }}_config.json
echo "adding new organization crypto material from config.json to the channel_config.json to make channel_modified_config.json"
jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"{{ $.Values.organization.name }}MSP":.[1]}}}}}' {{ $.Values.channelName }}_config.json ./config.json > {{ $.Values.channelName }}_modified_config_without_anchorpeer.json
echo "adding anchor peer information to the block"
jq '.channel_group.groups.Application.groups.{{ $.Values.organization.name }}MSP.values += {"AnchorPeers":{"mod_policy": "Admins","value":{"anchor_peers": ['$(cat ./anchorfile.json)']},"version": "0"}}' {{ $.Values.channelName }}_modified_config_without_anchorpeer.json > {{ $.Values.channelName }}_modified_config.json
echo "converting the channel_config.json and channel_modified_config.json to .pb files"
configtxlator proto_encode --input {{ $.Values.channelName }}_config.json --type common.Config --output {{ $.Values.channelName }}_config.pb
configtxlator proto_encode --input {{ $.Values.channelName }}_modified_config.json --type common.Config --output {{ $.Values.channelName }}_modified_config.pb
echo "calculate the delta between these two config protobufs using configtxlator"
configtxlator compute_update --channel_id {{ $.Values.channelName }} --original {{ $.Values.channelName }}_config.pb --updated {{ $.Values.channelName }}_modified_config.pb --output {{ $.Values.channelName }}_update.pb
echo "decode the channel_update.pb to json to add headers."
configtxlator proto_decode --input {{ $.Values.channelName }}_update.pb --type common.ConfigUpdate | jq . > {{ $.Values.channelName }}_update.json
echo "wrapping the headers arround the channel_update.json file and create channel_update_in_envelope.json"
echo '{"payload":{"header":{"channel_header":{"channel_id":"{{ $.Values.channelName }}", "type":2}},"data":{"config_update":'$(cat {{ $.Values.channelName }}_update.json)'}}}' | jq . > {{ $.Values.channelName }}_update_in_envelope.json
echo "converting the channel_update_in_envelope.json to channel_update_in_envelope.pb"
configtxlator proto_encode --input {{ $.Values.channelName }}_update_in_envelope.json --type common.Envelope --output {{ $.Values.channelName }}_update_in_envelope.pb
mv {{ $.Values.channelName }}_config_block.pb {{ $.Values.channelName }}_config_block_old.pb
cp {{ $.Values.channelName }}_update_in_envelope.pb {{ $.Values.channelName }}_config_block.pb
cd ${CURRENT_DIR}

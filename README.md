# oxygenation_kc
Repo for Oxygenation project proposed by KC at Datathon




# Installing BigQuery CLI

From https://cloud.google.com/sdk/docs/

export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
gcloud init


Run the script sync_to_bq.sh in data-extraction to upload the current queries to the BigCloud server.

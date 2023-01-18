#!/bin/bash
rm -rf kubeconfigs

bash ../ca/gencerts.sh
bash genconfig.sh
bash gentemplates.sh
bash genetcdconfig.sh
bash genapiserver.sh
bash genkubecontrollermanagerserver.sh
bash genkubeschedulerserver.sh
bash genworkerconfigs.sh
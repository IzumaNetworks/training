machine=tbuild3
ssh $machine "mkdir ~/Edge_Credentials"
scp ~/CERTS/DEMO-CLOUD/* $machine:~/Edge_Credentials/
scp module.sh $machine:~/

## Introduction
The main utility for this tool is to be able to run chef cookbooks locally in vagrant boxes. To get started with, clone this repository, `cd cookbooks && bundle install`.

## Vagrant setup
Install virtualbox and vagrant on your system. Change into cookbooks folder. Run the below commands to bring up vagrant.
```
vagrant init hashicorp/xenial64
vagrant up
```

## Kitchen steps to converge and test your cookbook
```
cd cookbooks
kitchen converge
kitchen verify
```

## Kitchen debugging
```
cd cookbooks
kitchen login
```

An example .kitchen-ec2.yml has been included, to run the same steps on an AWS EC2 instance. 







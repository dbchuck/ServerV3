# OpenStack Setup

This is an inefficient setup of OpenStack, but it allows a person to emulate a production OpenStack cluster.

## Requirements:

- 48GB+ of RAM
- 40GB+ of storage space

## Recommendations:

- Highly recommended to use SSDs to host OpenStack VMs.
- Have over 64GB of RAM to partition a few machines in OpenStack
- 8+ physical cores
- 100Mb/s Internet connection


### Step 1
Install CentOS 7 minimal

### Step 2
Transfer your customized config.sample file, setup.sh, reboot* folders via scp or git clone to the baremetal machine intended to run the OpenStack environment.

### Step 3
Execute: `# bash setup.sh config.sample `

The bash script will reboot the computer once although this behavior may change in the future.

### Step 4
After the baremetal machine reboots, check the status of the install scripts: `# systemctl status persist.service `

When it says 'active (exited)', the install scripts are done.

### Step 5
Follow the instructions in `openstack_installation_instructions.txt`

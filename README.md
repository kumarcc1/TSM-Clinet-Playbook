Ansible role for TSM Client
===========================

Install and configure the client for [Tivoli Storage
Manager](http://www-03.ibm.com/software/products/en/spectrum-protect) (now
renamed *IBM Spectrum Protect*). Also register it into the TSM server.

Requirements
------------

The TSM server must be already installed and working. You need to know its
admin username and password.

If you want to register the newly installed node in the TSM server, then you
also need to add it inside Ansible's inventory (in order to allow this role to
delegate commands to the server).

Role Variables
--------------

See [defaults/main.yml](blob/master/defaults/main.yml) for full list.

The version to install is defined by `tsm_client_archive_uri` and
`tsm_client_archive_file` variables, repectively the URI and filename of the
archive to download from IBM FTP server. If you change these values, you must
verify `tsm_client_install_rpms` still lists the right RPMs to install.

Include and exclude list is defined by `tsm_client_incl_excl` list variable.

Example Playbook
----------------

```yaml
# Without registering into the server
- hosts: all
  roles:
  - role: ansible-role-tsm-client
    tsm_client_servers:
    - ServerName: TEST_SRV_1
      TCPServerAddress: test-tsm-1.example.com
    - ServerName: TEST_SRV_2
      TCPServerAddress: test-tsm-2.example.com
    tsm_client_incl_excl:
    - exclude.fs /proc
    - exclude.fs /dev
    - exclude.dir /tmp
    - exclude /.../core

# With the registration into the server
- hosts: all
  roles:
  - role: ansible-role-tsm-client
    tsm_client_servers:
    - ServerName: TSM-SRV
      TCPServerAddress: tsm-srv.example.com
    tsm_client_server_in_inventory: tsm-srv
    tsm_client_server_tsm_password: my_password
    tsm_client_node_password: "MyPasswordFor{{ ansible_hostname|upper }}"
    tsm_client_node_domain: DOMAIN_1
    tsm_client_node_cloptset: LINUX_SERVERS
    tsm_client_node_schedule: SCHEDULE_23H
```

License
-------

GPLv3


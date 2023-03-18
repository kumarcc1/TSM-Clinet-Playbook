#!/bin/bash

# Command used to validate the changes done by the role
VERIFY_CMD='sudo netstat -tlnp |grep dsmc'

# Verify Ansible is available
if ! which ansible-playbook >/dev/null; then
    echo "You must first setup Ansible environment:"
    echo "source ~/dev/ansible/hacking/env-setup"
    exit 1
fi

######################################################################

quit() {
    # Remove temporary created symlink
    if [ "x$SYMLINK_CREATED" == "x1" ]; then
        rm -f test.yml
        SYMLINK_CREATED=0
        read -p "* Press a key to continue to next play." -n1 -r
    fi
    exit $1
}
trap quit ABRT EXIT HUP INT QUIT

######################################################################

# If we got several plays (test*.yml) then iterate each of them
if [ -z $1 ]; then
    if [ -s test*1*.yml ]; then
        for f in test[0-9]*.yml; do
            $0 $f
        done
        quit
    fi
else
    SYMLINK_CREATED=1
    ln -sf $1 test.yml
fi

######################################################################

# Syntax check Ansible
echo "Check Ansible syntax..."
ansible-playbook -i 'localhost,' test.yml --syntax-check || quit 1

######################################################################

# Create VMs:
echo "Create Vagrant VMs..."
vagrant up --no-provision || quit 1

######################################################################

# Provision them:
# NOTE: Force locale until this bug is fixed:
# https://github.com/ansible/ansible/issues/11055
echo "* Run Ansible..."
LC_ALL=en_US.UTF-8 vagrant provision || quit 1

######################################################################

echo "* Verify we got what we expected..."
verification_failed=0
for vm in $(vagrant status |awk '/ running \(/ { print $1 }'); do
    echo -n "- $vm: "
    if ! LC_ALL=en_US.UTF-8 vagrant ssh $vm -c "${VERIFY_CMD}"; then
        verification_failed=1
    fi
    if [ $verification_failed -eq 1 ]; then
        echo "* Verification FAILED! VMs are kept and NOT destroyed."
        quit 1
    fi
done

######################################################################

echo "* Verify idempotency..."
# Run again to verify idempotence:
LC_ALL=en_US.UTF-8 vagrant provision \
    | grep 'changed=0.*failed=0' && IDEMPOTENCE_PASS=1 || IDEMPOTENCE_PASS=0

if [ $IDEMPOTENCE_PASS -eq 1 ]; then
    echo "* Idempotence test passed."
    read -p "** Shall I destroy VMs? [y/N] " -n1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        vagrant destroy -f
    else
        echo "** Don't forget to do it yourself: vagrant destroy -f"
    fi
    quit 0
else
    echo "* Idempotence test FAILED!"
    echo "** VMs are kept and NOT destroyed."
    quit 1
fi

# Manually:
# vagrant ssh-config > /tmp/ansible_ssh_temp
# export ANSIBLE_SSH_ARGS="-F /tmp/ansible_ssh_temp"
# MYHOST=centos-7
# ansible-playbook test.yml -i "$MYHOST," --sudo

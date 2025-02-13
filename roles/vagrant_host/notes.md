# vagrant_host role notes

Need to convert the install steps [here](https://developer.hashicorp.com/vagrant/downloads#linux) into ansible

```sh
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant
```

1. get gpg key: [ansible.builtin.uri](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
2. add gpg key to the keyring [ansible.builtin.apt_key](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/apt_key_module.html) - does optionally download it and that could save the step above
3. ..? add the sources list to the apt repo directory /etc/apt/sources.list.d

trying to find a replacement for the lsb_release portion above, looks like it might be somewhere in here:

```txt
jac494@toyserver:~/Projects/blinkingboxes_home_ansible
$ ansible all -i inventory.yaml --key-file ~/.ssh/ansiblekey -m ansible.builtin.setup | grep -A5 "ansible_lsb"
        "ansible_lsb": {},
        "ansible_lvm": "N/A",
        "ansible_machine": "x86_64",
        "ansible_machine_id": "7177dd30fa81435d987c3875656c0163",
        "ansible_memfree_mb": 435,
        "ansible_memory_mb": {
[WARNING]: Platform linux on host toyserver is using the discovered Python
interpreter at /usr/bin/python3.12, but future installation of another Python
interpreter could change the meaning of that path. See
https://docs.ansible.com/ansible-
core/2.16/reference_appendices/interpreter_discovery.html for more information.
--
        "ansible_lsb": {
            "codename": "wilma",
            "description": "Linux Mint 22",
            "id": "Linuxmint",
            "major_release": "22",
            "release": "22"
```

## Get gpg key and add to keyring


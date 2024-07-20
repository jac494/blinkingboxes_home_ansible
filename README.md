# home.blinkingboxes.net

Documentation, scratch notes, configurations, and other things for the home domain for blinkingboxes.net

## General Overview

### Network

* IPv4 space: 10.255.0.0/24
* router: 10.255.0.1
* dhcp
  * server == router == 10.255.0.1
  * range start: 10.255.0.100
  * range end: 10.255.0.254
  * static leases:
    * **hp-laptop** 2c:59:e5:ba:21:c9 10.255.0.128
    * **hpsff1** 18:60:24:eb:03:b7 10.255.0.103
    * **hpsff2** n/a n/a
    * **ps5** 2c:9e:00:0f:63:21 10.255.0.245

### Physical Infra Systems

* hp-laptop
* hpsff1
* hpsff2 (needs to be sent out for RMA as of 20230625)
* EdgeRouterX
* WAP..?

## Ansible

* my goal here is to at least get one role set up as my user where my core stuff I use everywhere is installed...
  * git installed and configured
    * can I pull down my dotfiles repo and run the install script?
  * zsh installed and set as the shell
  * oh-my-zsh installed and configured
  * docker? yeah why not

I'm following along with the [ansible "Getting Started" tutorial](https://docs.ansible.com/ansible/latest/getting_started/index.html) but it took some extra steps when I got to Step 4: Set up SSH connections: I created a new key pair first using `ssh-keygen -t rsa -b 2048 -f ansiblekey -C "ansible mgmt"` then I was able to follow the steps and make sure that the `authorized_keys` file was present on all of the hosts in the inventory (at first located in `/etc/ansible/hosts` file but then relocated to `inventory.yaml` in this same directory). One thing I did was make the private key file passwordless, and an option moving forward would be to use ssh-agent and add that key to the agent on the ansible control node so that it _does_ have a password but that password doesn't have to be entered. This is a thing to look at for the future when I'm either on a network that needs higher security standards or if I am using a different overall architecture for my home network that needs to be battened down (e.g. extending out into cloud providers and connections outside of my immediate physical network here).

```txt
[  9:10AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✔) ]
 $ ansible all --key-file ~/.ssh/ansiblekey -m ping
10.255.0.128 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
10.255.0.103 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

```txt
# ROUND TWO AFTER NEW INVENTORY FILE

[  9:15AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
 $ ansible all -i inventory.yaml -m ping --key-file ~/.ssh/ansiblekey
hp-laptop | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
hpsff1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

Added task "Ensure ZSH is installed" which requires sudo, so passing in cli switch `--ask-become-pass` to avoid putting it in the inventory file; alternatively could have used the `-K` switch. There are options for providing it in an encrypted file but I'm not going to do that for now

Currently I have the following inventory file which does some "hello world" stuff and then installs the basic software packages that I always use on every system

```yaml
- name: My first play
  hosts: all
  tasks:
   - name: Ping my hosts
     ansible.builtin.ping:
   - name: Print message
     ansible.builtin.debug:
       msg: Hello world
   - name: Install base jac494 packages and ensure latest
     ansible.builtin.dnf:
       name: "{{ list_of_packages }}"
       state: latest
     become: true
     vars:
       list_of_packages:
        - zsh
        - git
        - python3
        - python3-pip
        - tmux
        - gdb
```

Next steps:

* make sure the projects directory exists:
  * `/home/jac494/Projects`
* run some basic commands such as
  * `git clone https://github.com/jac494/dotfiles.git` into /home/jac494/dotfiles directory
  * as user jac494, execute `~/dotfiles/install.sh`
* maybe make sure my jac494 user is set and all the things
  * `user --groups=wheel --name=jac494 --password=$y$j9T$pI73iJWUFwMS.GVhsRLgAq2m$twMgJaoXpB4soEn5TvWdxZ.8lu.WeafwYB.PqEoH5J2 --iscrypted --gecos="jac494"`

Final update for the day 20230625:

inventory.yaml

```yaml
fedoramachines:
  hosts:
    hp-laptop:
      ansible_host: 10.255.0.128
    hpsff1:
      ansible_host: 10.255.0.103
```

playbook.yaml

```yaml
- name: My first play
  hosts: all
  tasks:
   - name: Ping my hosts
     ansible.builtin.ping:
   - name: Print message
     ansible.builtin.debug:
       msg: Hello world
   - name: Install base jac494 packages and ensure latest
     ansible.builtin.dnf:
       name: "{{ list_of_packages }}"
       state: latest
     become: true
     vars:
       list_of_packages:
        - zsh
        - git
        - python3
        - python3-pip
        - tmux
        - gdb
   - name: make Projects directory for jac494
     ansible.builtin.file:
       path: /home/jac494/Projects
       state: directory
       mode: '0755'
   - name: make Projects/dotfiles directory for jac494
     ansible.builtin.file:
       path: /home/jac494/Projects/dotfiles
       state: directory
       mode: '0755'
   - name: clone jac494 dotfiles
     ansible.builtin.git:
       repo: https://github.com/jac494/dotfiles.git
       dest: /home/jac494/Projects/dotfiles
   - name: create dotfiles symlinks
     ansible.builtin.file:
       src: "/home/jac494/Projects/dotfiles/configs/{{ item.src }}"
       dest: "/home/jac494/{{ item.dest }}"
     loop:
       - { src: zshrc, dest: .zshrc }
       - { src: tmux.conf, dest: .tmux.conf }
       - { src: vimrc, dest: .vimrc }
       - { src: gdbinit, dest: .gdbinit }
       - { src: gitconfig, dest: .gitconfig }
   - name: create vim cache directory
     ansible.builtin.file:
       path: /home/jac494/.cache/vim
       state: directory
       mode: '0755'
   - name: make sure zsh is set as jac494 shell
     ansible.builtin.user:
       name: jac494
       shell: /usr/bin/zsh
     become: true
```

Example run:

```sh
cd ~/Projects/drew_dev/home.blinkingboxes.net && \
ansible-playbook \
  -i inventory.yaml \
  --key-file ~/.ssh/ansiblekey \
  --ask-become-pass \
  my_first_playbook.yaml
```

```txt
[  5:00PM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
 $ ansible-playbook -i inventory.yaml --key-file ~/.ssh/ansiblekey --ask-become-pass my_first_playbook.yaml
BECOME password: 

PLAY [My first play] ******************************************************************

TASK [Gathering Facts] ****************************************************************
ok: [hpsff1]
ok: [hp-laptop]

TASK [Ping my hosts] ******************************************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [Print message] ******************************************************************
ok: [hp-laptop] => {
    "msg": "Hello world"
}
ok: [hpsff1] => {
    "msg": "Hello world"
}

TASK [Install base jac494 packages and ensure latest] *********************************
ok: [hpsff1]
ok: [hp-laptop]

TASK [make Projects directory for jac494] *********************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [make Projects/dotfiles directory for jac494] ************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [clone jac494 dotfiles] **********************************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [create dotfiles symlinks] *******************************************************
ok: [hp-laptop] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hpsff1] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hp-laptop] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hp-laptop] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hpsff1] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hp-laptop] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hpsff1] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hp-laptop] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})
ok: [hpsff1] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hpsff1] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})

TASK [create vim cache directory] *****************************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [make sure zsh is set as jac494 shell] *******************************************
ok: [hp-laptop]
changed: [hpsff1]

PLAY RECAP ****************************************************************************
hp-laptop                  : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
hpsff1                     : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

## 20230701

Just installed fedora workstation 38 on a vm, set up the jac494 user and put the authorized_keys file on to let ansible manage through ssh. Mostly worked, but when it got to the step of syncing dotfiles and creating symlinks something failed:

```txt
[ 10:08AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
 $ ansible-playbook -i inventory.yaml --key-file ~/.ssh/ansiblekey --ask-become-pass my_first_playbook.yaml
BECOME password: 

PLAY [My first play] ***********************************************************

TASK [Gathering Facts] *********************************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [Ping my hosts] ***********************************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [Print message] ***********************************************************
ok: [hp-laptop] => {
    "msg": "Hello world"
}
ok: [hpsff1] => {
    "msg": "Hello world"
}
ok: [F38WS_001] => {
    "msg": "Hello world"
}

TASK [Install base jac494 packages and ensure latest] **************************
changed: [hpsff1]
changed: [hp-laptop]
changed: [F38WS_001]

TASK [make Projects directory for jac494] **************************************
ok: [hp-laptop]
ok: [hpsff1]
changed: [F38WS_001]

TASK [make Projects/dotfiles directory for jac494] *****************************
ok: [hpsff1]
ok: [hp-laptop]
changed: [F38WS_001]

TASK [clone jac494 dotfiles] ***************************************************
ok: [hpsff1]
ok: [hp-laptop]
changed: [F38WS_001]

TASK [create dotfiles symlinks] ************************************************
ok: [hp-laptop] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hpsff1] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hpsff1] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hp-laptop] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hpsff1] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hp-laptop] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hpsff1] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hp-laptop] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hpsff1] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})
ok: [hp-laptop] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})
failed: [F38WS_001] (item={'src': 'zshrc', 'dest': '.zshrc'}) => {"ansible_loop_var": "item", "changed": false, "item": {"dest": ".zshrc", "src": "zshrc"}, "msg": "src option requires state to be 'link' or 'hard'", "path": "/home/jac494/.zshrc"}
failed: [F38WS_001] (item={'src': 'tmux.conf', 'dest': '.tmux.conf'}) => {"ansible_loop_var": "item", "changed": false, "item": {"dest": ".tmux.conf", "src": "tmux.conf"}, "msg": "src option requires state to be 'link' or 'hard'", "path": "/home/jac494/.tmux.conf"}
failed: [F38WS_001] (item={'src': 'vimrc', 'dest': '.vimrc'}) => {"ansible_loop_var": "item", "changed": false, "item": {"dest": ".vimrc", "src": "vimrc"}, "msg": "src option requires state to be 'link' or 'hard'", "path": "/home/jac494/.vimrc"}
failed: [F38WS_001] (item={'src': 'gdbinit', 'dest': '.gdbinit'}) => {"ansible_loop_var": "item", "changed": false, "item": {"dest": ".gdbinit", "src": "gdbinit"}, "msg": "src option requires state to be 'link' or 'hard'", "path": "/home/jac494/.gdbinit"}
failed: [F38WS_001] (item={'src': 'gitconfig', 'dest': '.gitconfig'}) => {"ansible_loop_var": "item", "changed": false, "item": {"dest": ".gitconfig", "src": "gitconfig"}, "msg": "src option requires state to be 'link' or 'hard'", "path": "/home/jac494/.gitconfig"}

TASK [create vim cache directory] **********************************************
ok: [hp-laptop]
ok: [hpsff1]

TASK [make sure zsh is set as jac494 shell] ************************************
ok: [hpsff1]
ok: [hp-laptop]

PLAY RECAP *********************************************************************
F38WS_001                  : ok=7    changed=4    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   
hp-laptop                  : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
hpsff1                     : ok=10   changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[ 10:11AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
```

Ok that worked, assuming it was ok before because the links existed so the path to "create a symlink" was never followed

```txt
[ 10:15AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
 $ ansible-playbook -i inventory.yaml --key-file ~/.ssh/ansiblekey --ask-become-pass my_first_playbook.yaml
BECOME password: 

PLAY [My first play] ***********************************************************

TASK [Gathering Facts] *********************************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [Ping my hosts] ***********************************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [Print message] ***********************************************************
ok: [hp-laptop] => {
    "msg": "Hello world"
}
ok: [hpsff1] => {
    "msg": "Hello world"
}
ok: [F38WS_001] => {
    "msg": "Hello world"
}

TASK [Install base jac494 packages and ensure latest] **************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [make Projects directory for jac494] **************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [make Projects/dotfiles directory for jac494] *****************************
ok: [hp-laptop]
ok: [hpsff1]
ok: [F38WS_001]

TASK [clone jac494 dotfiles] ***************************************************
ok: [hpsff1]
ok: [hp-laptop]
ok: [F38WS_001]

TASK [create dotfiles symlinks] ************************************************
ok: [hpsff1] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hp-laptop] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hpsff1] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hp-laptop] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
changed: [F38WS_001] => (item={'src': 'zshrc', 'dest': '.zshrc'})
ok: [hpsff1] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hp-laptop] => (item={'src': 'vimrc', 'dest': '.vimrc'})
ok: [hpsff1] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hp-laptop] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
ok: [hpsff1] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})
changed: [F38WS_001] => (item={'src': 'tmux.conf', 'dest': '.tmux.conf'})
ok: [hp-laptop] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})
changed: [F38WS_001] => (item={'src': 'vimrc', 'dest': '.vimrc'})
changed: [F38WS_001] => (item={'src': 'gdbinit', 'dest': '.gdbinit'})
changed: [F38WS_001] => (item={'src': 'gitconfig', 'dest': '.gitconfig'})

TASK [create vim cache directory] **********************************************
ok: [hp-laptop]
ok: [hpsff1]
changed: [F38WS_001]

TASK [make sure zsh is set as jac494 shell] ************************************
ok: [hpsff1]
ok: [hp-laptop]
changed: [F38WS_001]

PLAY RECAP *********************************************************************
F38WS_001                  : ok=10   changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
hp-laptop                  : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
hpsff1                     : ok=10   changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[ 10:16AM ]  [ jac494@hp-laptop:~/Projects/drew_dev/home.blinkingboxes.net(main✗) ]
```

I still had to go in and manually install zsh and then re-run the dotfiles/install.sh script (not sure if that last step was actually required but it did work)

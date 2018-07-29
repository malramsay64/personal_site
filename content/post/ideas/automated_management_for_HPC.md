+++
title = "Automated Management of HPC Environments"
date = "2018-03-21"

draft = true
math = true
highlight = true
+++

Research Software, particularly that you are writing for a specific purpose changes rapidly.
- new functionality
- bug fixes

Managing these versions can be difficult
- Can have many different computers that need updating
    - local machine
    - small test server
    - faculty HPC
    - University HPC
    - National HPC
- How do you keep everything up to date with minimal effort
    - managing updates is typically slow and tedious
        - copy pasting commands you never remember from some website
    - download, compile, install
    - How do I compile this thing

- Typically with these shared systems you don't have root access
    - distribution package managers don't work
    - lots of compiling from source into non-standard locations
    - Conda

- There are a number of tools which make this possible.
    - SaltStack, Puppet
        - Hardcore devops tools which require a daemon running on each of the hosts
        - Requires manual setup on the host
        - Opening additional ports for communication
    - Ansible
        - Running over SSH connection
        - Huge library of user programs to tap into
        - Highly configurable
        - Problem is root access is assumed
            - installation of dependencies using package managers
            - default installation as system user
            - few packages for the management of virtualenvs 
                - end up using shell commands for intended result
            - complicated setup of directory structure and tasks
        - when you end up having to modify everything and either run shell commands or write your
        own modules, I am not using the full power of Ansible.
    - Fabric
        - Library for running shell commands on remote hosts
        - Fabric 2.0 is a remote version of Invoke
            - uses invoke for the running of the shell commands
            - provides a layer for simple use with remote hosts
        - uses ssh_config for configuration
            - if you have gone to the effort of creating an ssh host you can run commands on the
            host
            - no additional specific configuration required
        - Uses shell commands for everything
            - This removes the complications of translating shell commands to some other paradigm.
            - An extension of what you are already doing manually.
        - simple interface
        - adaptability
            - run as much or as little as you like

- Right tool for the job
    - I still use ansible for managing things like nginx configurations
        - nicer interface, default values are useful
        - Also use fabric to keep my dotfiles in sync.
            - yes there are other specific methods but this works for me.

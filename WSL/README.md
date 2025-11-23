# How to install WSL
### Install WSL
Open PowerShell
```
wsl --install
```

or if you prefer to specify distribution
```
wsl --install -d Ubuntu
```

then set username and password for your default user.

### List installed distibutions
```
wsl --list -v
```

### Check Ubuntu version
Run on Ubuntu
```
lsb_release -a
```

### Uninstall WSL
```
wsl --unregister Ubuntu
wsl --uninstall 
```

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
Run in Ubuntu
```
lsb_release -a
```

### Open Windows Media Explorer window
Run in Ubuntu
```
explorer.exe
```

### Uninstall WSL
Run in PowerShell
```
wsl --unregister Ubuntu
wsl --uninstall 
```

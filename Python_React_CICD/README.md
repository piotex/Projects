# Python & React CICD Project

This project provides a comprehensive guide to setting up a **Continuous Integration/Continuous Deployment (CICD)** pipeline for a Python and React application. The guide is broken down into several key sections, covering everything from initial server setup to automated deployments using various DevOps tools.

---

## 1. Server - Virtual Machine Setup in VirtualBox 💻

This section details the precise, step-by-step process of creating and configuring a virtual machine (VM) in **Oracle VM VirtualBox**. This VM will serve as our development and deployment environment.

### 1.1. Preparation

First, you need to download the necessary software:

* **CentOS Stream 10 ISO:** Download the `x86_64` ISO image from the official CentOS website.
* **Oracle VirtualBox:** Download and install the latest version for your operating system.

### 1.2. Configure Host-Only Adapter (if absent)

To allow the host machine to communicate with the VM, we need to set up a dedicated private network.

1.  Open VirtualBox, go to **File > Tools > Network Manager**.
2.  Select **Host-only Networks** and add a new one if it doesn't exist.
3.  Configure the settings as follows:
    * **Adapter Tab:**
        * **IPv4 Address:** `192.168.56.1`
        * **IPv4 Network Mask:** `255.255.255.0`
    * **DHCP Server Tab:**
        * Enable **Server**.
        * **Server Address:** `192.168.56.100`
        * **Server Mask:** `255.255.255.0`
        * **Lower Address Bound:** `192.168.56.101`
        * **Upper Address Bound:** `192.168.56.254`

After configuring the adapter, **reboot your machine** to ensure the changes take effect.

### 1.3. VM Creation

Now, let's create the virtual machine.

1.  In VirtualBox, go to **Machine > New**.
2.  **Name and Operation System:**
    * **Name:** `DevOps_Server`
    * **ISO Image:** Select the downloaded CentOS Stream 10 ISO.
    * **Type:** `Linux`
    * **Version:** `Red Hat (64-bit)`
    * Check `Skip Unattended Installation`.
3.  **Hardware:**
    * **Base Memory (RAM):** `8192 MB` (8 GB)
    * **Processors:** `4`
4.  **Hard Disk:**
    * **Create a Virtual Hard Disk Now**.
    * **File Location:** Set it to your desired folder.
    * **Size:** `80 GB`

### 1.4. Network Setup in VirtualBox

Before starting the installation, configure the network adapters for the VM.

1.  Right-click on the `DevOps_Server` VM and select **Settings > Network**.
2.  **Adapter 1:** Leave this enabled and set to **NAT**. This provides internet access for the VM.
3.  **Adapter 2:** Enable this adapter and set it to **Host-only Adapter**. This allows communication with the host machine.

### 1.5. CentOS Installation and Network Configuration

Start the VM to begin the CentOS installation process.

1.  Click **Start** to run the VM and select **Install CentOS Stream 10**.
2.  Choose your preferred language for the installation (**English** is recommended).
3.  On the **Installation Summary** screen, configure the following:
    * **Keyboard:** `English`
    * **Language Support:** `English`
    * **Time & Date:** Select your time zone, e.g., `Europe/Warsaw`.
    * **Installation Source:** The system should auto-detect the downloaded ISO.
    * **Software Selection:** Choose `Server`.
    * **Installation Destination:** Select the 80 GB disk.
4.  Configure the **Network & Host Name**:
    * Enable the `enp0s3` interface to get a dynamic IP address via NAT.
    * Select the **`enp0s8`** interface (this is your Host-only adapter).
    * Click **Configure** then IPv4 Settings, select **Manual** and set a **Static IP address**:
        * **Address:** `192.168.56.101`
        * **Netmask:** `255.255.255.0`
        * **Gateway:** `192.168.56.1`
        * **DNS:** `8.8.8.8`
5.  **User Settings:**
    * Set the **Root Password** (or choose to disable it).
    * Create a new user, e.g., `peter`, and set a strong password.
6.  Click **Begin Installation**.
7.  Once the installation is complete, click **Reboot System**.

---
### 1.6. System Update and SSH Connection

Once the VM has rebooted, log in and perform a system update and test your SSH connection.

1.  **Update Packages:** Run the following commands to update the kernel and packages.
    ```bash
    sudo dnf update -y
    ```
2.  **Check Versions:** Verify the installed kernel version.
    ```bash
    uname -r
    ```
3.  **Connect via SSH:** From your host machine, you can now connect to the VM.
    ```bash
    ssh peter@192.168.56.101
    ```
    If you encounter a `REMOTE HOST IDENTIFICATION HAS CHANGED` error, you can fix it by removing the old key from your `known_hosts` file.
    ```bash
    ssh-keygen -f '/home/peter/.ssh/known_hosts' -R '192.168.56.101'
    ```

### 1.7. Final Step: Snapshot

To avoid repeating these steps, it's highly recommended to save the machine state.

1.  In VirtualBox, go to **Machine > Take Snapshot**.
2.  Name the snapshot (e.g., `Initial Setup`) and provide a brief description.

This completes the foundational setup for our DevOps server.

---

## 2. Linux - Most Important Commands 🐧

This section provides a comprehensive cheat sheet of essential Linux commands that are fundamental for navigating, managing, and configuring your server.

### File and Directory Management

| Command | Description and Examples |
| --- | --- |
| **`ls`** | Lists the contents of the current directory. <br> `ls -l` - Displays a detailed list of files and directories (long format). <br> `ls -a` - Shows all files, including hidden ones. <br> `ls -h` - Displays file sizes in a human-readable format. <br> `ls -lS` - Lists files in long format, sorted by their size in descending order. <br> `ls -lt` - Lists files in long format, sorted by their last modification time, newest first. <br> `ls -lr` - Reverses the sorting order. <br> `ls -F` - Appends a character to entries to indicate their type: `*` for executables, `/` for directories, `@` for symbolic links. |
| **`cd`** | Changes the current directory. <br> `cd Documents` - Changes to the "Documents" directory. <br> `cd ..` - Goes to the parent directory. <br> `cd ~` or `cd` - Navigates to the user's home directory. |
| **`pwd`** | Prints the full path to the current working directory, e.g., `/home/user/Documents`. |
| **`mkdir`** | Creates a new directory. <br> `mkdir NewDirectory` - Creates a directory named "NewDirectory". <br> `mkdir -p Project/Phase1` - Creates "Project" and a sub-directory "Phase1" within it, if they don't already exist. <br> `mkdir -m 700 tests` - Sets the permissions (mode) for the newly created directory. |
| **`cp`** | Copies files and directories. <br> `cp source.txt destination.txt` - Copies `source.txt` to `destination.txt`. <br> `cp file.txt /user/Documents` - Copies `file.txt` to the "Documents" directory. <br> `cp -r Directory1 Directory2` - Copies an entire directory `Directory1` (including its contents) to `Directory2`. <br> `cp -v Directory1 Directory2` - Displays the name of each file as it's being copied. <br> `cp -p Directory1 Directory2` - Copies the file while maintaining the same permissions and modification times. |
| **`scp`** | Securely copies files between hosts on a network. <br> `scp source.txt user@remotehost.com:/home/user/documents/` <br> `-r` - Used to copy entire directories. <br> `-p` - Preserves modification times, access times, and permissions. <br> `-C` - Enables compression during the transfer. <br> `-i ~/.ssh/my_rsa_key` - Specifies the path to a private key file for authentication. |
| **`rsync`** | A more advanced tool for file synchronization and copying. <br> `rsync -avz --progress -e ssh /local/path/file.txt user@remote:/remote/path/` <br> `-a` - Archive mode (preserves permissions, timestamps, etc.). <br> `-v` - Verbose mode. <br> `-z` - Compresses data during transfer. <br> `--progress` - Displays a progress bar. |
| **`mv`** | Moves or renames files and directories. <br> `mv old_file.txt new_file.txt` - Renames `old_file.txt` to `new_file.txt`. <br> `mv file.txt /home/user/Backup` - Moves `file.txt` to the "Backup" directory. |
| **`rm`** | Removes files or directories. <br> `rm file.txt` - Deletes `file.txt`. <br> `rm -r MyDirectory` - Removes the directory `MyDirectory` and all its contents (use with caution!). <br> `rm -f MyDirectory` - Removes files without prompting for confirmation. |
| **`cat`** | Displays the content of a file. <br> `cat file.txt` - Displays the entire content of `file.txt`. <br> `cat file1.txt file2.txt > combined.txt` - Concatenates `file1.txt` and `file2.txt` into `combined.txt`. |
| **`touch`** | Creates a new, empty file, or updates the timestamp of an existing one. <br> `touch new_empty_file.txt` - Creates a new, empty file. |

### Searching and Filtering

| Command | Description and Examples |
| --- | --- |
| **`find`** | Searches for files and directories. <br> `find . -name "report.pdf"` - Searches for files named "report.pdf" in the current directory and its subdirectories. <br> `find /home/user -type d -name "Projects*"` - Searches for directories whose names start with "Projects". <br> `-type f`: regular file. <br> `-type d`: directory. |
| **`grep`** | Searches for patterns within files. <br> `grep "error" logs.txt` - Searches for lines containing "error" in `logs.txt`. <br> `ls -l | grep ".txt"` - Filters the output of `ls -l` to show only files with the `.txt` extension. |

### System and Process Information

| Command | Description and Examples |
| --- | --- |
| **`ps`** | Displays currently running processes. <br> `ps -aux` - Displays all running processes for all users. <br> `ps -ef` - Shows processes in a tree format. |
| **`top`** | Launches an interactive process monitor that updates in real-time. <br> `top -d 1` - Sets the refresh interval to 1 second. <br> `top -o %MEM` - Sorts processes by memory usage. |
| **`df`** | Displays information about free disk space. <br> `df -h` - Displays information in a human-readable format. |
| **`du`** | Displays disk usage for files and directories. <br> `du -sh` - Displays the total size of the current directory. <br> `du -h --max-depth=1 .` - Shows the total size of the current directory and its immediate subdirectories. |
| **`free`** | Displays information about RAM usage. <br> `free -h` - Displays usage in a human-readable format. |
| **`uname`** | Displays system information. <br> `uname -a` - Displays all system info (kernel name, version, architecture, etc.). |
| **`hostname`** | Shows the computer's hostname. |
| **`who`** | Lists users currently logged into the system. |
| **`whoami`** | Prints the current user's effective username. |

### Permissions Management

| Command | Description and Examples |
| --- | --- |
| **`chmod`** | Changes file permissions. <br> `chmod 711 script.sh` - Gives `script.sh` owner permissions (read, write, execute) and read-only for others. <br> `chmod +x script.sh` - Grants execute permissions to `script.sh`. |
| **`chown`** | Changes the owner and group of files. <br> `chown user file.txt` - Changes the owner of `file.txt` to `user`. <br> `chown user:group file.txt` - Changes the owner and group of `file.txt`. |

### Other Useful Commands

| Command | Description and Examples |
| --- | --- |
| **`echo`** | Prints text to the terminal. <br> `echo "Hello world!"` - Prints "Hello world!". <br> `echo "My username is: $USER"` - Displays the current user's name. |
| **`history`** | Shows a list of previously executed commands. <br> `!123` - Executes the command with the number 123 from history. |
| **`clear`** | Clears the terminal screen. |
| **`exit`** | Closes the current terminal session. |
| **`sudo`** | Executes a command with administrator privileges. <br> `sudo apt update` - Runs `apt update` with root privileges. <br> `sudo su` - Switches to the root user while maintaining the current working directory. <br> `sudo su -` - Switches to the root user and loads the root user's environment and home directory. |
| **`man`** | Displays the manual page for a command. <br> `man ls` - Displays the manual page for the `ls` command. (Press `q` to exit). |

---
<!--
## 3. Manual Server Configuration for HTTP Server 🌐

This part of the guide focuses on the **manual setup of an HTTP server** (e.g., Nginx or Apache) on the virtual machine. It includes instructions for:

* Installing the web server software.
* Configuring server blocks or virtual hosts to handle incoming web traffic.
* Setting up firewall rules to allow HTTP/HTTPS connections.

---

## 4. Ansible 🚀

This section introduces **Ansible**, a powerful open-source automation tool. It covers how to use Ansible to automate the server configuration and application deployment process. Topics include:

* Installing Ansible on the control machine.
* Writing **playbooks** to define the desired state of the server.
* Managing hosts and inventory.

---

## 5. Git ⚙️

Git is a fundamental tool for version control. This section explains how to use **Git** to manage your project's source code, collaborating with a team and tracking changes over time. Key topics include:

* Initializing a Git repository.
* Common commands (`add`, `commit`, `push`, `pull`).
* Branching and merging strategies.

---

## 6. Jenkins ✨

Finally, this section ties everything together with **Jenkins**, a leading automation server for building CICD pipelines. You will learn how to:

* Install and configure Jenkins.
* Create a new pipeline.
* Integrate your Git repository.
* Configure automated builds, tests, and deployments to your server.

ansible-playbook -i inventory/test.yml setup.yml -->

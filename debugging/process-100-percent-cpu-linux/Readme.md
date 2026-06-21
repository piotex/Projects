
## Connect to EC2
```bash
cd $HOME
cd debugging/process-100-percent-cpu-linux/terraform
PUBLIC_IP=$(terraform output -raw public_ip)     && echo $PUBLIC_IP

ssh -i /home/peter/github/S3CR3T\$/lab-key.pem ec2-user@$PUBLIC_IP
```


## Run CPU and RAM utilization
Healthcheck:
```bash
cd $HOME
cd debugging/process-100-percent-cpu-linux/terraform
PUBLIC_IP=$(terraform output -raw public_ip)     && echo $PUBLIC_IP
curl http://$PUBLIC_IP:5000/

# CPU intensive endpoint:
curl http://$PUBLIC_IP:5000/report
curl http://$PUBLIC_IP:5000/cpu
curl http://$PUBLIC_IP:5000/allocate
curl http://$PUBLIC_IP:5000/free
```


## Identify processes consuming CPU and memory
### Display all running processes
```bash
ps aux
ps aux --sort=-%cpu | head -5
ps aux --sort=-%mem | head -5
```
a - show processes for all users
u - user-oriented format (USER, %CPU, %MEM, etc.)
x - include processes without a controlling terminal (daemons, services)


### Real-time process monitoring
```bash
top -d1 -p 2134
top -H -p -f 2134
```
-d1 - refresh interval in seconds (live view every 1s)
-p - filter by specific PID
-H - show per-thread CPU usage (important for multi-threaded apps)


## Check parent-child chain
```bash
sudo dnf install -y psmisc
pstree -aps 2134
```
-a - show complete command-line arguments for each process
-p - display process IDs alongside process names
-s - print the process hierarchy up to the root (init/systemd)


### Interactive process viewer
```bash
sudo dnf install -y htop
htop -p 2134
```
-p - show only selected PID in htop


### System call tracing (strace)
```bash
sudo dnf install -y strace
sudo strace -p 2134
```
read / write / openat                   → file operations (disk I/O)
stat / lstat / fstat                    → file metadata checks
socket / connect / sendto / recvfrom    → network activity
poll / epoll_wait                       → waiting for events (I/O multiplexing)
nanosleep / clock_nanosleep             → intentional sleeping
futex                                   → thread synchronization (locks, GIL, waits)

### Python profiling (py-spy)
```bash
sudo dnf install -y python3-pip
python3 -m pip install --user py-spy
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

sudo ~/.local/bin/py-spy top --pid 2134             # CPU usage per function (jak top, ale dla Pythona)
sudo ~/.local/bin/py-spy dump  --pid 2134           # „snapshot stack trace” wszystkich wątków w danym momencie

sudo ~/.local/bin/py-spy record -o out.svg --pid 2134 --rate 100
scp -i /home/peter/github/S3CR3T\$/lab-key.pem  ec2-user@$PUBLIC_IP:~/out.svg  .
```
Alternatywy np. dla javy:
async-profiler              → asprof -d 30 -f flamegraph.html <PID>
jstack                      → jstack <pid>
Java Flight Recorder (JFR)  → jcmd <pid> JFR.start

Co wybrać w praktyce?
async-profiler              → chcesz szybko znaleźć CPU spike     
jstack                      → chcesz zobaczyć deadlock            
JFR                         → chcesz full diagnostykę produkcji   


### Quick memory snapshot
```bash
sudo pmap 2134 | tail -20

sudo pmap -x 2134 | head -n3
sudo pmap -x 2134 | sort -k3 -nr | head -5

sudo pmap -x 2134 | awk '
/total/ {
    printf "Size:         %.2f MB\n", $2/1024;
    printf "RSS (RAM):    %.2f MB\n", $3/1024;
    printf "Dirty (data): %.2f MB\n", $4/1024;
}'

sudo cat /proc/2134/smaps_rollup
```
-x  - extended view with: Kbytes, RSS, Dirty, Mapping



### Container resource usage
```bash
docker stats --no-stream
docker stats --no-stream --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### Container logs
```bash
docker logs -f cpu-app
```
-f - follow log stream (live output)


## Disk usage analysis
### Disk free space
```bash
df -h
```
-h - human readable format (GB/MB)

### Directory usage overview
```bash
sudo du -xhd1s /
```
-x - stay on one filesystem
-h - human readable
-d1 - depth level 1
-s - summary only




###  Przegląd systemu przed wejściem w konkretny proces
```bash
uptime              # load average 1/5/15 min
free -h             # ile RAM faktycznie zajęte/wolne/cache
vmstat 1 5          # CPU (us/sy/id/wa), swap, context switches w czasie
mpstat -P ALL 1     # obciążenie per-core (czy to jeden wątek dusi jeden rdzeń?)
iostat -xz 1        # czy to nie iowait udaje "100% CPU"?
```


###  Deskryptory plików i limity
```bash
sudo dnf install -y lsof
sudo lsof -p 2134 | wc -l        # liczba otwartych FD — leak?
cat /proc/2134/limits            # ulimit dla procesu
cat /proc/2134/status | grep -i ctxt   # voluntary/nonvoluntary context switches
pidstat -p 2134 1                # CPU/ctxsw/IO per proces w czasie
```


### Logi systemowe i OOM
```bash
sudo dmesg -T | grep -i -E "oom|kill"

journalctl -u <service> -f
sudo journalctl -u docker | tail -n 10

journalctl -k --since "10 min ago"   # sprawdzenie dziennika zdarzeń jądra (kernel logs) z ostatnich 10 minut
```

### Sieć
```bash
ss -tunap 
sudo nethogs        # ruch sieciowy per proces
sudo iftop
```









# OLD ==========================

## Test
```bash

# Investigation
top -d1                 # refresh each 1s
top -d1 -p 17678        # show only one process
top -H -p 17678         # każdy wątek z osobna
ps -fp 17678            # f == full format | show process snapshot

sudo dnf install -y htop
htop -p 17678  

ps aux
ps aux --sort=-%cpu | head -10
ps aux --sort=-%mem | head -10
ps -eo pid,ppid,%cpu,%mem,cmd --sort=-%cpu | head -10


sudo dnf install -y strace
# ===== strace =====================================
sudo strace -p 17678        # show system calls (wszystkie wywołania systemowe (syscalls))
                                # czy proces czyta plik
                                # czy robi request sieciowy
                                # czy czeka na dane
                                # czy śpi / blokuje się
                                # czy używa CPU w pętli

                                # wzorzec	                  ||    co oznacza
                                # ================================================
                                # read/openat	              ||    pliki
                                # socket/connect/send/recv  ||    sieć
                                # poll/epoll_wait	          ||    czekanie na event
                                # nanosleep/futex WAIT	    ||    śpi / sync
                                # powtarzające się syscalle	CPU loop


# ===== py-spy =====================================
sudo dnf install -y python3-pip
python3 -m pip install --user py-spy
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
sudo ~/.local/bin/py-spy top --pid 17678
              # Collecting samples from 'python main.py' (python v3.12.13)
              # Total Samples 600
              # GIL: 93.00%, Active: 400.00%, Threads: 5
              #   %Own   %Total  OwnTime  TotalTime  Function (filename) 
              # 400.00% 400.00%   24.00s    24.00s   is_prime (main.py)
              #   0.00% 400.00%   0.000s    24.00s   handle_one_request (http/server.py)
              #   0.00% 400.00%   0.000s    24.00s   wsgi_app (flask/app.py)


sudo ~/.local/bin/py-spy record -o profile.svg --pid 17678
scp -i /home/peter/github/S3CR3T\$/lab-key.pem  ec2-user@$PUBLIC_IP:~/profile.svg  .



sudo pmap 17678 | tail -20       # szybki snapshot RAM procesu
sudo pmap -x 17678
sudo pmap -d 17678
sudo pmap -x 17678 | awk '/total/ {printf "Total: %.2f MB\n", $2/1024}'
sudo pmap -x 17678 | awk '
/total/ {
    printf "Size:         %.2f MB\n", $2/1024;
    printf "RSS (RAM):    %.2f MB\n", $3/1024;
    printf "Dirty (data): %.2f MB\n", $4/1024;
}'


docker stats
docker stats --no-stream
docker stats --no-stream --format "table {{.Container}}\t{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
docker logs -f cpu-app


# TL;DR (najważniejsze 5 komend)
ps aux --sort=-%cpu | head -n7
top -H -p <PID>
docker stats
py-spy top --pid <PID>
pidstat -p <PID> 1
              
```


## Disk cleanup
```bash
df -h
sudo du -x -h -d1 / | sort -h
sudo du -xhd1 /var  | sort -h         # x - analise only '/' ignore /proc  ||| d1 = depth 1
sudo du -sh /var/lib/docker           # s - summary - total number



```






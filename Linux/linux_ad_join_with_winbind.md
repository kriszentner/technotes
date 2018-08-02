# Introduction
Winbind is a component of Samba and this guide effectively shows how to set up samba for domain joining.
The Samba project [recommends that you use Samba 4](https://github.com/samba-team/samba).
Ubuntu 12.04 - Comes with Samba 3. These seem to work, however Samba 4 may be more stable.  The samba 4 packages that come with 12.04 are 4.0.0~alpha18.
Ubuntu 14.04 - Comes with Samba 4 v4.1.6 by default.


# Install Winbind, kerberos and ntpd
```bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -q -y install winbind libpam-winbind krb5-user krb5-config libpam-krb5 ntp unscd
```
	
## Using systemd intsead of init.d
Note that winbindd and smbd will by default use the init.d system which has poor daemon monitoring. A better option is to use systemd which is trivial to convert to:
```bash
inits="smbd winbind"
for i in $inits;do
  rm -f /etc/init.d/$i
  rm -f /etc/rc*.d/$i
done
cat > /etc/systemd/system/smbd.service << EOF
[Unit]
Description=Samba SMB/CIFS server
[Service]
Restart=always
ExecStart=/usr/sbin/smbd -F
ExecReload=/bin/kill -HUP $MAINPID
[Install]
WantedBy=multi-user.target
EOF
cat > /etc/systemd/system/winbindd.service << EOF
[Unit]
Description=Samba Winbind daemon

[Service]
ExecStart=/usr/sbin/winbindd -F
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
daemons="smbd winbindd"
for i in daemons;do
  systemctl start $i
  systemctl enable $i
done
```
## System Configurations:

If you haven't yet, edit `/etc/hostname`, add just the machine name, not the domain.
	
Edit `/etc/ntp.conf` and change the server lines:
```
		server chicago.corp.contoso.com
		server chicago.corp.contoso.com
		server chicago.corp.contoso.com
		server chicago.corp.contoso.com
```
Start ntp, you can also check that it's running correctly (this command can take a minute initially):
```
# echo "lpeer"|ntpq
    remote       refid           st t when poll reach   delay   offset  jitter
==============================================================================
+dc1-chi-mr.13.c 10.0.0.72       3 u    7   64   77    7.500   -8.561  10.066
-dc4-chi.mr.15.c 172.14.162.124  4 u    5   64   77  141.674  -56.774  13.699
*dc2-chi-mr-14.c 10.0.6.169      3 u   31   64   77    6.333   -6.291   5.891
+dc3-chi-mr-06.c 10.0.160.214    4 u   26   64   77   25.914  -29.716   5.068
```

Edit `/etc/nsswitch.conf`
```
passwd:         compat winbind
group:          compat winbind
```
Edit /etc/hosts:
```
127.0.0.1       localhost.CHICAGO.CORP.contoso.com localhost.CHICAGO localhost 
127.0.1.1       <host-name>.CHICAGO.CORP.contoso.com <host-name>.CHICAGO <host-name>
```
	Edit /etc/krb5.conf (expand with plus if collapsed)
		[libdefaults]
		  ticket_lifetime = 24h
		  default_realm = CHICAGO.CORP.contoso.com
		  forwardable = true
		
		[realms]
		  CORP.contoso.com = {
		    kdc = corp.contoso.com
		    default_domain = CORP.contoso.com
		  }
		
		  PARIS.CORP.contoso.com = {
		    kdc = paris.corp.contoso.com
		    default_domain = CORP.contoso.com
		  }
		
		  TOKYO.CORP.contoso.com = {
		    kdc = tokyo.corp.contoso.com
		    default_domain = CORP.contoso.com
		  }
		
		  NEWYORK.CORP.contoso.com = {
		    kdc = newyork.corp.contoso.com
		    default_domain = CORP.contoso.com
		  }
		
		  CHICAGO.CORP.contoso.com = {
		    kdc = chicago.corp.contoso.com
		    default_domain = CORP.contoso.com
		  }
		
		[domain_realm]
		        .chicago = CHICAGO.CORP.contoso.com
		        .chicago.corp.contoso.com = CHICAGO.CORP.contoso.com
		
		#[kdc]
		#  profile = /etc/krb5kdc/kdc.conf
		
		[appdefaults]
		  pam = {
		    debug = false
		    ticket_lifetime = 36000
		    renew_lifetime = 36000
		    forwardable = true
		    krb4_convert = false
		  }
		
		[logging]
		  kdc = SYSLOG:INFO:DAEMON
		  kdc = FILE:/var/log/krb5kdc.log
		  admin_server = FILE:/var/log/kadmin.log
		  default = FILE:/var/log/krb5lib.log
		


	PAM
		Add this at the end of /etc/pam.d/common-session:
		# create homedir for new users 
		session required pam_mkhomedir.so skel=/etc/skel umask=0022


Configure Samba  
edit: `/etc/samba/smb.conf`
```
# Further doco is here
# https://www.samba.org/samba/docs/man/manpages/smb.conf.5.html
[global]
  # No .tld
  workgroup = CHICAGO
  # Active Directory System
  security = ADS
  # With .tld
  realm = CHICAGO.CORP.contoso.com
  # Just a member server
  domain master = No
  local master = No
  preferred master = No
  # Works both in samba 3.2 and 3.6 and 4.1
  idmap config * : backend = rid
  idmap config * : range =              900000000-999999999
  idmap config PARIS : backend = rid
  idmap config PARIS : range =         100000000-199999999
  idmap config BEIJING : backend = rid
  idmap config BEIJING : range =        200000000-299999999
  idmap config NEWYORK : backend = rid
  idmap config NEWYORK : range =   300000000-399999999
  idmap config DUBAI : backend = rid
  idmap config DUBAI : range =   400000000-499999999
  idmap config CHICAGO : backend = rid
  idmap config CHICAGO : range =        500000000-599999999
  idmap config SAOPAULO : backend = rid
  idmap config SAOPAULO : range =          600000000-699999999
  idmap config TOKYO : backend = rid
  idmap config TOKYO : range =          700000000-799999999
  idmap config JOHANNESBURG : backend = rid
  idmap config JOHANNESBURG : range =          800000000-899999999
  idmap cache time = 604800
  winbind cache time = 604800
  winbind enum users = No
  winbind enum groups = No
  # This way users log in with username instead of username@example.org
  winbind use default domain = No
  # Do not recursively descend into groups, it kills performance
  winbind nested groups = No
  winbind expand groups = 1
  winbind refresh tickets = Yes
  winbind offline logon = Yes
  winbind max clients = 1500
  winbind max domain connections = 50
  winbind separator = .
  winbind:ignore domains = MYTEST COSTOSOTEST XTEST
  # Disable printer support
  load printers = No
  printing = bsd
  printcap name = /dev/null
  disable spoolss = yes
  # Becomes /home/example/username
  template homedir = /home/%U
  # shell access
  template shell = /bin/bash
  client use spnego = Yes
  client ntlmv2 auth = Yes
  encrypt passwords = Yes
  restrict anonymous = 2
  log level = 2
  log file = /var/log/samba/samba.log
```
The above will force you to ssh in with DOMAIN.username. This is recommended because there are many domain accounts at Microsoft that can conflict with local accounts on Linux machines.

## Join the Domain
This shows how to include the password for scripting purposes. If by hand you can exclude the echo.
```bash
sudo echo "mypassword"|kinit alice@CHICAGO.CORP.CONTOSO.COM
```
To include the password you'd just use the below user%password with the net command:
```bash
sudo net ads join createcomputer=RnD/Research/FrotzCluster -k 
```
If your password has spaces you can use single quotes
```bash
sudo net ads join createcomputer=RnD/Research/FrotzCluster -k
	Using short domain name -- CHICAGO
	Joined 'MYHOST-TEST01' to realm 'chicago.corp.contoso.com'
```
You may get errors like the below with the join command. These will usually resolve themselves and aren't something to worry about. It takes about 5-10 minutes for things to sync after a reboot or domain join. Using auth before then you can get things like "group not found" errors:
```
DNS Update for MYHOST-TEST01.chicago.corp.contoso.com failed: ERROR_DNS_UPDATE_FAILED
DNS update failed!

kerberos_kinit_password MYHOST-TEST01$@CHICAGO.CORP.contoso.com failed: Preauthentication failed
DNS update failed: kinit failed: Preauthentication failed
```

```
sudo net ads dns register -U bob
	Successfully registered hostname with DNS
```

It can take up to an hour to propagate some of these changes. See the Administrative commands below to see if things are working. Sometimes a restart of winbind can get things working.

If you're having trouble joining the domain…stop. Active directory takes time to sync new and removed objects. 

Start Winbind and have it run at boot
```bash
service winbind start
update-rc.d winbind defaults
```
# Administrative Commands
You can use the below commands to see if you're on the domain and things are working. Remember these won't work immediately. Propagation takes time.


**`wbinfo`**  
wbinfo queries a running winbind daemon. If it's not running, you'll get not found errors.
`wbinfo --own-domain`
`wbinfo --all-domains`
`wbinfo --user-info=CHICAGO.CORP.contoso.com\\bob`

You can also use: 
```bash
id CHICAGO\\bob
```
Don't use these commands as suggested by some tutorials. They'll get ALL users from the domain and you don't want that:
```bash
wbinfo -u
```
**`net`**  
To use many of the net commands, you'll need a kerberos ticket (assuming you're an admin)
```bash
kinit yourusername@CHICAGO.CORP.contoso.com
```
```bash
# get domain info, including the computer object location and other AD details
net ads status 
```bash
```bash
# issue dynamic DNS update
net ads dns
```
# Caching
Using the idmap and winbind cache should be sufficient for winbind caching. You could use nscd, but it shouldn't be necessary. You can warm the cache by using the id command.

## Clearing the cache
Cleared all Winbind caches and flushed Net cache, remember to take a backup before deleting anything!

Stop the Winbind and Samba services:
```bash
service winbind stop
service smbd stop
```
Clear the Samba Net cache:
```bash
net cache flush
```
Delete the Winbind caches:
```bash
rm -f /var/lib/samba/*.tdb
rm -f /var/cache/samba/*.tdb
rm –f /var/lib/samba/group_mapping.ldb
```
Start the Samba and then Winbind services - Note: The order is important
```bash
service smbd start
service winbind start
```
Test it by trying to resolve a user.

Cache Files
Cache files are stored as tdb (Trivial DataBase files) in the following dirs:
```
/var/cache/samba
/var/lib/samba
```
An lsof on a winbind process can give you more specifics:
```
/run/samba/gencache_notrans.tdb
/run/samba/messages.tdb
/run/samba/serverid.tdb
/var/cache/samba/gencache.tdb
/var/cache/samba/netsamlogon_cache.tdb
/var/lib/samba/private/secrets.tdb
/var/lib/samba/winbindd_cache.tdb
```
likewise, the smb process also has its own different list of tdb caches it uses:
```
/run/samba/brlock.tdb
/run/samba/gencache_notrans.tdb
/run/samba/locking.tdb
/run/samba/messages.tdb
/run/samba/notify_index.tdb
/run/samba/notify.tdb
/run/samba/serverid.tdb
/run/samba/smbXsrv_open_global.tdb
/run/samba/smbXsrv_session_global.tdb
/run/samba/smbXsrv_tcon_global.tdb
/run/samba/smbXsrv_version_global.tdb
/var/cache/samba/gencache.tdb
/var/lib/samba/account_policy.tdb
/var/lib/samba/group_mapping.tdb
/var/lib/samba/private/passdb.tdb
/var/lib/samba/private/secrets.tdb
/var/lib/samba/registry.tdb
/var/lib/samba/share_info.tdb
```

A list of what they are is here:
https://www.samba.org/samba/docs/man/Samba-HOWTO-Collection/tdb.html

You can dump a tdb's contents with `tdbdump`
There's also tdbtool which lets you manipulate a tdb file.

## Discovering Group memberships:
these are about the same
```bash
getent group CHICAGO.ctsomembers
wbinfo --group-info=CHICAGO.ctsomembers
```



Mounting CIFS/Windows Shares
See the msr-winbind::user_mount chef recipe for automation.

Users mounting CIFS
For Ubuntu, you'll need the cifs-utils package
```bash
apt-get install cifs-utils
```
Also you'll want to set the following sysctls to get around an obscure bug with mounting using kerberos, and winbind `use default domain = No`.
```
echo "10000" > /proc/sys/kernel/keys/root_maxkeys
echo "1000000" > /proc/sys/kernel/keys/root_maxbytes
```
Create a file in /etc/sysctl.d/60-mountcifs-fix.conf:
```
kernel.keys.root_maxkeys = 10000
kernel.keys.root_maxbytes = 1000000
```
## Manually
To manually mount a windows share users just need to run mount -t cifs but again they must be sure to include the options `krb5,cruid=$(id -u ),uid=$(id -u),gid=$(id -g)` this will ensure that they are correctly authenticated and are able to read and write data.
So a manual mount command would look like:
```bash
sudo mount.cifs //MSR-DATA-FS02/Scratch/$(whoami|cut -d. -f2)  --verbose -o sec=krb5,cruid=$(id -u),uid=$(id -u),gid=$(id -g),vers=3.02
```
And with some sensible options
```bash
sudo mount.cifs //MSR-DATA-FS02/Scratch/$(whoami|cut -d. -f2) ~/scratch --verbose -o sec=krb5,cruid=$(id -u),uid=$(id -u),gid=$(id -g),nounix,serverino,mapposix,file_mode=0777,dir_mode=0777,noforceuid,noforcegid,vers=3.02
```
You can give users account to mount by writing the following file

`/etc/sudoers.d/mount`
```
Cmnd_Alias MOUNT_CMDS = /sbin/mount.cifs
ALL ALL=(ALL) NOPASSWD: MOUNT_CMDS
```


## Automount CIFS on user login
For Ubuntu, you'll need the libpam-mount, and cifs-utils packages
```bash
sudo apt-get install libpam-mount cifs-utils
```
This will put entries in `/etc/pam.d/common-auth` and `common-session`, and will create the file `/etc/security/pam_mount.conf.xml`
 
To enable this feature you need to uncomment the following line in `/etc/security/pam_mount.conf.xml`:

```xml
<luserconf name=".pam_mount.conf.xml" />
```
And you'll need to adjust the <mntoptions line:
```xml
<mntoptions allow="nosuid,nodev,loop,encryption,fsck,nonempty,allow_root,allow_other,sec,cruid,uid" />
```
For users to mount the "h" drive above, the following would be put in their `~/.pam_mount.conf.xml`
```xml
<pam_mount>
<volume user="*" fstype="cifs" server="myhost-test01" sgrp="domain users" path="userhomedrives$/%(USER).CHICAGO" mountpoint="~/h" options="sec=krb5,cruid=%(USERUID),uid=%(USERID),nodev,nosuid,vers=3.02" />
</pam_mount>
```
# Automount CIFS at boot
For this method, you'll need credentials stored unencrypted on disk since there is no SYSTEM account for linux, and using kerberos requires a ticket (which requires auth).
For Ubuntu, you'll need the cifs-utils package
```bash
apt-get install cifs-utils
```
You can use an fstab line like:
```bash
//servername/sharename  /media/windowsshare  cifs  username=msusername,password=mypassword,iocharset=utf8,sec=ntlm,vers=3.02  0  0
```
to hide the password you can do something like:
```bash
//servername/sharename /media/windowsshare cifs credentials=/home/ubuntuusername/.smbcredentials,iocharset=utf8,sec=ntlm,vers=3.02 0 0
```
And your creds file can contain:
```
username=username
password=mypassword
```
Be sure to chmod 400 the creds file to avoid non admins seeing it.


# Winbind Troubleshooting
## Is winbind running?
ps auxww|grep winbind

Can you start winbind, and does it run?

If not, what happens when you run: winbindd -I

Joining a domain (replace password below!):
If you see errors after the domain join, try ignoring them
most of the time the join works anyhow. Try testing with
an: id CHICAGO.username in about 10 mins. 
```bash
kdestroy
service smbd stop
 service nmbd stop
net cache flush
echo 'password'| kinit alice@CHICAGO.CORP.contoso.com
net ads join -k
service smbd start
service nmdb start
service nmbd start
service winbind start
```

Error messages:
This tends to resolve itself in about 10m or so
```
net ads testjoin
kerberos_kinit_password MYHOST01$@CHICAGO.CORP.contoso.com failed: Client not found in Kerberos database
kerberos_kinit_password MYHOST01$@CHICAGO.CORP.contoso.com failed: Client not found in Kerberos database
Join to domain is not valid: Improperly formed account name
```

# References
https://wiki.samba.org/index.php/Setup_a_Samba_AD_Member_Server  
https://www.samba.org/samba/docs/man/Samba-HOWTO-Collection/winbind.html  
http://wiki.centos.org/TipsAndTricks/WinbindADS  
https://help.ubuntu.com/community/ActiveDirectoryWinbindHowto  
[Samba source code at github](https://github.com/samba-team/samba)
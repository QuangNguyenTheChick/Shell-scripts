#!/bin/sh

echo "Would you like to install auto-configuration shell scripts ??"
read i
while true
do 
	case "$i" in
		[Yy]*)
			echo "----------		Which shell do you want to run ??		----------"
			echo "1: Install and update yum store Shell"
			echo "2: Network Interface Configuration(NIC) Automate Shell"
			echo "3: DHCP Configuration Automate Shell (NIC configuration required)"
			echo "4: File Transfer Protocol Configuration Automate Shell"
			echo "5: Samba Configuration Automate Shell"
			echo "6: Auto add user Shell"
			echo "7: Check all system information Shell"
			echo "0/exit: Quit script"
			read check
			case "$check" in
				"1")
					echo "Welcome to install and update shell, please wait......"
					yum install -y yum-skip-broken
					#yum update -y --skip-broken
					yum install -y epel-release
					yum install -y dhcp*
					yum install -y python-pip*
					yum install -y python-devel
					yum groupinstall -y 'development tools'
					yum install -y gparted*

					echo "Update complete !!! Please choose another case to configuration your system."
					;;

				"2") 
					echo "<------>		Welcome to Network Interface Configuration(NIC)		<------>"
					echo "Please input your IP for LAN connection:"
					read ip
					if ! [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
						echo "Your input ip is invalid, please re-type your IP:"
						echo "Your IP will like x.x.x.x (x=1~254)"
						read ip
					fi
					echo "Please input your Netmask for LAN connection:"
					read netmask
					if ! [[ $netmask =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
						echo "Your input netmask is invalid, please re-type your netmask:"
						echo "Your netmask will like 255.255.x.x (x=1~254)"
						read netmask
					fi
					IFACE=eth0
					IFACE1=eth1
					read MAC0 </sys/class/net/$IFACE/address
					read MAC1 </sys/class/net/$IFACE1/address
					sed -ie 's/eth0/WAN/g' /etc/udev/rules.d/70-persistent-net.rules
					sed -ie 's/eth1/LAN/g' /etc/udev/rules.d/70-persistent-net.rules
					echo "You can see your new NIC by typing 'vi /etc/udev/rules.d/70-persistent-net.rules' "
					echo 'DEVICE="WAN"							
					BOOTPROTO="dhcp"
					ONBOOT="yes"
					TYPE=Ethernet' > /etc/sysconfig/network-scripts/ifcfg-eth0
					echo "HWADDR=$MAC0 " >> /etc/sysconfig/network-scripts/ifcfg-eth0
					echo '
					DEVICE="LAN"
					BOOTPROTO="none"
					ONBOOT="yes"
					TYPE=Ethernet' > /etc/sysconfig/network-scripts/ifcfg-eth1
					echo "HWADDR=$MAC1
					IPADDR=$ip
					NETMASK=$netmask" >> /etc/sysconfig/network-scripts/ifcfg-eth1
					echo "domain localdomain 
					search localdomain 
					nameserver 8.8.8.8" > /etc/resolv.conf

					echo "Your NIC Configuration is done."
					echo "Restart must be done before continue, do you want to restart now ??"
					read q
					while true
					do
					case "$q" in
					[Yy]*)
							init 6
							;;
					[Nn]*)
							#Trở lại màn hình chính
							echo "Please restart main shell and choose another shell you want to run."
							echo "Warning: Not reboot your system may cause critical error on next shell"
							break
							;;
					*) 		
							echo "Wrong type, please re-type:"
							read q
							;;
					esac
					done
					;;

				"3") 
					echo "----------Welcome to auto configuration DHCP shell----------"
					echo "Warning: You must configuration you NIC before you use this shell"
						function	calculate_IP(){
							ip=$1; mask=$2
							IFS=. read -r i1 i2 i3 i4 <<< "$ip"
							IFS=. read -r m1 m2 m3 m4 <<< "$mask"

							echo "Network:   $((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))"
							echo "Broadcast: $((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$((i4 & m4 | 255-m4))"
							echo "First IP:  $((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))"
							echo "Last IP:   $((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))" 
							firstip=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))
							lastip=$((i1 & m1 | 255-m1)).$((i2 & m2 | 255-m2)).$((i3 & m3 | 255-m3)).$(((i4 & m4 | 255-m4)-1))
							network=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$((i4 & m4))
							option_routers=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))
							domain_name_servers=$((i1 & m1)).$((i2 & m2)).$((i3 & m3)).$(((i4 & m4)+1))
							temp=$((i1 & m1)).$((i2 & m2)).$((i3 & m3))
						}
						getip="$(ifconfig | grep -A 1 'LAN' | tail -1 | cut -d ':' -f 2 | cut -d ' ' -f 1)"
						netmask="$(ifconfig | grep -A 1 'LAN' | tail -1 | cut -d ':' -f 4 )"
						calculate_IP $getip $netmask
							echo "
							subnet $network netmask $netmask
							{		
									range $firstip $lastip;
									option domain-name-servers $option_routers, 8.8.8.8;
									option routers $domain_name_servers;
									default-lease-time 600;
									max-lease-time 7200;
								}" > /etc/dhcp/dhcpd.conf
					echo "-----You can change your dhcp configuration at /etc/dhcp/dhcpd.conf !!!-----"
					service dhcpd restart
					chkconfig dhcpd on
					echo "Your DHCP configuration is done."
					;;

				"4")
					echo "----------Welcome to auto configuration File Transfer Protocol(FTP) shell----------"
					yum install -y vsftp*
						sed -ie 's/anonymous_enable=YES/anonymous_enable=NO/g' /etc/vsftpd/vsftpd.conf
						sed -ie 's/#local_enable=YES/local_enable=YES/g'	 /etc/vsftpd/vsftpd.conf
						sed -ie 's/#chroot_local_user=YES/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf
						sed -ie 's/chroot_local_user=NO/chroot_local_user=YES/g' /etc/vsftpd/vsftpd.conf
						sed -ie 's/local_enable=NO/local_enable=YES/g'	 /etc/vsftpd/vsftpd.conf
						service vsftpd restart
						chkconfig vsftpd on
						setsebool -P ftp_home_dir on
						setsebool allow_ftpd_full_access on
						echo "You FTP configuration is done."
					#sed: find and replace (stream editor)
					#g:do this for the whole line
					#s:substitute-từ thay thể
					#-i:option is used to writes the output back to the file (wil overwrite source file)
					#-e:option indicates the expression/command to run, in this case s/
					;;

				"5")
					echo "--#####		Welcome to auto configuration Samba shell		#####--"
					yum install -y samba* --skip-broken
					echo "If you haven't configuration your NIC and DHCP first, you have to re-configuration manually again or re-install this shell later"
					sed -ie 's/host allow = 127. 192.168.12. 192.168.13. /& $temp /g' 	/etc/samba/smb.conf			
					echo "
					[Download-Without-Login]
					path = /var/spool/samba
					public = yes
					" >> /etc/samba/smb.conf			
					if [ ! -d "/home/SecureDocuments/" ]; then
						mkdir /home/SecureDocuments/
					fi
					echo "
					[Download-and-Upload-Account-Required]
					path = /home/SecureDocuments
					valid users = chicken
					writeable = yes
					browsable = yes
					create mode = 0760
					directory mode = 0770
					" >> /etc/samba/smb.conf	
					function check_user(){
					if id "$1" >/dev/null 2>&1; then
					        smbpasswd -a chicken
					else
					        useradd chicken 123
					        smbpasswd -a chicken
					fi
					}
					echo "We will add chicken user into your Samba serverm please type your password:"
					check_user chicken
					;;

				"6")
					echo "----------Welcome to the Auto add user Shell----------"
					echo 'Please input how many user you want to add, each user will seperate by space "_" button'
					read number_of_user
					echo "$number_of_user" >> users.txt
					for i in $( cat users.txt ); do
					    useradd $i
					    echo "user $i added successfully!"
					    echo $i:$i"123" | chpasswd
					    echo "Password for user $i changed successfully"
					done
					echo "Default password is 123, make sure you can change it later"
					;;

				"7")
					echo "********** Welcome to Auto check system information shell **********"
					echo""
					echo -e "\e ***** HOSTNAME INFORMATION *****\e"
						hostnamectl
						echo""
					echo -e "\e *****  FILE SYSTEM DISK SPCAE USAGE  *****\e" 
						df -h
						echo""
					echo -e "\e ***** FREE AND USED MEMORY  *****\e"
						free
						echo""
					echo -e "\e ***** SYSTEM UPTIME AND LOAD *****\e"
						uptime
						echo""
					echo -e "\e ***** CURRENTLY LOGGED-IN USERS *****\e"
						who
						echo""
					echo -e "\e ***** TOP 10 MEMORY-CONSUMING PROCESSES *****\e"
						ps -eo %mem,%cpu,comm --sort=-%mem | head -n 11
						echo""
					echo -e "\e  DONE. \e"
						;;
				[Nn]* | Exit | exit | 0)
					echo "Thank you for using our scripts. !!!"
					break
					;;
				* ) 
					echo "Unrecognize input, please tying from 1-7 to execute scripts or 0 to exit"
					read check
					;;
			esac
			;;
		[Nn]* | *)
			echo "Good bye, see you later !!!"
			break
	esac
done 
exit 0



#Đừng để ý khúc dưới này
#yum install -y cronie*
#function add() {
#  grep -Fq "$1" mycron || echo "$1" >> mycron
#}
#echo "Processing backup username and password on your system....."
#echo "1 */1 * * * vi /etc/passwd > backup_user1.txt" > crontab -e
#echo "1 */1 * * * vi /etc/shadow > backup_user2.txt"
#service crond restart
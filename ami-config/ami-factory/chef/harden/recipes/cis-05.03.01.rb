# CIS 5.3.1

#FIXME handle multiple flavors
package 'libpam-pwquality'
#RHEL uses pam_passwdqc

template '/etc/security/pwquality.conf' do
    source 'etc_security_pwquality.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
end

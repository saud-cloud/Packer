# CIS 5.3.2
# update /etc/security/common-auth.conf

template '/etc/pam.d/common-auth' do
    source 'etc_pam.d_common-auth.erb'
    owner 'root'
    group 'root'
    mode '0644'
end

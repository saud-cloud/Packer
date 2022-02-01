# CIS 1.4.3
# lock root password
bash 'lock root' do
    code 'passwd -l root'
end

# set password aging for root and ubuntu
bash 'password aging' do
    code <<-EOH
  for uid in root ubuntu ec2-user; do
    id -u $uid 2>/dev/null && /usr/bin/chage -m 0 -M -1 $uid
  done
    EOH
end

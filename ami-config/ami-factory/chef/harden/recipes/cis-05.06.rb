# CIS 5.6
# Description: Restrict access to the su command

cookbook_file "/etc/pam.d/su" do
    source "etc_pam_d_su"
    owner "root"
    group "root"
    mode 0644
  end
  
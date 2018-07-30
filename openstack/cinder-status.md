### Set cinder status in FusionCloud

Use cinder command line (only part of status):

```shell

# Connect to CPS, default password: IaaS@OS-CLOUD9!
ssh fsp@<cps_ip>


# Switch to root user, default password: IaaS@OS-CLOUD8!
su - root

# Import OpenStack enviorment, default password: FusionSphere123
. set_env

# Change the state of volume
cinder reset-state --state error_deleting b941b643-7772-41c3-a60b-66bf361ca3e8
cinder reset-state --state error b941b643-7772-41c3-a60b-66bf361ca3e8
```

Set status directly in database:

```shell
su - gaussdba

gsql -d cinder -W FusionSphere123

update volumes set status='error_extending' where id='cf950031-20c2-42c5-9ebc-b77e70ab3f06';
update volumes set status='error_rollbacking' where id='b941b643-7772-41c3-a60b-66bf361ca3e8';
```

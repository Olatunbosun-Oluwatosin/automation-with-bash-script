## Automating User and Group Management with a Bash Script

### _Creating the script_
![](./1.%20observed-output.png)

The content of the scripts will be push to the remote github repository as requested in task manual provided on the slack channel. The scripts <create_users.sh> was ran using the command below;
"sudo ./create_users.sh users.txt" where the usernames and the groups are specified in the text file <users.txt>.

### _Management log file content_
![](./2.%20log-file-content.png)
As seen in the image shared, this contain the activities based on what was initiated through the script.

### _Git installation on Ubuntu server_
![](./3.%20git-installed.png)
The command "sudo apt-get install git" installed git package on ouyr Ubuntu system. This will allow us to run git commands on the system.

### _Git add command_
![](./4.%20git-add-file.png)
The "git add" command was used to add our script <create_users.sh> to the local repository before pushing it to the remote repository.

### _Git push command_
![](./5.git-push.png)

The command <git push> was used to push our scripts from the local repository to the remote repository.

### _File for users and group_
![](./6.%20users-text-content.png)

The image above shows the content of the <users.txt> which comprises the usernames and the groups associated to the users. 

Thank you


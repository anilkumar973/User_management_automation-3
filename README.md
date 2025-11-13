Explanation
Purpose

Automate creation of multiple user accounts with proper groups, home directories, passwords, and logs — saving SysOps time.

Design

Reads user info from a file (user;group1,group2,...)

Skips blank lines and comments

Creates missing groups

Generates random passwords

Saves logs and credentials with correct permissions

Ensures idempotent execution (existing users/groups not recreated)

Step-by-step

Reads each line of input file

Ignores comments

Creates user and home directory

Adds user to required groups

Generates random password

Logs every step and error

Saves passwords securely
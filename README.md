# Bash 42
*Warning : you should know your commands and how they work before using this project.*
## Usage

If this is your first download, run this:

For bash users :
```sh
wget https://raw.githubusercontent.com/SaikoroAsh/Bash42/refs/heads/main/.bash42 -O ~/.bash42
echo ". ~/.bash42" >> ~/.bashrc && source ~/.bashrc
```
For zsh users :
```sh
wget https://raw.githubusercontent.com/SaikoroAsh/Bash42/refs/heads/main/.bash42 -O ~/.bash42
echo ". ~/.bash42" >> ~/.zshrc && source ~/.zshrc
```
After your first download, you can run this command to update to the last version:

`b42`

## Contribute
To contribute, you can submit your changes, and the project contributors will check the pull requests daily to accept or reject them.

## FAQ
### How to update automatically ?
In your **.bashrc** file, add `b42` on the start of a new line after `. ~/.bash42` so it will run the update command on the start of the shell.

For bash users :
```sh
echo "b42" >> ~/.bashrc
```
For zsh users :
```sh
echo "b42" >> ~/.zshrc
```
### You don't know where to start ?
Run the `help42` command to see all that is available.

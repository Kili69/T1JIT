# Introduction 
This is a active directory Just-In-Time solution based on the Active Directory Version 2016 or higher and powershell scripts. The reduce the risk of a administrator ist 24x7 administrator on all or many computers. 

The project is based on:
1) Active directory Forest functional Level Windwos Server 2016
2) A schedule task who create a group for each computer object. 
3) A Group Policy who add the computer specified group to the local administrators group on each computer
4) A scheduled task to add a user to one of these tasks. this task is triggered by an event
5) A powershell script which triggers the scheduled task

# Getting Started
TODO: Guide users through getting your code up and running on their own system. In this section you can talk about:
1.	Installation process
2.	Software dependencies
3.	Latest releases
4.	API references

# Build and Test
TODO: Describe and show how to build your code and run the tests. 

# Contribute
TODO: Explain how other users and developers can contribute to make your code better. 

If you want to learn more about creating good readme files then refer the following [guidelines](https://docs.microsoft.com/en-us/azure/devops/repos/git/create-a-readme?view=azure-devops). You can also seek inspiration from the below readme files:
- [ASP.NET Core](https://github.com/aspnet/Home)
- [Visual Studio Code](https://github.com/Microsoft/vscode)
- [Chakra Core](https://github.com/Microsoft/ChakraCore)

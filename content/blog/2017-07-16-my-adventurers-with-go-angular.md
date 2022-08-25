+++
author = "Robert Fletcher"
categories = ["Go", "programming", "Projects", "Robrotheram"]
date = 2017-07-16T21:39:38Z
description = ""
draft = false
thumbnail = "/images/Building_Go_Web_Applications___Microservices_Using_Gin.png"
slug = "my-adventurers-with-go-angular"
tags = ["Go", "programming", "Projects", "Robrotheram"]
title = "My Adventurers with GO/Angular"

+++


Why did I choose to learn Go, In part it was to add another language to my repertoire, I seen it listed as the main technologies behind some of the latest services for cluster orchestration and minoring such as [Prometheus.io](http://Prometheus.io). As I am a kind of person that when learning something new likes to have a project associated with it and I don't want to just build the age old todo app I though I have a crack making a REST interface to Virsh/Libvirt. I understand there are probably sever projects out there that do the same much better but this was mainly used so I could learn Go. 

![](https://raw.githubusercontent.com/robrotheram/microStackClient/master/docs/screenshot.PNG)


The project is called Micro-stack as it aims to do some of the things OpenStack can do but on a very limited footprint I was not aiming to produce the smallest thing in the world but the resulting binary is less than 10mb that includes all the backend libraries. I will talk more about the front end later.

One the best things I seen while writing this project is how easy it is creating background serveries. This should not be too surprising since Go prides itself on how concurrent the language is. But all you need to do is wrap a function ````go func() {}````. Since the language is fairly new it has a load of features implemented into the language such as DB support and basic web serving, encoding and decoding JSON structured. 

My main gripe about go lang and this is less to do with the language and more to do with the community around it. When starting a new project it is nice to see project structure or boilerplate projects to help get stated. In part is is because Go has so much built in the language there is hardly any setup code to write to get started for example web server is around 200 characters long.  

There is also no good way to manage packages. Go have recently launched [dep](https://github.com/golang/dep) otherwise there is ````go get repo-url ```` which works but feels somehow very basic which in a world where every language has there own build system might be refreshing. 

If you search for python or Node boilerplate project there are tones to choose from. These projects make it easier for someone new to get started and have a good base to expand from. Go has some excellent tutorials but they are all single file examples which for long term development is not the best. I could not find very few example projects, all I could find we either single file examples or very large projects that we too complex for a new person to get grips with. This is probably due to the main community lack of adoption for using GO for small personal projects instead going for python or node where they know there is a larger base of libraries they can use.

##### The Project
I personally had no trouble finding libraries I needed for this project. The main libaries I used were:

* go-sql-driver/mysql
* gorilla
* libvirt
* libvirt-go-xml
* yaml.v2

Gorilla was used for routing and also had good web-socket support and was used for the proxy to VNC the rest of the features that I need to implement were done by using the native libvirt bindings. 

To make the project feel inline with Openstack I wanted a way to get cloud images working. 
This ended up being more tricky then I thought and had to essentially default into running shell commands under the hood.

```go-lang
func CommandRunner(cmdName string, cmdArgs []string) (err error, result bool) {
	fmt.Println("running commandL: %s", cmdName)
	fmt.Println(cmdArgs)
	cmd := exec.Command(cmdName, cmdArgs...)
	cmdReader, err := cmd.StdoutPipe()
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error creating StdoutPipe for Cmd", err)
		os.Exit(1)
	}

	scanner := bufio.NewScanner(cmdReader)
	go func() {
		for scanner.Scan() {
			fmt.Printf("OutPUT out | %s\n", scanner.Text())
		}
	}()
	err = cmd.Start()
	if err != nil {
		return err, false
	}
	for scanner.Scan() {
		fmt.Printf("CMD out | %s\n", scanner.Text())
	}

	err = cmd.Wait()
	if err != nil {
		return err, false
	}
	return nil, true

}
```

By using the CommandRunner function to run the shell commands I needed I esentially took the bash script I wrote to do the same thing and conververted to GO. The steps in creating a vm are as follows:

* Get Paramaters form url POST request
* Generate a new set of ssh keys for the vm
* Create a Cloud Config YAML file that defines how to set up the VM
* Using the cloud-localds command a seed image can be created using the config file
* Now a disk of size specified can be created.
* With all the requirements complete we can use the virt-install and define all the parameters (Memory, CPU core, Disk locations)

If all the commands run sucessfully we have a will have a vm we can start and on boot it will auto configure with all the setting that were defined in the cloud init file. The reset of the commands e.g turning on the vm are done with functions form the labaries e.g to start a VM we do:

```go-lang
func start(uuid string) {
	conn, err := libvirt.NewConnect("qemu:///system")
	if err != nil {
		fmt.Println(err.Error())
	}
	dom, err := conn.LookupDomainByUUIDString(uuid)
	if err == nil {
		err := dom.Create()
		if err != nil {
			fmt.Println(err.Error())
		}
	}
	conn.Close()
}
```

We also have a couple of background jobs, the first one is a simple always running job that is collating vm metrics such as working out the VM load. The other background job is created when a user wants to use the noVNC JavaScript UI to view the VM console. This is done by creating a web socket that connects to the VM VNC port and sends the JavaScript the frame buffer for it to render.  You can see an example below.
 
![](https://raw.githubusercontent.com/robrotheram/microStackClient/master/docs/screenshot2.PNG)

While I am happy with the results and think I might use Go for future projects there is still one minor niggle I have with the Language. I not a fan of not defining where every function comes from. Let me explain, In Go if you define a function in one file and use it in another file and these 2 files are in the same directory Go will automatically workout where this function is. My problem with this is that is not clear when looking at projects on the web for inspiration where that function is defined and requires you to search the project each time you want to find that function. I am more in favour of explicitly defining where stuff comes from at the top of the file. I know this increases the amount of boilerplate code you have to write but for new people to the language it makes it clear the entire project structure. 

---

##### The Client / Angular 4.0

For some reason I chose Angular over react, I think this was because Angular 4.0 was recently released and I already played a bit with react previously and thought lets give this new thing a go. 

There is not that much to say since the client is very small and only contains a few components. I used the quickstart project (https://github.com/angular/quickstart) at first but moved the the better Angular CLI tool that automatically sets up webpack for you to begin developing the web-app. 

If there is one thing about angular and its the same for most of the JavaScript web-apps there is a tone of boilerplate code to write and remember to import files into the correct files otherwise it will not load. So while Go minimises the boilerplate code to a point that in my mind makes it a little confusing, Angular goes the other-way and added a tone of boilerplate code especially if you use the quick-start project that uses System.js.

Apart form the boilerplate issues I do like the component architecture. For a project that took only about a month to make Angular is fast to develop in compered to React. The main advantage Angular has here over react is that it is one project while React splits it up into several smaller projects which effective requires reading 3 time the documentation. On the downside Angular problem is its old namesake Angular.js which does make googling a problem harder you have to keep adding angular 2 or angular.io to find results. The final negative would be its 3rd partly libraries the re-write from angular.js to angular.io caused many people to only support the js version or re-write and choose a different MVC framework such as React.

![](https://raw.githubusercontent.com/robrotheram/microStackClient/master/docs/screenshot1.PNG)

---
##### In Conclusion

While both Angular and Go have its problems they are all around documentation/eco-system with less well know libraries to complete task compered with Node/React but the this project has only taken about 2 ish months on and off to complete which means that a person like me can get a grasp on the technologies and build something fairly quickly. 

All the code is opensource if you want to see it 

The server: https://github.com/robrotheram/microStackServer
The Webapp https://github.com/robrotheram/microStackClient


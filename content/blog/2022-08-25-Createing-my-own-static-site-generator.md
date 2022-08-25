+++
author = "Robert Fletcher"
date = 2022-08-25T00:51:16Z
description = "Creating a theme"
draft = false
thumbnail = "/images/2022-08-25-Createing-my-own-static-site-generator/Static-Site-Generation.png"
slug = "2022-08-25-Createing-my-own-static-site-generator"
tags = ["Static", "Site", "Generator", "Galery", "Development", "hugo"]
title = "Building my own Static Site Generator"
+++

Over the past 6 months I have solwly been moving all my sites to be built using static site generators. In part as I am enjoying the easy of editing some markdown and it producing a site. My [last post](/blog/2022-02-09-moving-from-ghost-to-hugo/) I moved this blog from ghost to be built by static site generator. The static site generator I used was Hugo. I like the similicty, its fast and has a good amount of supports especially around theming as try as I might I am not a UI designer. 

Currrently My personal portfolio and blog are hugo sites. My CV is Latex because if you are going to static site generate all the things you might as well ☺️ The only main public thing that that is left is the gallery. Lets get that to be built using a static site generator so there is no DB and maybe find some other places to host it like S3 or places like netlify like other JamStacks deployments.

But What is a Jamstack?

Jamstack is an architectural approach that decouples the web experience layer from data and business logic, improving flexibility, scalability, performance, and maintainability.

Its supposed to offer the following beinifits: 
- **Faster performance:** Serve pre-built markup and assets over a CDN.
- **More secure:**  No need to worry about server or database vulnerabilities.
- **Less expensive:** Hosting of static files is cheap or even free.

Most tooling ends up just write content in markdown, run it through some generator e.g hugo that will use a theme to generate a site which is just a bunch of HTML files. finally publish that site on some low cost CDN e.g github pages, S3, netlify or your own server. 

Basiclly just the next interaction in the LAMP, MEAN tech stack. 

---
### Bit of history

Back to the gallery. The first problem is I can not and do not want to host my images in github in part that the raw files are around 25-50MB in size and the High quality png produced are in the 5mb size. So for my 1000+ images that 5GB+ which falls out of the free tier of places like github
The currently set of tools are designed for text content and I do not want to alter the stucture of my images. I have them in folders represnting albums which I like. What I need is a tool that I can point at the root of the albums and generate the site. 

Currently there are no mainstream tools that can do this and most image gallery software have databases which you need to host. So time to make one I guess. 

I had a custom image gallery for something like 15 years. I started off with a wordpress plugin urg... which was a pain to manage. I then transitioned to a dedicated CMS for images called Koken which was great and even had a lightroom plugin. Then about 4-5 years ago all development on it stoped. (There is a long story which you can read here https://www.koken.me/ ). I was playing around with this new language called golang so I used the need to build a new gallery to learn it and build it in golang. 

4 years later and the gallery software has had many iterations. Last year I replaced the frontend from a React Single Page app to a server side rending template based on the handlebar syntax. I was initally thinking I could port some Ghost themes. That never happended ah best laid plans of mice and men. 

### Building the Static site generator 

So the gallery software had most of the things in place to become a static site generator. It already can scan a directory of images and also had the ability to generate pages but instead of writing it out of a http socket it just had to write the data to a file. 
That was a realitivly simple change to make. The hard part is the images themselves. 

There is a lot of debate about image formats sizes etc. I am not going to say my way is the best but just the one I chose 

From what I read next gen images formats such as webp are surposed to offer a better performance as they are better compressible increseing download speed. So that is the format I have choses. The other optomization that was made was to generate images in different sizes. So that only the approiate sized image format is served. For example on the homepage is a grid of images. On a standard desktop image image in the grid is only about 400px in width, so we can serve a 400px image saving tones of bandwidth also speeding up the web pages. 

There has been some good developments in the HTML spec allowing the use of some new HTML attributes to do image optomizations without the needs of javascript 😎

These are **lazy** which will only load the image if it above the page. So if you have 1000 images on a page only once you scroll and that image is now visible will the browser decide to load it. **srcset** defines a list of images and what size should we load that images and sizes we can define what size of image depending on the page width. So for desktop with large grid of images only load the smaller images, mobile where you will only have 2 images displayed at one time and therefore these images are bigger and phones have much higher DPI we will load the large image. 

```HTML
 <img 
    loading=lazy  
    width="100%" 
    alt="DSC04343" 
    src="/img/f48e004fd4efea57238bf46096839d25/xlarge.webp" 
    srcset="
        /img/f48e004fd4efea57238bf46096839d25/large.webp 1600w,
        /img/f48e004fd4efea57238bf46096839d25/xlarge.webp 1920w,
        /img/f48e004fd4efea57238bf46096839d25/xsmall.webp 350w,
        /img/f48e004fd4efea57238bf46096839d25/small.webp 640w,
        /img/f48e004fd4efea57238bf46096839d25/medium.webp 1024w,
    "
    sizes="
        (min-width: 1200px) 640px,
        (min-width: 960px) 350px,
        (min-width: 750px) 1024px, 
        1600px
    "
    class="rounded img-fluid"/>
```
So for one image we will generate 5 new ones of various sizes. You would think that this migh take a long time. But thanks to golang concurrent processing we can do this in parallel. In my usecase I have 1000 images and the code takes approx 150seconds to generate the site. 

I wrote my own batch processing framework using new golang generics. Mainly so I could play around with this new feature. The batch framework is very simple it has a workgroup to manage the gorouties a chuck size to specifiy how many concurrent workers you want and a function that will do the work. 

You then give it an slice containing all the work you want to do e.g a list of images and it will chunk this up and start the goroutine to do this. 

```go
import (
	"runtime"
	"sync"
)

type BatchProcessing[T any] struct {
	wg        sync.WaitGroup
	work      func(T) error
	chunkSize int
}

func chunkSlice[T any](slice []T, chunkSize int) [][]T {
	var chunks [][]T
	for i := 0; i < len(slice); i += chunkSize {
		end := i + chunkSize
		if end > len(slice) {
			end = len(slice)
		}
		chunks = append(chunks, slice[i:end])
	}
	return chunks
}

func (batch *BatchProcessing[T]) Run(items []T) {
	for _, chunk := range chunkSlice(items, batch.chunkSize) {
		go batch.processing(chunk)
	}
	batch.wg.Wait()
}

func (poc *BatchProcessing[T]) processing(batch []T) {
	poc.wg.Add(1)
	defer poc.wg.Done()
	for _, pic := range batch {
		poc.work(pic)
	}
}

func NewBatchProcessing[T any](processing func(T) error) *BatchProcessing[T] {
	proc := BatchProcessing[T]{}
	proc.work = processing
	proc.chunkSize = runtime.NumCPU()
	return &proc
}

```
Implemenation:

```go

func main(){
    imageRender = NewBatchProcessing(ImageGenV2)
    pageRender = NewBatchProcessing(renderPhotoTemplate)
    ImageRender.Run(datastore.GetPictures())
    pageRender.Run(datastore.GetPictures())
}

func ImageGenV2(pic datastore.Picture) error {
	destPath := filepath.Join(imgDir, pic.Id)
	os.MkdirAll(destPath, os.ModePerm)
	for key, size := range templateengine.ImageSizes {
		cachePath := filepath.Join(destPath, key+".webp")
		newImage, _ := bimg.NewImage(buffer).Resize(size, 0)
		bimg.Write(cachePath, newImage)
	}
	return nil
}
```
The nice part of generics is that I can reuse the batch framework without the need of horrible reflection of types and just define the fuction to do the work and pass in the slice of work I want it to do.


### Using the Static site generator 

gogallery has the following options

```bash
$ gogallery 
Using config file: /home/robrotheram/.gogallery.yml
Generates a full static site that you can host all use the local provided server

Usage:
  gogallery [flags]
  gogallery [command]

Available Commands:
  build          build static site
  completion     Generate the autocompletion script for the specified shell
  deploy         deploy static site
  help           Help about any command
  init           create site
  reset-password reset admin password
  serve          serve static site
  template       extract template

Flags:
      --config string   config file (default is $HOME/.gogallery.yaml)
  -h, --help            help for gogallery

Use "gogallery [command] --help" for more information about a command.

```

Once configured you can build a site using  the command `gogallery build`
Give it a couple minuets as it will build your site. 

You can preview your site using the inbuild webserver `gogallery serve <port>`

Finally you can deploy straight to netifly using `gogallery deploy`

#### Why Netifly?

Simply put when I was researching jamstacks it was one of the popular deployment options and hugo treats it as a first class deployment so I gave it a go. Also it has free hosting which is always a plus. 



### Links

Example gallery: https://gallery.exceptionerror.io/

Source code: https://github.com/robrotheram/gogallery






























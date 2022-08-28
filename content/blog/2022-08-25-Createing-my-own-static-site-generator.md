+++
author = "Robert Fletcher"
date = 2022-08-25T00:51:16Z
description = "Creating a static site generator for 1000 images"
draft = false
thumbnail = "/images/2022-08-25-Createing-my-own-static-site-generator/Static-Site-Generation.png"
slug = "2022-08-25-Creating-my-own-static-site-generator"
tags = ["Static", "Site", "Generator", "Galery", "Development", "Hugo"]
title = "Building my own Static Site Generator"
+++

Over the past 6 months, I have slowly been moving all my sites to be built using static site generators. I am currently enjoying the ease of editing some markdown and it producing a site. My [last post](/blog/2022-02-09-moving-from-ghost-to-hugo/) I moved this blog from ghost to being built by a static site generator. The static site generator I chosed was Hugo. I like the simplicity, it is fast and has a good amount of support especially around theming as try as I might I am not a UI designer. 

Currently, My personal portfolio and blog are Hugo sites. My CV is Latex because if you are going to static site generate all the things you might as well ☺️ The final webiste that could be tranistioned is the gallery.  If I can  use a static site generator there would be no DB to manage and since the output is just a bunch of html files I should be able to find some felexible deployment options. In the past few years there has been some interesting progress in Jamstack achitecute/infrasctructure. 

But What is a Jamstack?

Jamstack is an architectural approach that decouples the web experience layer from data and business logic, improving flexibility, scalability, performance, and maintainability.

It's supposed to offer the following benefits: 
- **Faster performance:** Serve pre-built markup and assets over a CDN.
- **More secure:**  No need to worry about server or database vulnerabilities.
- **Less expensive:** Hosting of static files is cheap or even free.

Most tooling ends up just writing content in markdown, and running it through some generator e.g Hugo that will use a theme to generate a site that is just a bunch of HTML files. finally, publish that site on some low-cost CDN e.g GitHub pages, S3, Netlify, or your own server. 

Basically, it is just the next iteration in the LAMP, MEAN tech stack. 

---
### Bit of History

Back to the gallery. The main problem is I can not and do not want to host my images on Github in part because the raw files are around 25-50MB in size and the High-quality png produced are in the 5Mb size. So for my 1000+ images  in the gallery I would need to host  5GB+ which falls out of the free tier of places like GitHub
The current set of tools is designed for text content and I do not want to alter the structure of my images. I have them in folders representing albums that I like. What I need is a tool that I can point at the root of the albums and generate the site. 

Currently, there are no mainstream tools that can do this and most image gallery software has databases that you need to host. So time to make one I guess. 

I had a custom image gallery for something like 15 years. I started off with a WordPress plugin urg... which was a pain to manage. I then transitioned to a dedicated CMS for images called Koken which was great and even had a lightroom plugin. Then about 4-5 years ago all development on it stopped. (There is a long story which you can read here https://www.koken.me/ ). I was playing around with this new language called Go so I used the need to build a new gallery to learn it and build it in Go. 

4 years later and the gallery software has had many iterations. Last year I replaced the front end from a React Single Page app with a server-side rending template based on the handlebar syntax. I was initially thinking I could port some Ghost themes. That never happened ah best-laid plans of mice and men. 

### Building the Static site generator 

So the gallery software had most of the things in place to become a static site generator. It already can scan a directory of images and also could generate pages but instead of writing it out of an HTTP socket it just had to write the data to a file. 
That was a relatively simple change to make. The hard part is the images themselves. 

There is a lot of debate about image format sizes etc. I am not going to say my way is the best but just the one I chose 

From what I read next-gen image formats such as webp are supposed to offer better performance as they are better compressible increseing download speed. So that is the format I have chosen. The other optimization that was made was to generate images in different sizes. So that only the appropriate sized image format is served. For example on the homepage is a grid of images. On a standard desktop image, the grid is only about 400px in width, so we can serve a 400px image saving tones of bandwidth also speeding up the web pages. 

There have been some good developments in the HTML spec allowing the use of some new HTML attributes to do image optimizations without the need for javascript 😎

These are **lazy** which will only load the image if it is above the page. So if you have 1000 images on a page only once you scroll and that image is now visible will the browser decide to load it. **srcset** defines a list of images and what size should we load those images and sizes we can define what size of the image depending on the page width. So desktops with a large grid of images only load the smaller images, mobile where you will only have 2 images displayed at one time and therefore these images are bigger and phones have much higher DPI we will load the large image. 

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
So for one image, we will generate 5 new ones of various sizes. You would think that this might take a long time. But thanks to Go concurrent processing we can do this in parallel. In my use case, I have 1000 images and the code takes approx 150seconds to generate the site. 

I wrote my own batch processing framework using new Go generics. Mainly so I could play around with this new feature. The batch framework is very simple it has a workgroup to manage the goroutines a chuck size to specify how many concurrent workers you want and a function that will do the work. 

You then give it a slice containing all the work you want to do e.g a list of images and it will chunk this up and start the goroutine to do this. 

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
Implementation:

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
The nice part of generics is that I can reuse the batch framework without the need for horrible reflection of types and just define the function to do the work and pass in the slice of work I want it to do.


### Using the Static site generator 

gogallery has the following options

```bash
$ gogallery 
Using config file: /home/robrotheram/.gogallery.yml
Generates a fully static site that you can host all using the local provided server

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
  serve          serve a static site
  template       extract template

Flags:
      --config string   config file (default is $HOME/.gogallery.yaml)
  -h, --help            help for gogallery

Use "gogallery [command] --help" for more information about a command.

```

Once configured you can build a site using  the command `gogallery build`
Give it a couple minutes as it will build your site. 

You can preview your site using the inbuilt webserver `gogallery serve <port>`

Finally, you can deploy straight to Netifly using `gogallery deploy`

#### Why Netifly?

Simply put when I was researching jamstacks it was one of the popular deployment options and Hugo treats it as a first-class deployment so I gave it a go. Also, it has free hosting which is always a plus. 



### Links

Example gallery: https://gallery.exceptionerror.io/

Source code: https://github.com/robrotheram/gogallery

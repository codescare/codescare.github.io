---
title: "Setting up Hugo on Github Pages"
date: 2018-02-18T14:31:49+05:30
---

At the time of writing this, this blog itself is hosted on [GitHub Pages](http://github.io) and is built with the static site generator [Hugo](https://gohugo.io/), and since this is just the second post, I'll go into some detail explaining how to setup Hugo properly (or at least the way I did it), which should be a matter of minutes even if you are not so experienced with these sort of things! If you follow the steps exactly, you'll have a blog up and running in no time!

If you are comfortable with the process of setting up GitHub Pages and site generators, I suggest heading over to the official [Quick Start](https://gohugo.io/getting-started/quick-start/) guide instead.

## Prerequisites
- Basics of git
- Basics of [markdown](https://lifehacker.com/5943320/what-is-markdown-and-why-is-it-better-for-my-to-do-lists-and-notes)
- Hugo is [downloaded](https://gohugo.io/getting-started/installing) and added to PATH. You have done this properly if you can run `hugo version` from anywhere.

# Let's Start!
So now we're all set to create our own blog!

First, if you don't have it already, start by setting up an account on GitHub, which you will need to use GitHub's Pages service (which is free). For this, just head over to [GitHub](https://github.com) and create a new account. Choose your username wisely, because your blog's URL will have your username in it. For example, by default, if your username is **hello-world**, then your blog's URL will be **hello-world.github.io**!

Once you have an account, head over to GitHub again, and create a new repository and name it **your-username.github.io**, replacing **your-username** as appropriate. Check **Initialize this repository with a README** and create the repository. Clone the repository into any local folder with git.


## Create the Website
Inside the repository, you can now create a new site by running
```bash
hugo new site mysite
```

This will create a folder named `mysite` with a bunch of files that define our site. `cd` over to this folder.
First, head over to `config.toml` and change `baseURL` as
```toml
baseURL = "https://your-username.github.io/"
```

## Add a Theme
For this example, I'll be using the [cactus-plus](https://github.com/nodejh/hugo-theme-cactus-plus) theme, which I think is very clean and tidy. Add this theme by running
```bash
git submodule add https://github.com/nodejh/hugo-theme-cactus-plus themes/cactusplus
```

You still need to update your site to use this theme. For this, add the following line to `config.toml`
```toml
theme = "cactusplus"
```

## Add Some Content
Next, we need to add a post to our site. For this, run the following command
```bash
hugo new posts/my-first-post.md
```
This will create a new file `contents/posts/my-first-post.md`. This is a regular markdown file that you can edit as you want, which has the contents of the post. Be sure not to accidentally delete the header in the file. For now, you may start by adding some dummy content. Note that this post is marked as a draft, so it won't be visible on the site.

## Try it out!
Go back to the root directory of Hugo (the directory with `config.toml`) and run the following command
```bash
hugo server -D
```
This should start a local Hugo server, which the `-D` indicating that drafts should be visible. Head over to the URL that is printed, and the page will be served! Now you can start adding content to your posts and also add dozens of posts. When you save a post, the browser will automatically refresh it, so you can see live changes.

## Deploying it
The last part is to publish the site to GitHub Pages. In config.toml, add the following line
```toml
publishDir = ".."
```
This will make Hugo output its files in the root of your repository, allowing GitHub Pages to serve it properly. Next, mark all posts you are satisfied with as completed by deleting the line `draft=true` from the header. To build your site, just run
```bash
hugo
```
and you're done! To see your blog in action, just commit and push to GitHub and visit **your-username.github.io**.

*Happy Blogging!*
---
title: "Continuously Deploy Hugo to GitHub Pages"
date: 2018-04-09T13:00:08+05:30
draft: false
---

I previously wrote on [setting up Hugo on GitHub Pages](../setting-up-hugo-on-github-pages), but if you want to get slightly more ambitious and automate deployment to GitHub Pages,  read on! At the end of this post, you will never need to build before commiting again; just write in markdown and let [Travis CI](https://travis-ci.org) take care of the rest!

**A note:** This blog is actually doing this, so if you want a live example of the result of this procedure, head over to [this GitHub repository](https://github.com/pulsejet/blog).

## Prerequisites
I am assuming you have Hugo setup locally and can deploy to GitHub Pages manually, and that your site is, in fact, working. For this, I will also assume that you are running the site as a project website and not as a user or organizatin website. This means that your url must look something like `username.github.io/awesomeblog` and not `username.github.io`.

## Setting up

To begin with, create an account with Travis if you don't have one already. Next, go to the repositories area and activate your blog repository. Now click on settings, and enable **Build only if .travis.yml is present** for the repository.

Now that Travis is all set to build for us, we need to tell it how to do that. For this, push the following as `.travis.yml` to your repository's root:
```
language: generic

script:
   - chmod +x build.sh && ./build.sh

deploy:
  provider: pages
  skip-cleanup: true
  keep-history: true
  github-token: $GITHUB_TOKEN
  local-dir: built
  on:
    branch: master
```

So what is this doing?

1. Set the `language` to `generic`, since we don't need any build environment. 
2. Run a build script to build our site.
3. Finally, we make Travis push to our repository with the built files. Note here that the commits will take place in the `gh-pages` branch, so you will need to point your GitHub Pages to this branch. This can be done easily inside the repository's settings.

A couple of notes:

* Set `keep-history` to `false` if you don't want history in your built pages branch.
* Travis will push the folder `built` as defined in `local-dir`, so you will need to adjust your `config.toml` to build to this directory.
* Make sure you have set `skip-cleanup` to `true`, or Travis will delete the built files!

Next, we need to add the build script. This is pretty straightforward, and my `build.sh` looks something like this:
```
#!/bin/bash

mkdir built
wget https://github.com/gohugoio/hugo/releases/download/v0.38.1/hugo_0.38.1_Linux-64bit.tar.gz
tar -xvzf hugo*.tar.gz
./hugo
```

This simply downloads a fixed version of Hugo, extracts the tarball and builds the site. Again, the build path must be set to `built` in `config.toml`.

Finally, we need to grant Travis permissions to push on our behalf. For this, go to GitHub and create a [personal access token](https://github.com/settings/tokens). Make sure you copy the token somewhere safe, since it will be displayed only once. If you are on a public repo, grant the token only `repo` permissions.

Now go to the Travis dashboard, and into the settings for your repository. Here, create an environment variable named `GITHUB_TOKEN` with the value as the token you just created,and make sure that it is hidden in builds.

## All Set!

And there you are! Just get rid of the built files from your `master` and push a change to GitHub. Travis should pull in your changes, build with Hugo and push back to `gh-pages` completing your continuous deployment!

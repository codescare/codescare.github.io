---
title: "HTTPS with Github Pages Custom Domain"
date: 2018-04-10T21:51:00+05:30
draft: false
---

## Background
GitHub Pages supports SSL for pages with `username.github.io`, but till now, there was no inherent support for SSL for custom domains. As soon as you added a custom domain, your site would be served over plain HTTP.

## Enter 'Enforce HTTPS'
Recently, GitHub added another option to the settings of repositories with GitHub Pages enabled, named [Enforce HTTPS](https://help.github.com/articles/securing-your-github-pages-site-with-https/). As the documentation states, this is applicable only for `github.io` sites, and doesn't work for custom domains. This option actually enables HSTS on your site, forcing it to be served via a secure channel.

## Further Developements
Recently, however, as noted by some people at [an issue tracking this](https://github.com/isaacs/github/issues/156) at the [unoffical GitHub support repo](https://github.com/isaacs/github), GitHub has started enabling this option for repos with custom domains too, using [Let's Encrypt's](https://letsencrypt.org/) free SSL certificates. The way it works is that as soon as you enter a custom domain on a new site, GitHub tries to get an SSL certificate for it, and serves the website over HTTPS using this. This, though, seems to be a feature in staging, since it seems unavailable to existing repos as of yet. I tried making a new GitHub Pages site, and the site was served for my custom domain with encryption successfully!

## So what about existing websites?
Well, this is not really of use to people with existing sites using custom domains, right? It turns out that there is an ugly hack to get this on your old site as well. Here's how I went about it:

1. Remove the `CNAME` file from the old repo.
2. Make sure your DNS is directed directly to GitHub pages and not a CDN. Do this by creating a `CNAME` record for your domain pointing to `username.github.io`.
3. Create a new repo with a different name.
4. Push your files to this new repo. **DO NOT** push the `CNAME` file with this. If you push the `CNAME` file here, `Enforce HTTPS` gets disabled.
5. Now go to settings for the new repo and enable GitHub Pages. Wait for the site to build and check.
6. Now add a `CNAME` through the settings of the repo, by setting a custom domain.
7. Wait for HTTPS to set up (takes ~2 minutes) and have fun!

## Conclusion
This is a really nice feature that will probably be useful for many people once it arrives in its fullest. HTTPS is often important not only for security, but other things like SEO, preventing browser warnings and general user trust. Hope it arrives for everyone real soon!

### ❤ for GitHub Pages and Let's Encrypt!


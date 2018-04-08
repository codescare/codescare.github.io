---
title: "HATEOAS - The Good, the Bad and the Ugly"
date: 2018-02-20T18:51:13+05:30
---

If you are working on a RESTful API, chances are that you have read or heard (I'll explain soon how it is pronounced) the word HATEOAS sometime while browsing best practices, technologies or about APIs in general. Wikipedia defines it as

> Hypermedia As The Engine Of Application State (HATEOAS) is a constraint of the REST application architecture that distinguishes it from other network application architectures.

but (in my opinion), it doesn't really explain much about how you are supposed to use it, or what the advantages (and disadvantages, if any) of using it are. I'm going to try to address these things in this post. Beware that I'm myself somewhat of a beginner in this, so I wouldn't advise following anything blindly if you are building an industry-grade enterprise application!

## Introduction
So, first, how do say it? There isn't really a consensus on this, but apparently, the most common pronounciation is goes as *hay-tee-ous*, which sounds somewhat like *hideous*.

Now that we have that aside, I want to give you a breif intoduction to what HATEOAS really is. For this, let us consider a simple API for the canonical blog-post database, with an additional table for users, who may comment on blog posts etc.

Suppose you have an endpoint that gets a post object, along with the comments on the post. This would look something like this

```javascript
{
    postName: "Some Post",
    description: "An amazing blog post",
    body: "Not such an amazing body",
    comments: [
        {
            name: "User 1",
            comment: "Hey, this post is terrible!"
        },
        {
            name: "User 2",
            comment: "I love this post, I read it daily ... visit my website now"
        },
        {
            name: "User 3",
            comment: "What...?"
        }
    ]
}
```

I want to pause here and emphasize that JSON not a standard format for HATEOAS. To properly implement it, you have to use hypermedia, or more specifically, something like XML is the proper way to implement it. However, JSON is really easy to parse and we do want that functionality, I will assume that we are using it for our API.

Suppose, for whatever reason, a comment can further be opened and there are more details in it such as the time of commenting, IP address etc. which are given by a separate API. To implement this, the server may just include a UID with the comment, which the client can now use to generate a new API url.

Now, lets bring in HATEOAS. With HATEOAS, your response would look like this

```javascript
{
    postName: "Some Post",
    description: "An amazing blog post",
    body: "Not such an amazing body",
    links: [
        {
            rel: "self",
            href: "http://blog.example.com/api/some-post"
        }
    ]
    comments: [
        {
            name: "User 1",
            comment: "Hey, this post is terrible!",
            links: [
                {
                    rel: "self",
                    href: "http://blog.example.com/api/some-post/comments/1"
                }
            ]
        },
        {
            name: "User 2",
            comment: "I love this post, I read it daily ... visit my website now",
            links: [
                {
                    rel: "self",
                    href: "http://blog.example.com/api/some-post/comments/2"
                }
            ]
        },
        {
            name: "User 3",
            comment: "What...?",
            links: [
                {
                    rel: "self",
                    href: "http://blog.example.com/api/some-post/comments/3"
                }
            ]
        }
    ]
}
```

Don't be scared by how large this looks! If you look carefully, we have just added one URL corresponding to the object to each entity. Notice that we also have another field `rel`, which indicates that it represents the entity itself (this will come up again later). Now, if the client wanted to get the comment, it can simply look for a link with `rel` as `self` and follow it! No need to create a URL by concatenating strings, looking at the state and so on!

But again, you might ask, what real use is this, when we can simply get the URL by the UID anyway. This brings us to,

## The Good

### 1. Authorization
Now suppose you want to let the users edit their comments, you have a few options (which don't use HATEOAS):

1. Let users see the edit button for all comments, but the server will authorize them only if they have access. Horrible!
2. Let the client make a separate requests to acknowledge what permissions the user has, hiding and showing things appropriately.
3. Let the reply include a flag if the post can be edited by the current user.
4. Probably many more ...

Instead of all this, if you use HATEOAS, the whole logic becomes much more natural and easier to work with. While returning the data to the client, the server simply checks if the post can be edited and return a response with

```javascript
comments: [
        {
            name: "User 1",
            comment: "Hey, this post is terrible!",
            links: [
                {
                    rel: "self",
                    href: "http://blog.example.com/api/some-post/comments/1"
                },
                {
                    rel: "update",
                    href: "http://blog.example.com/api/some-post/comments/1/update"
                }
            ]
        },
        {
            name: "User 2",
            comment: "I love this post, I read it daily ... visit my website now",
            links: [
                {
                    rel: "self",
                    href: "http://blog.example.com/api/some-post/comments/2"
                }
            ]
        }
]
```

Notice that the entry for comment `1` has another link in it now, pointing to an update URL. The authorized user's client can now simply follow this link and send an update to the server. If the link isn't preset, it already knows that updating is not possible. Further, it actually doesn't know the URL for updating the comment, which might give you an added security advantage.

### 2. Maintainability
Suppose now you update your API to version 2, after realizing that your structure was not so great, but this ends up changing the URL that must be used to update comments to `http://blog.example.com/api/some-post/comments/1/modify`. If you are not using HATEOAS, you will also need to make sure that all client application implementations change the URL generators appropriately. With HATEOAS, however, this makes absolutely no difference to the client, since it will just call the new URL that will be sent by the server! This may not be an issue with small applications, but even for a mid-sized application, it gives great flexibility to the API maker.

### 3. Tracking
With this, you can now also generate unique URLs for actions, enabling you to track all actions automatically without intervention from the client. Further, tracking actually is completely unblockable now, since it is inherently built into the systems. You can easily figure out which was the previous call done by the user from the same session, what is the flow of calls and so on.

### 4. Server Control
Effectively, the status of the client application is completely determined by the server's response, which might place you at a huge advantage, not only in terms of security, but also for ease of programming. The client will tend to be more minimalistic, and things are just more deterministic for the server, since an illegal request due to a programming bug is completely unwarranted for now. It also reduces the number of bad requests, since each request is checked by the server itself, before it is sent out to the client.

### 5. Ease
Seriously, it is much easier for the client to use ready-made links that generating them itself!

All this seems good, but as usual, there are a few things that aren't so great about this, which can be summarised as,

## The Bad
### 1. Harder to Implement
While getting URLs from the server is convenient for the client, generating URLs is now something that the backend programmer is responsible for now. This effectively makes it much harder to write the backend for an API which implements HATEOAS.

### 2. Needs More Resources
While this may not be a big concern, including all those URLs in your response and storing them on the client will put some stress on network and memory. Of these, again, network will not be an issue in most cases unless there are a huge number of items since the response will be sent compressed, but it will definitely have some impact on memory usage. Further, it might just be much easier to concatenate a predefined template and a UID to get a URL than looking through hundreds of records to find one.

### 3. Tracking
HATEOAS offers unblockable tracking. And every coin has two sides!

### 4. Reduces Flexibility
Not allowing the client to make its own URLs does reduce flexibility in some cases, especially where the client behaves highly unpredictably. Everything that can be done is already pre-defined by the server, giving the client limited options.

### 5. Unnecessary for Small Applications
If your application has only a few users and a single client with only minimalistic, there is no point adding the overhead of HATEOAS, since you can easily update anything as required.

I wanted to highlight a couple of other, but couldn't really fit them into any of these, so I'll instead label them as,
## The Ugly
### 1. Deep Linking
Deep Linking can be a real pain to achieve with HATEOAS, since the state of the application is defined by the server, and hence visiting a URL that defines the state needs an understanding between the server and the client, or the client needs to store the state itself in the URL. One way to achieve the latter is by encoding the `self` link of the object and passing through the URL. This effectively stores the state as long as the URLs generated do not have an expiry.
### 2. Excessive Information
You will end up with too much unnecessary information on the client that you will probably never use. While this is not really a big issue, it somehow feels like going backwards!

## Conclusion
So, is HATEOAS worth it? If you are looking to build a new modern API that is strictly RESTful, then *yes*, you should use HATEOAS, since it is one of the constraints of ReST, and is rather useful too! If you are building a small time application that doesn't need to be too maintainable, or if you are going to be the only maintainer for a long time, I really don't think it is worth the effort. For existing projects, it would really depend how everything is implemented, but while implementing it on the server side should not be too much effort (since it is non-intrusive, in the sense that traditional calls would continue working anyway), updating the clients would probably involve reworking everything they have. Either way, *if you have the resources, do it. If you don't, you could end up wasting them.*
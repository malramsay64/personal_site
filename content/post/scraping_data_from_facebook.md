+++
title = "Scraping Data from Facebook"
date = "2018-04-30"

draft = true
math = true
highlight = true
+++


Lanceband we are interested in the number of likes we have
- partially because we are growing our follower base
- also because we have recently overtaken a 'rival'

We want to keep track of where we stand amongst other comparable Facebook pages.
- there are a lot of pages to keep track of
- what about historical data?
- how are we growing?


Facebook Graph API
- Query Facebook data from an app
- allows access to a wide range of data
- The field I am looking for is `page_likes`


Problem is with all the privacy concerns about applications
using this API is difficult
- one off useage is fine, getting a token from the GraphAPI page
    - this token can request any permissions you require
    - only for your own facebook account
    - token only lasts an hour.
- longer term usage is a problem
    - have to request a token every hour/every time you use
    - Creating an app is a giant pain in the arse
        - need terms of use
        - privacy statement
        - app approved by FB

At this point with all the restrictions why bother with the standard approach.

All the data I want is publicly available for most pages
- the number of likes on the page.


Since it is so hard to get this data through the API that Facebook is providing,
lets go about this in a different way.

As far as I can discern,
the two packages to get for dealing with webpages in python are
- requests
    - which provides an interface to the creation of http requests and their returned data
- beautifulsoup4
    - provides an interface for querying a webpage to extract the data of interest

for the purposes of this simple example, requests is possibly overkill,
instead using the python builtin urllib package,
although I am sure the interface of requests will shine with a more complex example.

Building a request object.
- we want to get the number of likes from a facebook page
- navigate to page manually
- address is `facebook.com/pg/thelancerband/community`
    - `thelancerband` is the bit that changes for each page
- `page='thelancerband'; request.get(f'facebook.com/pg/{page}/community')`

Extracting page views
- it is rather fortunate the page is rather sparse of content
- Beatufulsoup allows for searching for text
- can also navigate within the document structure with `.parent` and `.previous`
    - We use this to get the number of page views


Understanding the page views.
- The number that is returned is in a more human readable format
    - 365K
    - 125,225
- To convert to an integer we need to parse these numbers
    - there is a library `humanfriendly` which can parse these numbers
    - the commas have to be removed though


With all this working for a single page now apply to a number of pages.
- This is a simple for loop
- The interesting part here is collecting the list of pages from a google doc.
- allow for collaboration/ get someone else to do the hard work and update in real time


To download a spreadsheet from Google drive
- `fb_pages_spreadsheet = f"https://docs.google.com/spreadsheets/d/{document_id}/export?format=csv"`
- The document_id is the string 
- this is assuming link sharing, no authentication required



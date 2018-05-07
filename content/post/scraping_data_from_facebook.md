+++
title = "Scraping Data from Facebook"
date = "2018-04-30"

draft = true
math = false
highlight = true
+++

Competition is a strange thing.
I am a member of The Lancer Band, 
a Regimental band of the Australian Army,
and it has become a tradition for us to create a music video for release 
as a component of ANZAC Day commemorations.
These videos have been highly successful
garnering millions of views on Facebook.
These viral successes 
along with some great communication throughout the rest of the year
have resulted in a fairly significant social media following,
especially when compared to other similar pages.

After a successful drive to raise the number of page likes this year,
we became more interested in how we compared to a whole host of other pages,
from other service bands in Australia,
to other units of the Australian Army.
Rather than manually collating this data manually,
I looked to find a solution to how we could automate this process.
Both to have up to date data,
and to be able to capture and store historical data
allowing us to create our own metrics on how we and all the comparable pages are growing.

The method recommended by the internet for getting any data from Facebook 
is through their [GraphAPI][graph-api],
a method of using http requests to get any specific data from a page.
The first step in using the GraphAPI is to get an access token,
the simplest method is by logging into the [GraphAPI Explorer][graph-api explorer],
a web based tool for testing out GraphAPI.
In getting an access token from the GraphAPI Explorer,
a prompt will ask for the permissions granted to the access token.
Uncheck all the permissions as they are not required for this example.
The more permissions granted to an access token,
the more data from the GraphAPI is accessible.
The data field of interest is the `fan_count`,
which is the number of users who like the page,
found in the [documentation][graph-api page ref] under the page reference.

Putting all this together it is possible to query the GraphAPI in python using requests
as in the code example below.

```python
import requests
page = 'thelancerband'
token = '<access_token>'
ret = requests.get(f'https://graph.facebook.com/{page}', params={'fields': 'fan_count', 'access_token': token})
ret.json()['fan_count']
```

Note that you will need to copy the access token 
generated from the [GraphAPI Explorer][graph-api explorer] into the token variable.
At the time of writing [The Lancer Band][thelancerband] has 6546 likes,
which is the value I got when I ran the code snippet above.
Hopefully when you are reading this the result you get is somewhat larger.

While the GraphAPI does have a relatively simple interface for querying
many different types of data,
it has a fairly significant drawback for accessing data over time.
The access tokens that are required for the API calls have a time based expiry,
in the case of the GraphAPI Explorer tokens this expiry is 1 hour.
This means that basically every time I want to perform the data collection
I need to get a new token.
The solution to being able programmatically generate access tokens
is to create a Facebook application.
While this sounds simple enough,
to create an app with the lowest set of permissions 
requires getting the ape reviewed and accepted by Facebook.
Far more work than I want to put into this.
While this is fair enough with all the personal information 
having access to a Facebook profile provides,
I only want to access the publicly available likes data of a page.

With all the restrictions and effort required
to go through the 'proper' methods to obtain this data,
I became really interested in alternate approaches.
As far as I can discern as a python developer from the scientific realm,
some of the key packages for dealing with websites are;

- **[requests][]** for an interface with http requests and responses
- **[beautifulsoup4][]** which provides an interface
    for extracting information from a returned html/xml document.

We are going to use requests to get the page which has the number of likes contained on it,
then use beautifulsoup4 to extract the number we require.

We can get the web address required by navigating Facebook manually,
which is the [community page].
We can get this page using the below code snippet;

```python
import requests
page_name = "thelancerband"
community_page = requests.get(f"https://facebook.com/pg/{page}/community")
```

By changing the `page_name` variable,
most likely in a loop,
we are able to easily loop over many different Facebook pages.

Now we have the html,
we need to extract the number of likes.
Printing the entire returned page

```python
community_page.text
```

and searching for 'Total Likes'

```html
<div class="_3xom">6,546</div><div class="_3xok">Total Likes</div>
```

we find a collection of `div` elements surrounding text of 'Total Likes', and the number of likes.
The number of likes is in the div element prior to that of the div containing the text `Total Likes`.
Beautifulsoup4 allows us to programmatically traverse the document in a similar method.

```python
from bs4 import BeautifulSoup
document = BeautifulSoup(community_page, 'html.parser')
document.find(text='Total Likes').parent.previous
```

Here we are searching for text matching 'Total Likes',
which returns a reference to that value.
The value we want to extract is the content of the previous div element,
by taking the parent element then previous element we extract the value of interest.

This returned value is not in the appropriate format for a straight conversion to an int,
having a comma as the thousands separator and for large numbers using the SI prefixes `k`, `M`, etc...
The quick and dirty method of dealing with the comma is using `str.replace(',', '')`,
though a real project should use the locale module as described on [stackoverflow][locale commas].
A simple fix for the prefixes is installing the [humanfriendly][] package,
which has a function `humanfriendly.parse_size()` which will handle with the prefixes.
This results in the code for getting likes from a list of pages looking like that below.

```python
from bs4 import BeautifulSoup
import humanfriendly
import requests

page_list = [
    "thelancerband",
]

def get_num_likes(page_id):
    community_page = requests.get(f"https://facebook.com/pg/{page_id}/community")
    document = BeautifulSoup(community_page, 'html.parser')
    page_likes = humanfriendly.parse_size(
        document.find(text='Total Likes').parent.previous.replace(',', '')
    )
    return page_likes

for page in page_list:
    print(f'The Facebook page for {page} has {get_num_likes(page)} likes')
```

This will print the results to the screen,
which is not useful for longer term analysis.
There are many different methods for saving this data for later analysis.
I am most familiar with pandas and HDF5 files,
so my loop looked like;

```python
import pandas
data = []
for page in page_list:
    data.append({
        'page_id': page,
        'likes': get_num_likes(page),
        'time': pandas.Timestamp.now(),
    })
df = pandas.DataFraame.from_records(data)
df.set_index('time').to_hdf('likes_data.h5', 'data', format='table', append=True)
```

Note that the `tables` package is also a requirement for this code snippet to work.

This is my first foray into extracting data from websites
for use in data analysis.
With the appropriate tools,
putting together a simple application is relatively painless.
The biggest issue I encountered in this project
was working out how to get a Facebook authentication token.


[graph-api]: https://developers.facebook.com/docs/graph-api
[graph-api explorer]: https://developers.facebook.com/tools/explorer/
[graph-api page ref]: https://developers.facebook.com/docs/graph-api/reference/page
[thelancerband]: https://facebook.com/thelancerband
[thelancerband community]: https://facebook.com/pg/thelancerband/community
[beautifulsoup4]: https://www.crummy.com/software/BeautifulSoup/bs4/doc/
[requests]: http://docs.python-requests.org/en/master/
[locale commas]: https://stackoverflow.com/questions/1779288/how-do-i-use-python-to-convert-a-string-to-a-number-if-it-has-commas-in-it-as-th
[humanfriendly]: https://pypi.org/project/humanfriendly/

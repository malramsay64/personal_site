+++
title = "The Ultimate Marching Playlist"
date = "2017-11-25"
draft = true

math = true
highlight = true
+++

Marching has long been associated with the movement of
large groups of people from one location to another,
often accompanied by music to both
keep the group moving together and to keep the morale high.
Today the march is most associated with the military
which maintains much of the history of marching,
including the music that is played on the march
which often dates back nearly a century.
What would today's marching playlist look like?
In particular for the Sydney Mardis Gras parade.


We need a few songs that would be suitable to play,
so rather than sit down and brainstorm
I had a different idea.
Spotify collects a wide range of metadata
for each of the songs in it's library,
from standard metrics to the length of the song and the artist,
to more unusual metrics like tempo, danceability and energy.
These more unusual metrics are computed by Spotify to
help them suggest songs that are suited to your interests.
They are also accessible to any developers using [Spotify's API][spotify_api].

Since I wasn't super keen on working out how to write http requests,
I looked to another solution.
As a python developer I quickly came across [Spotipy][spotipy_docs]
which handles all the http requests so that you don't have to.
So now I just have to work out how to use it.

Using Spotipy
-------------

To access all of the available capability of the Spotify API,
as a developer you need to register your app,
and as a user you need to log in.
Since the full capability involves interacting as a logged in user
I guess that is reasonable enough.
However there is information you can get without registering anything.

The installation of Spotipy is simply

    pip install spotipy



There are a few different ways of interacting with a



The official quick march tempo for the Australian Defence Force
is 116 beats per minute.

[spotify_api]: https://developer.spotify.com/web-api/user-guide/
[spotipy_docs]: https://spotipy.readthedocs.io/en/latest/

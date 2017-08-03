+++
title = "Click: The right tool for the job"
date = "2017-08-04"
draft = true

math = true
highlight = true
+++

There are times when you have a problem that needs solving,
but you don't have the tool to solve it.
There are other times where you have found a tool you want to use
but no problem to use it on.
Then there are the magical times when a problem and tool just fall into your lap at the same time.

## The Problem

I have been using [vimwiki](https://github.com/vimwiki/vimwiki) Vimwiki for my PhD logbook.
This is awesome for taking text based notes and including code and latex math typesetting.
Including figures in the wiki was turning out to be a pain,
I had to copy the figure to an images directory,
then link to it from the wiki.
A process that was not conducive to me actually including the figures.
However, since it is entirely text based I can just hack my own tools.

I wanted a command line utility that;
1. is callable from anywhere,
2. move file to common directory,
3. rename the file using the date and a short description, and
4. add a link to the file in vimwiki along with a long description

## The Solution



    @click.argument('filename', type=click.Path(exists=True))
    @click.option('--short-desc', prompt='Short Description for filename',
                  help='Description to put into filename')
    @click.option('--long-desc', prompt='Long description for caption',
                  help='Description for caption')


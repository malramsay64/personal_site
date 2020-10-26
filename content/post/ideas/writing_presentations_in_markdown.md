+++
title = "Writing Presentations in Markdown"
date = 2019-08-28

draft = true

[taxonomies]
tags = ["markdown", "writing"]
+++

When developing a presentation,
(or blog post)
typically my first step is
to flesh out the idea using dot points.
Creating a rough structure
which can then be formulated
into some kind of narrative.
Occasionally I will start this on paper,
however, invariably my ideas end up in a text document,
typically in the markdown format.

- I want to use Markdown for presentations
    - I am used to using beamer

- Pandoc allows this
    - fairly simple syntax

- For more complicated presentations there are issues
    - beyond some dot points on a slide

## Complicated things

Columns
- Really nice to have dot points next to an image
- multiple images next to each other

- Using ::: syntax for column environment
    - Example from the documentation, including links
    - Just need at least 3
    - no requirement for matching
    - Specifying widths

Incremental
- pauses
    - location within columns
- dot points

Citations
- Citations as a footnote
    - For reference footnotes have syntax `[^1]`
- Where you got an image or data from
- unobtrusive yet present
- Use a CSL definition
    - Here's one I prepared earlier
        - Important part is the note definition
    - How to modify for various changes
        - Removing bibliography
        - Changing out the theme
        - Modifying using the CSL editor
    - Creating a note style for any CSL

Custom Themes
- I have created a custom beamer theme which I want to use
- LaTeX doesn't deal with additional paths well
    - have to add `\searchpath`
    - This can be done in the after includes
    - have to set theme there

Custom preamble
- The default latex theme has many utilities defined
    - what if you want your own?
    - your commands defining helper functions
- Instead of letting pandoc do all the work, split into two steps
    - Pandoc converts document to latex
    - Use `\include` or `\input` to include the generated latex script into your
- There are a few things which need to be defined
    - `\tightlist`
    - usepackage
    - Gin

Larger font size
- I like minimalist slides, so want a larger font size
- Use extsizes packages (incorrectly noted in beamer documentation)

Centering Images
- all images

Reverting to latex
- There are some things only possible in latex
- so use latex where required

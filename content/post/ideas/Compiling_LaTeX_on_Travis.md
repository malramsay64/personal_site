+++
title = "Compiling LaTeX on Travis-CI"
date = "2018-07-16"

draft = true
math = true
highlight = true
+++

- Introduction to CI/CD
    - Why it is used in code
    - Why it can be useful for LaTeX docs

- Challenges for LaTeX
    - The complete TeXLive distribution takes forever to download
    - No simple way of specifying and updating the packages required
    - NO CI provider offers a complete LaTeX environment
        - closest is the R container on Travis CI
        - only offers the base packages

- Solutions
    - TeXLive 
        - too large to download completely
        - have to manually spec packages to download
        - Is installable using apt assuming you have the correct packages
            - You have to perform the entire installation each time
        - Docker container
            - Large image

    - MikTex
        - Docker image available
        - Can download required packages automatically
        - Biber is only supported on Windows
            - I don't want to try and deal with CI in windows

    - Tectonic
        - A relatively new project
        - Complete standalone (nearly) binary
        - Installable using conda
        - Downloads required packages automatically
        - No support for biber

    - There are no really good solutions for compiling latex documents using CI
        - at least none that I have found

- MY solution
    - Of the options above I like tectonic the best
        - Installable using conda
            - package manager I use for all the rest of my code
            - Really easy to use and install
            - I have travis scripts already using conda
        - Pandoc is also installable using conda
            - The workflow for LaTeX I want is markdown to .tex to .pdf
                - or just skip the tex part
            - Pandoc does the conversion, either to .tex or straight to .pdf using latex
        - Biber download binary from sourceforge

- Code

- Deployment
    - With the document compiling, how do we save it somewhere useful
    - Travis-CI deployments
        - I am deploying to GitHub to keep everything in a single location
        - can also deploy to others https://docs.travis-ci.com/user/deployment
        - or just use a script to upload somewhere
            - make sure to not include your credentials
    - I have chosen to use github releases
        - every time I tag a commit `git tag <tag>` a new version is uploaded to the releases
        - I am using a semver like approach so my tags are `v0.1.0`, `v0.1.1` ...
        - This keeps every historical release so you can go back in time
        - When I tag a commit, I also update a version number in the document, which is on the
            footer of every page.
            - This keeps continuity of versions even with printed documents

- Conclusion
    - This should work for almost all latex Documents
    - Tectonic compiles using xetex for unicode and font support


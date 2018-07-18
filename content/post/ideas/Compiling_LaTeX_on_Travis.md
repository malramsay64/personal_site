+++
title = "Compiling LaTeX on Travis-CI"
date = "2018-07-16"
draft = true
math = true
highlight = true
+++

One of the best parts of the current software development environment is the proliferation of
Continuous Integration (CI) services like [Travis-CI]. These CI services plug into GitHub or other
code repositories to automatically run when new code is pushed to a repository. Typically CI is
used for running automated testing every time new code is added so you can be reasonably confident
that a change hasn't broken any functionality. The premise of CI is taking tedious tasks like
running tests and automating them.

When writing a LaTeX document the most tedious task is running the compilation step. Particularly
for large documents it can take a long time and when you only run the compilation irregularly
there are invariably a whole collection of errors that have accumulated. Additionally the
compilation of LaTeX documents is often highly machine dependent, only compiling properly on your
machine for some unknown reason. The final issue with LaTeX documents is ensuring that all the
files required for the compilation are included in the repository and not just hiding in a
directory somewhere on your local filesystem.

As a way of getting around these issues in the write-up of my PhD thesis, I have developed a
configuration for building LaTeX documents on Travis-CI. While I have found other methods for
compiling LaTeX documents on Travis-CI, all the other methods I have found have compromises. I
want a system that is;

- *fast*, with builds completing in a couple of minutes
- *adaptable*, not having to manually specify every package I use
- *extensible*, I can easily use [pandoc] to convert files to LaTeX before compilation
- uses `biber`, the best practice for compiling the references

## Choosing a LaTeX Distribution

There are a number of different methods to get a distribution of LaTeX installed. The main method
for Linux is the TeXLive distribution which is typically installed via the package manager. The
base TeXLive distribution is pre-installed on the Travis-CI image for A. However, this is only the
core extensions and so this approach is either *fast* in that the image just boots up, or
*adaptable* by downloading `texlive-full` which takes a long time.

The key issue I had with the TeXLive distribution was the lack of automatically downloading
required packages. A LaTeX distribution that does download packages automatically is [MiKTeX],
which has an installer that is only 200 MB compared to the ~3 GB of the complete TeXLive. MiKTeX
also provides a [docker container][MiKTeX docker] which is a great method of having exactly the
same environment for compiling locally and with a CI service. Unfortunately MiKTeX doesn't install
the `biber` binary on Linux (or macOS)[^1]. While it is possible to create a new Docker which does
include the `biber` binary, this deficiency highlights that extending a Docker container is
non-trivial which makes this approach less favourable. That said, for other Docker-centric CI
services this could be an excellent approach.

Another much less well known and newer LaTeX distribution is [Tectonic] which is still considered
beta software. However, it works for most scenarios and it has a lot of features that make it
suitable for CI. I would recommend installation with [conda][Tectonic conda] although there are a
range of [installation methods][Tectonic install] for both Linux and macOS (currently no Windows
support). Like MiKTeX, Tectonic will automatically download all the packages required to compile a
document, making the same configuration *adaptable* to many different configurations. Having conda
as an installation method is also really useful, allowing a simple installation of many other
tools (like [pandoc]) which are required to compile a document. The only requirement not satisfied
by Tectonic is the automatic installation of `biber`. Although not supported natively, it is
[possible to use biber with tectonic][Tectonic #53] as long as the binary for biber 2.5 is
installed from [Sourceforge][biber 2.5].

### Compiling Documents with Tectonic

```Makefile
# makefile

# directory to put build files
build_dir := output

.PHONY: all

all: document.pdf

%.pdf: %.tex | $(build_dir)
	tectonic -o $(build_dir) --keep-intermediates -r0 $<
	if [ -f $(build_dir)/$(notdir $(<:.tex=.bcf)) ]; then biber2.5 --input-directory $(build_dir) $(notdir $(<:.tex=)); fi
	tectonic -o $(build_dir) --keep-intermediates $<
	cp $(build_dir)/$(notdir $@) .

$(build_dir):
	mkdir -p $@
```

If you want to continue using your standard latex build tool locally which in my case is `latexmk`,
you can check whether the `TRAVIS` environment variable is defined as in the example below.

```makefile
%.pdf: %.tex | $(build_dir)
ifdef TRAVIS
	tectonic -o $(build_dir) --keep-intermediates -r0 $<
	if [ -f $(build_dir)/$(notdir $(<:.tex=.bcf)) ]; then biber2.5 --input-directory $(build_dir) $(notdir $(<:.tex=)); fi
	tectonic -o $(build_dir) --keep-intermediates $<
else
	latexmk -outdir=$(build_dir) -pdf $<
endif
	cp $(build_dir)/$(notdir $@) .
```

The `TRAVIS` environment variable is defined on all Travis instances and to test the code locally
you can use the command

```bash
TRAVIS=true make
```

which sets the variable for that command. Note that you will want to run a `make clean` between
running with the different build systems since there will be some incompatibility with version
numbering.

## Configuring Travis CI

With a LaTeX distribution that is suitable for CI in [Tectonic], how do I actually use Travis CI?

1. Create a public repository on GitHub. Travis CI only works with GitHub and while it does work
   with private repositories they requires a paid account with Travis.
2. Using your GitHub account, sign in to [GitHub][travis-ci app] and add the Travis CI app to the
   repository you want to activate. You'll need Admin permissions for that repository.
3. Once signed in to Travis CI, go to your profile page and enable the repository you want to
   build.
4. Create a `.travis.yml` file in the repository which tells Travis CI what to do. What you need
   to put in the file is addressed [below]({{ <ref "#travis.yml"}}).

### Creating a .travis.yml file {#travis.yml}

The [`.travis.yml`][travis.yml file] I have developed are linked for download and are
also explained below.

```yaml
# .travis.yml
language: generic

cache:
  directories:
    - $HOME/.cache/Tectonic
    - $HOME/miniconda
    - $HOME/downloads

before_install:
  - mkdir -p $HOME/downloads
  - mkdir -p $HOME/bin

  # Download and install biber installing executable as biber2.5
  - |
    if [ ! -f $HOME/downloads/biber.tar.gz ]; then
      wget https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.5/binaries/Linux/biber-linux_x86_64.tar.gz -O $HOME/downloads/biber.tar.gz
    fi
  - tar xvzf $HOME/downloads/biber.tar.gz -C $HOME/bin
  - mv $HOME/bin/biber $HOME/bin/biber2.5
  - export PATH="$HOME/bin:$PATH"

  # Download and install conda
  - |
    if [ ! -f $HOME/downloads/miniconda.sh ]; then
      wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $HOME/downloads/miniconda.sh
    fi
  - bash $HOME/downloads/miniconda.sh -b -u -p $HOME/miniconda
  - export PATH="$HOME/miniconda/bin:$PATH"
  - hash -r

    # Install tectonic
  - conda install -y -c conda-forge tectonic

script:
  - make
```


6. Add the `.travis.yml` file to the repository and 

## Deploying to GitHub Releases

5. Install the travis [command line client][travis.rb] which will be used to configure 

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
    - This should work for most latex Documents
    - Tectonic compiles using xetex for unicode and font support

[^1]: I should note that MiKTeX will install `biber` on a Windows system. So if you wanted to set
    up a Windows CI config I guess MiKTeX is a great approach.

[Tectonic conda]: https://tectonic-typesetting.github.io/en-US/install.html#the-anaconda-method
[Tectonic install]: https://tectonic-typesetting.github.io/en-US/install.html
[Tectonic #53]: https://github.com/tectonic-typesetting/tectonic/issues/53
[biber 2.5]: https://sourceforge.net/projects/biblatex-biber/files/biblatex-biber/2.5/binaries/
[travis-ci getting started]: https://docs.travis-ci.com/user/getting-started/
[travis-ci app]: https://github.com/marketplace/travis-ci/plan/MDIyOk1hcmtldHBsYWNlTGlzdGluZ1BsYW43MA==#pricing-and-setup
[travis.rb]: https://github.com/travis-ci/travis.rb#installation

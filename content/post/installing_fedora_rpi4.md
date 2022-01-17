+++
title = "Installing Fedora 35 on Raspberry Pi 4"
date = 2022-01-08

draft = true

[taxonomies]
tags = ["fedora"]
+++

I have found the installation of Fedora on a Raspberry Pi to be
an incredibly difficult process,
with many of the approaches I have tried not working for some reason.
This documents the process that ended up working for me,
along with many of the approaches that didn't work.

## Installation Process

Unlike standard hardware like a server or desktop,
there are a number of steps in the installation process.
This is because the Raspberry Pi doesn't come with a standard UEFI bios
we can to boot from to boot from an installer USB.
Normally this would allow us to boot from a USB stick to enable the installation,
however, on the Raspberry Pi we first need to install the UEFI firmware.

### Standard install

The latest version of Fedora for the aarch64 architecture
used by the Raspberry Pi 4 is available on the [Fedora Downloads](https://getfedora.org/en/workstation/download/) site.
There are two downloads for aarch64,

1. an aarch64 DVD ISO, and
2. an aarch64 raw image.

We need second of those, the aarch64 raw image.
The raw image can be installed on a MicroSD card
and _should_ provide a working installation of Fedora.
I was unable to get a functional installation using this approach,
however this should work.

To get the raw image onto the MicroSD card we can use the `arm-image-installer` utility,
which is available as part of the fedora distribution through `dnf`.
Running

```sh
dnf install arm-image-installer
```

will ensure it is installed locally.
Once installed we can use it to configure the installation.

To find the appropriate path of the MicroSD card,
we can run the command

```sh
sudo fdisk -l
```

and finding the drive matching the size of the MicroSD card.
For me this is `/dev/sda` since I have an NVMe boot drive on my local computer.
Make sure to double check the drive path, since you don't want to overwrite your local boot drive.
With the appropriate drive path found, replace `<MicroSD Card>` with the path.

```sh
sudo arm-image-installer --image=Downloads/Fedora-Workstation-35-1.2.armhfp.raw.xz --target=rpi4 --media=<MicroSD Card> --resizefs
```

where;
- the image is the file we downloaded,
- the target is the device we want to use with the MicroSD card
  in this case a Raspberry Pi 4 (rpi4).
- The media is where we are writing the data to
- and `--resizefs` tells `arm-image-installer` to expand the storage to fill the media,
  making the entire drive usable when booted up.

Once these steps are completed,
we can try running the drive on a Raspberry Pi.
Insert the drive, connect up the power and monitor,
and everything should boot up fine,
giving the initial configuration screen for Fedora.

Unfortunately in my case, I was unable to go through the configuration,
with my keyboard unresponsive upon reaching the configuration screen.
Because I was unable to continue through the installation,
I had to take an alternative approach.

### Installing UEFI Firmware

With the raw image not working,
I had to take an alternate approach for the installation.
The alternative download to the RAW image was the DVD ISO,
so that was my next approach.
However, as mentioned earlier,
the Raspberry PI doesn't ship with the UEFI bootloader we need
to get the DVD ISO installed.
Fortunately however, we can download one.
The UEFI firmware that we need is available in the [releases](https://github.com/pftf/RPi4/releases/latest)
of the [pftf/RPi4](https://github.com/pftf/RPi4) GitHub repository.
The `.zip` file should be downloaded onto your local machine.

The instructions listed describe creating a FAT32 partition for the firmware
however, it just so happens that when we created the RAW image,
we have also created all the partitions we need for this step already.
Putting the SD card back into the computer that is working,
you should see three partitions on the drive.
A large one that close to the total capacity of the SD card,
which will be the root partition and is where all the Fedora OS is installed.
This will contain many folders including those named `dev`, `etc`, `home`, `sys`, and `proc`.
There will be a drive about 1.1 GB which is where the OS Kernel is installed,
this will include folders like `dtb`, `grub2`, `loader`.
The final directory is the one we want,
which appears for me as 629 MB in size;
containing a number of `.elf` files.
The zip file with the UEFI firmware can be extracted to this drive,
replacing any of the files that are already there.

With the bootloader installed onto the drive,
we now have a UEFI firmware.
This can be checked by inserting the MicroSD card
into the Raspberry Pi and booting it up.
It will now provide options for how you want to boot the Pi.

While you are here,
it is a good idea to remove the 3GB memory limit.
This is imposed to ensure support for older kernels,
however using Fedora 35 is new enough to not cause any issues.

### Installing the DVD ISO

To install the DVD image onto our Pi,
we first need to download the DVD ISO,
which is available at the same [Fedora Downloads](https://getfedora.org/en/workstation/download/) link as above.
However, this time we need the first link for the DVD ISO.

The simplest method to get this ISO onto Fedora Workstation onto a USB
is to use the Fedora Media Writer utility,
which can be installed using `dnf`

```sh
dnf install fedora-media-writer
```

Running Fedora Media Writer we need to select the downloaded image.

## Why all this Effort?

The key reason for choosing Fedora is because I am familiar with it
and the tooling and versions are consistent across the rest of my workspaces.
Additionally I have been playing around with Rust and want to compile my code
for the aarch64 architecture.
This means that the standard Raspberry Pi OS is not appropriate,
only being the 32 rather than 64 bit architecture.

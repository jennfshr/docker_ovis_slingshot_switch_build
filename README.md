# Slingshot Switch Sampler LDMS DPKG Package Build in a Docker Debian Container

## Jennifer Green <jkgreen@sandia.gov> (inspired by Cory Lueninghoener's original documentation)

This is a rather simple implementation of a docker build of a Debian Package and run invocation on a Macintosh Apple M2 Max.

No positional parameters are supplied to the script, but it will prompt for a docker username and password to authenticate to the docker registry.
In order for me to pull from the docker registry, I had to disconnect from the VPN.

The successful execution of the script will output the following execution trace of the docker build steps and a print statement directing the user to the resulting tarball on their desktop.

![image](https://github.com/user-attachments/assets/a8f502a8-4292-496b-835a-b6746fbba110)


# WSL-Kernel-Configuration
My personal configuration for building WSL kernels.

## Installation

Clone this repo...

```
gh repo clone cerebrate/WSL-Kernel-Configuration
```

...into a directory peer to the `linux` directory of a fresh kernel tree.

From inside the WSL-Kernel-Configuration directory, run:

```
patch-peer-kernel
```

Switch to the `../linux` directory and build the kernel packages as normal.

If you change `.config` or `localversion`, for example using `make xconfig`, do not forget to copy them back to `../WSL-Kernel-Configuration` afterwards.


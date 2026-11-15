# WSL hv_pci swiotlb ("virtio performance") patches, forward-ported to 7.3

These are the two commits from Microsoft's `linux-msft-wsl-6.18.y` branch
(microsoft/WSL2-Linux-Kernel) that the Nov 14 reply on WSL discussion #41573
pointed to, ported onto Linux 7.2.15 and then onto Linux 7.3:

| File | Upstream WSL commit | What it does |
|---|---|---|
| `02-swiotlb-hyperv.patch` | `faef3e1b156a` (Asher Kariv) | Adds `swiotlb_create_pool()` and lets the Hyper-V PCI driver bounce all VPCI device DMA through a dedicated pool |
| `03-pci-hv-reserve.patch` | `81447f0ea110` (Ben Hillis) | Allocates that pool in the guest (64 MiB, below 4 GiB, via `alloc_contig_pages`), takes `hv_pci_swiotlb=<size>`, and publishes it at `/sys/bus/vmbus/drivers/hv_pci/swiotlb_{base,size}` |

Both commits were confirmed to be on that branch in the official repo.

## How WSL uses it

From WSL's own source: when virtiofs, virtio-9p or consomme networking is in
use, WSL adds `hv_pci_swiotlb=<bytes>` (64 MiB by default) to the kernel command
line, then reads the two sysfs files. If they are missing, you get the
"missing a patch that significantly improves virtio device performance"
warning. So no manual command-line changes are needed.

## Porting notes

### 7.3

These patches are no longer Microsoft's code unchanged:

- 7.3 swiotlb tracks whether a pool's memory is shared (decrypted) with the
  host for confidential-computing guests (`io_tlb_mem.cc_shared`). It refuses
  mappings from a pool whose flag does not match the device. In
  `swiotlb_create_pool()`, patch 02 now follows the restricted-DMA-pool code: it
  decrypts the region and sets `cc_shared` only when
  `cc_platform_has(CC_ATTR_MEM_ENCRYPT)`, and returns `-EIO` if decryption
  fails. On an ordinary (non-confidential) WSL VM this behaves exactly as
  before. Without it, a confidential guest would fail every mapping.
- On `-EIO`, patch 03 leaks the pool pages instead of calling
  `free_contig_range()`, because their encryption state is unknown.
- Patch 03 also had a context conflict: 7.3 sets
  `.driver.probe_type = PROBE_PREFER_ASYNCHRONOUS` in `hv_pci_drv`. That is
  harmless here because the pool is created in a `core_initcall`, before any
  probe.
- Each commit message has a `[ Forward port to 7.3 ]` note.

### 7.2

- Conflicts were context only. 7.2's `init_hv_pci_drv()` no longer has the
  `hv_root_partition()` check, and the restricted-pool `RESERVEDMEM_OF_DECLARE`
  line in `kernel/dma/swiotlb.c` changed. The code itself is unchanged from
  Microsoft's version.
- The 7.2 APIs the patches lean on (`alloc_contig_pages`, `free_contig_range`,
  `swiotlb_init_io_tlb_pool`, `DRIVER_ATTR_RO`) still have the same signatures,
  and `alloc_contig_pages` still accepts `__GFP_DMA32 | __GFP_ZERO`.
- Original authorship and sign-offs are kept; each commit message has a
  `[ Forward port to 7.2.15 ]` note. Add your own Signed-off-by if you want one.

## Config requirements

- `CONFIG_PCI_HYPERV=y`. It must be built in: the cmdline parser and the pool
  allocation are compiled out of module builds, which quietly fall back to the
  default swiotlb. This also needs `CONFIG_HYPERV_VMBUS=y`.
- `CONFIG_CONTIG_ALLOC=y`, which you get from `COMPACTION` + `MEMORY_ISOLATION`, or from `CMA`.


After booting the new kernel:

```
dmesg | grep -i 'hv_pci.*swiotlb'
cat /sys/bus/vmbus/drivers/hv_pci/swiotlb_base /sys/bus/vmbus/drivers/hv_pci/swiotlb_size
```

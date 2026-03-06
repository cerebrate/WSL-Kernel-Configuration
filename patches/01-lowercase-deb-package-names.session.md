# 🤖 Copilot CLI Session

> **Session ID:** `2230af76-8ea6-4f7f-b3b8-6c63b29169c8`
> **Started:** 3/5/2026, 6:55:43 PM
> **Duration:** 9m 41s
> **Exported:** 3/5/2026, 7:05:25 PM

<sub>⏱️ 0s</sub>

### ℹ️ Info

💡 No copilot instructions found. Run /init to generate a copilot-instructions.md file for this project.

---

<sub>⏱️ 2s</sub>

### ℹ️ Info

Environment loaded: 1 MCP server

---

<sub>⏱️ 2m 20s</sub>

### 👤 User

This repository contains the source code for the Linux kernel. The primary makefile builds Debian packages for the kernel when `make deb-pkg` is executed. Please familiarize yourself with this packaging process. (Do not concern yourself with the prior building process, which works satisfactorily; the work we need to do is only in the packaging section.)

---

<sub>⏱️ 2m 22s</sub>

### 💭 Reasoning

*The user wants me to familiarize myself with the Debian packaging process in this Linux kernel repository. Let me explore the relevant files.*

---

<sub>⏱️ 2m 28s</sub>

### 📦 task (Completed)

### 💬 Copilot

I'll help you explore the Debian packaging process in the Linux kernel. Let me start with parallel searches to understand the structure and flow.

### ✅ `grep`

**/wrk/avatar/src/linux**

"deb-pkg" (/wrk/avatar/src/linux)

<details>
<summary>7 matches</summary>

```
/wrk/avatar/src/linux/.gitignore
/wrk/avatar/src/linux/scripts/Makefile.package
/wrk/avatar/src/linux/Documentation/kbuild/kbuild.rst
/wrk/avatar/src/linux/Documentation/translations/zh_CN/kbuild/kbuild.rst
/wrk/avatar/src/linux/Documentation/admin-guide/verify-bugs-and-bisect-regressions.rst
/wrk/avatar/src/linux/Documentation/admin-guide/quickly-build-trimmed-linux.rst
/wrk/avatar/src/linux/arch/s390/Makefile
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/package.**

/wrk/avatar/src/linux/scripts/package

<details>
<summary>10 lines</summary>

```
PKGBUILD
builddeb
buildtar
debian
gen-diff-patch
install-extmod-build
kernel.spec
mkdebian
mkspec
snapcraft.template
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian.**

/wrk/avatar/src/linux/debian

<details>
<summary>13 lines</summary>

```
arch
changelog
control
copyright
files
headers.files
image-dbg.files
image.files
libc-dev.files
patches
rules
rules.vars
source
```

</details>


### ✅ `glob`

**/wrk/avatar/src/linux**

"scripts/package/**/*" in /wrk/avatar/src/linux

<details>
<summary>11 matches</summary>

```
/wrk/avatar/src/linux/scripts/package/snapcraft.template
/wrk/avatar/src/linux/scripts/package/gen-diff-patch
/wrk/avatar/src/linux/scripts/package/install-extmod-build
/wrk/avatar/src/linux/scripts/package/kernel.spec
/wrk/avatar/src/linux/scripts/package/PKGBUILD
/wrk/avatar/src/linux/scripts/package/debian/copyright
/wrk/avatar/src/linux/scripts/package/debian/rules
/wrk/avatar/src/linux/scripts/package/buildtar
/wrk/avatar/src/linux/scripts/package/mkspec
/wrk/avatar/src/linux/scripts/package/mkdebian
/wrk/avatar/src/linux/scripts/package/builddeb
```

</details>


### ✅ `glob`

**/wrk/avatar/src/linux**

"debian/**/*" in /wrk/avatar/src/linux

```
No files matched the pattern.
```


### 💬 Copilot

Now let me examine the key Makefile that defines deb-pkg and the builddeb script:

### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/Makefile.package.**

/wrk/avatar/src/linux/scripts/Makefile.package

<details>
<summary>286 lines</summary>

```
1. # SPDX-License-Identifier: GPL-2.0-only
2. # Makefile for the different targets used to generate full packages of a kernel
3. 
4. include $(srctree)/scripts/Kbuild.include
5. include $(srctree)/scripts/Makefile.lib
6. 
7. # Git
8. # ---------------------------------------------------------------------------
9. 
10. filechk_HEAD = git -C $(srctree) rev-parse --verify HEAD 2>/dev/null
11. 
12. .tmp_HEAD: check-git FORCE
13. 	$(call filechk,HEAD)
14. 
15. PHONY += check-git
16. check-git:
17. 	@if ! $(srctree)/scripts/check-git; then \
18. 		echo >&2 "error: creating source package requires git repository"; \
19. 		false; \
20. 	fi
21. 
22. git-config-tar.gz   = -c tar.tar.gz.command="$(KGZIP)"
23. git-config-tar.bz2  = -c tar.tar.bz2.command="$(KBZIP2)"
24. git-config-tar.lzma = -c tar.tar.lzma.command="$(LZMA)"
25. git-config-tar.xz   = -c tar.tar.xz.command="$(XZ)"
26. git-config-tar.zst  = -c tar.tar.zst.command="$(ZSTD)"
27. 
28. quiet_cmd_archive = ARCHIVE $@
29.       cmd_archive = git -C $(srctree) $(git-config-tar$(suffix $@)) archive \
30.                     --output=$$(realpath $@) $(archive-args)
31. 
32. suffix-gzip  := .gz
33. suffix-bzip2 := .bz2
34. suffix-lzma  := .lzma
35. suffix-xz    := .xz
36. 
37. # Linux source tarball
38. # ---------------------------------------------------------------------------
39. 
40. linux-tarballs := $(addprefix linux, .tar.gz .tar.bz2 .tar.lzma .tar.xz)
41. 
42. targets += $(linux-tarballs)
43. $(linux-tarballs): archive-args = --prefix=linux/ $$(cat $<)
44. $(linux-tarballs): .tmp_HEAD FORCE
45. 	$(call if_changed,archive)
46. 
47. # rpm-pkg srcrpm-pkg binrpm-pkg
48. # ---------------------------------------------------------------------------
49. 
50. quiet_cmd_mkspec = GEN     $@
51.       cmd_mkspec = $(srctree)/scripts/package/mkspec $@
52. 
53. rpmbuild/SPECS/kernel.spec: FORCE
54. 	$(call cmd,mkspec)
55. 
56. PHONY += rpm-sources
57. rpm-sources: linux.tar.gz
58. 	$(Q)mkdir -p rpmbuild/SOURCES
59. 	$(Q)ln -f linux.tar.gz rpmbuild/SOURCES/linux.tar.gz
60. 	$(Q)cp $(KCONFIG_CONFIG) rpmbuild/SOURCES/config
61. 	$(Q)$(srctree)/scripts/package/gen-diff-patch rpmbuild/SOURCES/diff.patch
62. 
63. PHONY += rpm-pkg srcrpm-pkg binrpm-pkg
64. 
65. ifneq ($(CC),$(HOSTCC))
66. rpm-no-devel = --without=devel
67. endif
68. 
69. rpm-pkg:    private build-type := a
70. srcrpm-pkg: private build-type := s
71. binrpm-pkg: private build-type := b
72. 
73. rpm-pkg srcrpm-pkg: rpm-sources
74. rpm-pkg srcrpm-pkg binrpm-pkg: rpmbuild/SPECS/kernel.spec
75. 	+$(strip rpmbuild -b$(build-type) rpmbuild/SPECS/kernel.spec \
76. 	--define='_topdir $(abspath rpmbuild)' \
77. 	$(if $(filter a b, $(build-type)), \
78. 		--target $(UTS_MACHINE)-linux --build-in-place --noprep --define='_smp_mflags %{nil}' \
79. 		$$(rpm -q rpm >/dev/null 2>&1 || echo --nodeps) \
80. 		$(rpm-no-devel)) \
81. 	$(RPMOPTS))
82. 
83. # deb-pkg srcdeb-pkg bindeb-pkg
84. # ---------------------------------------------------------------------------
85. 
86. KDEB_SOURCE_COMPRESS ?= gzip
87. 
88. supported-deb-source-compress := gzip bzip2 lzma xz
89. 
90. PHONY += linux.tar.unsupported-deb-src-compress
91. linux.tar.unsupported-deb-src-compress:
92. 	@echo "error: KDEB_SOURCE_COMPRESS=$(KDEB_SOURCE_COMPRESS) is not supported. The supported values are: $(supported-deb-source-compress)" >&2
93. 	@false
94. 
95. debian-orig-suffix := \
96.     $(strip $(if $(filter $(supported-deb-source-compress), $(KDEB_SOURCE_COMPRESS)), \
97.     $(suffix-$(KDEB_SOURCE_COMPRESS)),.unsupported-deb-src-compress))
98. 
99. quiet_cmd_debianize = GEN     $@
100.       cmd_debianize = $(srctree)/scripts/package/mkdebian $(mkdebian-opts)
101. 
102. debian: FORCE
103. 	$(call cmd,debianize)
104. 
105. PHONY += debian-orig
106. debian-orig: private source = $(shell dpkg-parsechangelog -S Source)
107. debian-orig: private version = $(shell dpkg-parsechangelog -S Version | sed 's/-[^-]*$$//')
108. debian-orig: private orig-name = $(source)_$(version).orig.tar$(debian-orig-suffix)
109. debian-orig: mkdebian-opts = --need-source
110. debian-orig: linux.tar$(debian-orig-suffix) debian
111. 	$(Q)if [ "$$(df  --output=target .. 2>/dev/null)" = "$$(df --output=target $< 2>/dev/null)" ]; then \
112. 		ln -f $< ../$(orig-name); \
113. 	else \
114. 		cp $< ../$(orig-name); \
115. 	fi
116. 
117. PHONY += deb-pkg srcdeb-pkg bindeb-pkg
118. 
119. deb-pkg:    private build-type := source,binary
120. srcdeb-pkg: private build-type := source
121. bindeb-pkg: private build-type := binary
122. 
123. deb-pkg srcdeb-pkg: debian-orig
124. bindeb-pkg: debian
125. deb-pkg srcdeb-pkg bindeb-pkg:
126. 	+$(strip dpkg-buildpackage \
127. 	--build=$(build-type) --no-pre-clean --unsigned-changes \
128. 	$(if $(findstring source, $(build-type)), \
129. 		--unsigned-source --compression=$(KDEB_SOURCE_COMPRESS)) \
130. 	$(if $(findstring binary, $(build-type)), \
131. 		-R'$(MAKE) -f debian/rules' -j1 -a$$(cat debian/arch), \
132. 		--no-check-builddeps) \
133. 	$(DPKG_FLAGS))
134. 
135. # snap-pkg
136. # ---------------------------------------------------------------------------
137. PHONY += snap-pkg
138. snap-pkg:
139. 	rm -rf $(objtree)/snap
140. 	mkdir $(objtree)/snap
141. 	$(MAKE) clean
142. 	sed "s@KERNELRELEASE@$(KERNELRELEASE)@; \
143. 		s@SRCTREE@$(realpath $(srctree))@" \
144. 		$(srctree)/scripts/package/snapcraft.template > \
145. 		$(objtree)/snap/snapcraft.yaml
146. 	cd $(objtree)/snap && \
147. 	snapcraft --target-arch=$(UTS_MACHINE)
148. 
149. # pacman-pkg
150. # ---------------------------------------------------------------------------
151. 
152. PHONY += pacman-pkg
153. pacman-pkg:
154. 	@ln -srf $(srctree)/scripts/package/PKGBUILD $(objtree)/PKGBUILD
155. 	+BUILDDIR="$(realpath $(objtree))/pacman" \
156. 		CARCH="$(UTS_MACHINE)" \
157. 		KBUILD_MAKEFLAGS="$(MAKEFLAGS)" \
158. 		KBUILD_REVISION="$(shell $(srctree)/scripts/build-version)" \
159. 		makepkg $(MAKEPKGOPTS)
160. 
161. # dir-pkg tar*-pkg - tarball targets
162. # ---------------------------------------------------------------------------
163. 
164. tar-install: FORCE
165. 	$(Q)$(MAKE) -f $(srctree)/Makefile
166. 	+$(Q)$(srctree)/scripts/package/buildtar $@
167. 
168. compress-tar.gz  = -I "$(KGZIP)"
169. compress-tar.bz2 = -I "$(KBZIP2)"
170. compress-tar.xz  = -I "$(XZ)"
171. compress-tar.zst = -I "$(ZSTD)"
172. 
173. quiet_cmd_tar = TAR     $@
174.       cmd_tar = cd $<; tar cf ../$@ $(compress-tar$(suffix $@)) --owner=root --group=root --sort=name *
175. 
176. dir-tarballs := $(addprefix linux-$(KERNELRELEASE)-$(ARCH), .tar .tar.gz .tar.bz2 .tar.xz .tar.zst)
177. 
178. $(dir-tarballs): tar-install
179. 	$(call cmd,tar)
180. 
181. PHONY += dir-pkg
182. dir-pkg: tar-install
183. 	@echo "Kernel tree successfully created in $<"
184. 
185. PHONY += tar-pkg
186. tar-pkg: linux-$(KERNELRELEASE)-$(ARCH).tar
187. 	@:
188. 
189. tar%-pkg: linux-$(KERNELRELEASE)-$(ARCH).tar.% FORCE
190. 	@:
191. 
192. # modules-cpio-pkg - generate an initramfs with the modules
193. # ---------------------------------------------------------------------------
194. 
195. .tmp_modules_cpio: FORCE
196. 	$(Q)$(MAKE) -f $(srctree)/Makefile
197. 	$(Q)rm -rf $@
198. 	$(Q)$(MAKE) -f $(srctree)/Makefile INSTALL_MOD_PATH=$@ modules_install
199. 
200. quiet_cmd_cpio = CPIO    $@
201.       cmd_cpio = $(CONFIG_SHELL) $(srctree)/usr/gen_initramfs.sh -o $@ $<
202. 
203. modules-$(KERNELRELEASE)-$(ARCH).cpio: .tmp_modules_cpio
204. 	$(call cmd,cpio)
205. 
206. PHONY += modules-cpio-pkg
207. modules-cpio-pkg: modules-$(KERNELRELEASE)-$(ARCH).cpio
208. 	@:
209. 
210. # perf-tar*-src-pkg - generate a source tarball with perf source
211. # ---------------------------------------------------------------------------
212. 
213. .tmp_perf:
214. 	$(Q)mkdir .tmp_perf
215. 
216. .tmp_perf/HEAD: .tmp_HEAD | .tmp_perf
217. 	$(call cmd,copy)
218. 
219. quiet_cmd_perf_version_file = GEN     $@
220.       cmd_perf_version_file = cd $(srctree)/tools/perf; util/PERF-VERSION-GEN $(dir $(abspath $@))
221. 
222. # PERF-VERSION-FILE and .tmp_HEAD are independent, but this avoids updating the
223. # timestamp of PERF-VERSION-FILE.
224. # The best is to fix tools/perf/util/PERF-VERSION-GEN.
225. .tmp_perf/PERF-VERSION-FILE: .tmp_HEAD $(srctree)/tools/perf/util/PERF-VERSION-GEN | .tmp_perf
226. 	$(call cmd,perf_version_file)
227. 
228. perf-archive-args = --add-file=$$(realpath $(word 2, $^)) \
229. 	--add-file=$$(realpath $(word 3, $^)) \
230. 	$$(cat $(word 2, $^))^{tree} $$(cat $<)
231. 
232. 
233. perf-tarballs := $(addprefix perf-$(KERNELVERSION), .tar .tar.gz .tar.bz2 .tar.xz .tar.zst)
234. 
235. targets += $(perf-tarballs)
236. $(perf-tarballs): archive-args = --prefix=perf-$(KERNELVERSION)/ $(perf-archive-args)
237. $(perf-tarballs): tools/perf/MANIFEST .tmp_perf/HEAD .tmp_perf/PERF-VERSION-FILE FORCE
238. 	$(call if_changed,archive)
239. 
240. PHONY += perf-tar-src-pkg
241. perf-tar-src-pkg: perf-$(KERNELVERSION).tar
242. 	@:
243. 
244. perf-tar%-src-pkg: perf-$(KERNELVERSION).tar.% FORCE
245. 	@:
246. 
247. # Help text displayed when executing 'make help'
248. # ---------------------------------------------------------------------------
249. PHONY += help
250. help:
251. 	@echo '  rpm-pkg             - Build both source and binary RPM kernel packages'
252. 	@echo '  srcrpm-pkg          - Build only the source kernel RPM package'
253. 	@echo '  binrpm-pkg          - Build only the binary kernel RPM package'
254. 	@echo '  deb-pkg             - Build both source and binary deb kernel packages'
255. 	@echo '  srcdeb-pkg          - Build only the source kernel deb package'
256. 	@echo '  bindeb-pkg          - Build only the binary kernel deb package'
257. 	@echo '  snap-pkg            - Build only the binary kernel snap package'
258. 	@echo '                        (will connect to external hosts)'
259. 	@echo '  pacman-pkg          - Build only the binary kernel pacman package'
260. 	@echo '  dir-pkg             - Build the kernel as a plain directory structure'
261. 	@echo '  tar-pkg             - Build the kernel as an uncompressed tarball'
262. 	@echo '  targz-pkg           - Build the kernel as a gzip compressed tarball'
263. 	@echo '  tarbz2-pkg          - Build the kernel as a bzip2 compressed tarball'
264. 	@echo '  tarxz-pkg           - Build the kernel as a xz compressed tarball'
265. 	@echo '  tarzst-pkg          - Build the kernel as a zstd compressed tarball'
266. 	@echo '  modules-cpio-pkg    - Build the kernel modules as cpio archive'
267. 	@echo '  perf-tar-src-pkg    - Build the perf source tarball with no compression'
268. 	@echo '  perf-targz-src-pkg  - Build the perf source tarball with gzip compression'
269. 	@echo '  perf-tarbz2-src-pkg - Build the perf source tarball with bz2 compression'
270. 	@echo '  perf-tarxz-src-pkg  - Build the perf source tarball with xz compression'
271. 	@echo '  perf-tarzst-src-pkg - Build the perf source tarball with zst compression'
272. 
273. PHONY += FORCE
274. FORCE:
275. 
276. # Read all saved command lines and dependencies for the $(targets) we
277. # may be building above, using $(if_changed{,_dep}). As an
278. # optimization, we don't need to read them if the target does not
279. # exist, we will rebuild anyway in that case.
280. 
281. existing-targets := $(wildcard $(sort $(targets)))
282. 
283. -include $(foreach f,$(existing-targets),$(dir $(f)).$(notdir $(f)).cmd)
284. 
285. .PHONY: $(PHONY)
286.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/package/builddeb.**

/wrk/avatar/src/linux/scripts/package/builddeb

<details>
<summary>171 lines</summary>

```
1. #!/bin/sh
2. #
3. # builddeb 1.3
4. # Copyright 2003 Wichert Akkerman <wichert@wiggy.net>
5. #
6. # Simple script to generate a deb package for a Linux kernel. All the
7. # complexity of what to do with a kernel after it is installed or removed
8. # is left to other scripts and packages. Scripts can be placed into the
9. # preinst, postinst, prerm and postrm directories in /etc/kernel or
10. # /usr/share/kernel. A different list of search directories can be given
11. # via KDEB_HOOKDIR. Scripts in directories earlier in the list will
12. # override scripts of the same name in later directories.  The script will
13. # be called on package installation and removal.
14. 
15. set -eu
16. 
17. is_enabled() {
18. 	grep -q "^$1=y" include/config/auto.conf
19. }
20. 
21. if_enabled_echo() {
22. 	if is_enabled "$1"; then
23. 		echo -n "$2"
24. 	elif [ $# -ge 3 ]; then
25. 		echo -n "$3"
26. 	fi
27. }
28. 
29. install_linux_image () {
30. 	pname=$1
31. 	pdir=debian/$1
32. 
33. 	# Only some architectures with OF support have this target
34. 	if is_enabled CONFIG_OF_EARLY_FLATTREE && [ -d "${srctree}/arch/${SRCARCH}/boot/dts" ]; then
35. 		${MAKE} -f ${srctree}/Makefile INSTALL_DTBS_PATH="${pdir}/usr/lib/linux-image-${KERNELRELEASE}" dtbs_install
36. 	fi
37. 
38. 	${MAKE} -f ${srctree}/Makefile INSTALL_MOD_PATH="${pdir}" INSTALL_MOD_STRIP=1 modules_install
39. 	rm -f "${pdir}/lib/modules/${KERNELRELEASE}/build"
40. 
41. 	# Install the kernel
42. 	if [ "${ARCH}" = um ] ; then
43. 		mkdir -p "${pdir}/usr/lib/uml/modules"
44. 		mv "${pdir}/lib/modules/${KERNELRELEASE}" "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}"
45. 		mkdir -p "${pdir}/usr/bin" "${pdir}/usr/share/doc/${pname}"
46. 		cp System.map "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}/System.map"
47. 		cp ${KCONFIG_CONFIG} "${pdir}/usr/share/doc/${pname}/config"
48. 		gzip "${pdir}/usr/share/doc/${pname}/config"
49. 	else
50. 		mkdir -p "${pdir}/boot"
51. 		cp System.map "${pdir}/boot/System.map-${KERNELRELEASE}"
52. 		cp ${KCONFIG_CONFIG} "${pdir}/boot/config-${KERNELRELEASE}"
53. 	fi
54. 
55. 	# Not all arches have the same installed path in debian
56. 	# XXX: have each arch Makefile export a variable of the canonical image install
57. 	# path instead
58. 	case "${SRCARCH}" in
59. 	um)
60. 		installed_image_path="usr/bin/linux-${KERNELRELEASE}";;
61. 	parisc|mips|powerpc)
62. 		installed_image_path="boot/vmlinux-${KERNELRELEASE}";;
63. 	*)
64. 		installed_image_path="boot/vmlinuz-${KERNELRELEASE}";;
65. 	esac
66. 	cp "$(${MAKE} -s -f ${srctree}/Makefile image_name)" "${pdir}/${installed_image_path}"
67. 
68. 	if [ "${ARCH}" != um ]; then
69. 		install_maint_scripts "${pdir}"
70. 	fi
71. }
72. 
73. install_maint_scripts () {
74. 	# Install the maintainer scripts
75. 	# Note: hook scripts under /etc/kernel are also executed by official Debian
76. 	# kernel packages, as well as kernel packages built using make-kpkg.
77. 	# make-kpkg sets $INITRD to indicate whether an initramfs is wanted, and
78. 	# so do we; recent versions of dracut and initramfs-tools will obey this.
79. 	debhookdir=${KDEB_HOOKDIR:-/etc/kernel /usr/share/kernel}
80. 	for script in postinst postrm preinst prerm; do
81. 		mkdir -p "${pdir}/DEBIAN"
82. 		cat <<-EOF > "${pdir}/DEBIAN/${script}"
83. 		#!/bin/sh
84. 
85. 		set -e
86. 
87. 		# Pass maintainer script parameters to hook scripts
88. 		export DEB_MAINT_PARAMS="\$*"
89. 
90. 		# Tell initramfs builder whether it's wanted
91. 		export INITRD=$(if_enabled_echo CONFIG_BLK_DEV_INITRD Yes No)
92. 
93. 		# run-parts will error out if one of its directory arguments does not
94. 		# exist, so filter the list of hook directories accordingly.
95. 		hookdirs=
96. 		for dir in ${debhookdir}; do
97. 			test -d "\$dir/${script}.d" || continue
98. 			hookdirs="\$hookdirs \$dir/${script}.d"
99. 		done
100. 		hookdirs="\${hookdirs# }"
101. 		test -n "\$hookdirs" && run-parts --arg="${KERNELRELEASE}" --arg="/${installed_image_path}" \$hookdirs
102. 		exit 0
103. 		EOF
104. 		chmod 755 "${pdir}/DEBIAN/${script}"
105. 	done
106. }
107. 
108. install_linux_image_dbg () {
109. 	pdir=debian/$1
110. 
111. 	# Parse modules.order directly because 'make modules_install' may sign,
112. 	# compress modules, and then run unneeded depmod.
113. 	if is_enabled CONFIG_MODULES; then
114. 		while read -r mod; do
115. 			mod="${mod%.o}.ko"
116. 			dbg="${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/kernel/${mod}"
117. 			buildid=$("${READELF}" -n "${mod}" | sed -n 's@^.*Build ID: \(..\)\(.*\)@\1/\2@p')
118. 			link="${pdir}/usr/lib/debug/.build-id/${buildid}.debug"
119. 
120. 			mkdir -p "${dbg%/*}" "${link%/*}"
121. 			"${OBJCOPY}" --only-keep-debug "${mod}" "${dbg}"
122. 			ln -sf --relative "${dbg}" "${link}"
123. 		done < modules.order
124. 	fi
125. 
126. 	# Build debug package
127. 	# Different tools want the image in different locations
128. 	# perf
129. 	mkdir -p ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
130. 	cp vmlinux ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
131. 	# systemtap
132. 	mkdir -p ${pdir}/usr/lib/debug/boot/
133. 	ln -s ../lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/boot/vmlinux-${KERNELRELEASE}
134. 	# kdump-tools
135. 	ln -s lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/vmlinux-${KERNELRELEASE}
136. }
137. 
138. install_kernel_headers () {
139. 	pdir=debian/$1
140. 	version=${1#linux-headers-}
141. 
142. 	CC="${DEB_HOST_GNU_TYPE}-gcc" "${srctree}/scripts/package/install-extmod-build" "${pdir}/usr/src/linux-headers-${version}"
143. 
144. 	mkdir -p $pdir/lib/modules/$version/
145. 	ln -s /usr/src/linux-headers-$version $pdir/lib/modules/$version/build
146. }
147. 
148. install_libc_headers () {
149. 	pdir=debian/$1
150. 
151. 	$MAKE -f $srctree/Makefile headers_install INSTALL_HDR_PATH=$pdir/usr
152. 
153. 	# move asm headers to /usr/include/<libc-machine>/asm to match the structure
154. 	# used by Debian-based distros (to support multi-arch)
155. 	mkdir "$pdir/usr/include/${DEB_HOST_MULTIARCH}"
156. 	mv "$pdir/usr/include/asm" "$pdir/usr/include/${DEB_HOST_MULTIARCH}"
157. }
158. 
159. package=$1
160. 
161. case "${package}" in
162. *-dbg)
163. 	install_linux_image_dbg "${package}";;
164. linux-image-*|user-mode-linux-*)
165. 	install_linux_image "${package}";;
166. linux-libc-dev)
167. 	install_libc_headers "${package}";;
168. linux-headers-*)
169. 	install_kernel_headers "${package}";;
170. esac
171.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/package/mkdebian.**

/wrk/avatar/src/linux/scripts/package/mkdebian

<details>
<summary>274 lines</summary>

```
1. #!/bin/sh
2. #
3. # Copyright 2003 Wichert Akkerman <wichert@wiggy.net>
4. #
5. # Simple script to generate a debian/ directory for a Linux kernel.
6. 
7. set -eu
8. 
9. is_enabled() {
10. 	grep -q "^$1=y" include/config/auto.conf
11. }
12. 
13. if_enabled_echo() {
14. 	if is_enabled "$1"; then
15. 		echo -n "$2"
16. 	elif [ $# -ge 3 ]; then
17. 		echo -n "$3"
18. 	fi
19. }
20. 
21. set_debarch() {
22. 	if [ "${KBUILD_DEBARCH:+set}" ]; then
23. 		debarch="$KBUILD_DEBARCH"
24. 		return
25. 	fi
26. 
27. 	# Attempt to find the correct Debian architecture
28. 	case "$UTS_MACHINE" in
29. 	i386|alpha|m68k|riscv*)
30. 		debarch="$UTS_MACHINE" ;;
31. 	x86_64)
32. 		debarch=amd64 ;;
33. 	sparc*)
34. 		debarch=sparc$(if_enabled_echo CONFIG_64BIT 64) ;;
35. 	s390*)
36. 		debarch=s390x ;;
37. 	ppc*)
38. 		if is_enabled CONFIG_64BIT; then
39. 			debarch=ppc64$(if_enabled_echo CONFIG_CPU_LITTLE_ENDIAN el)
40. 		else
41. 			debarch=powerpc$(if_enabled_echo CONFIG_SPE spe)
42. 		fi
43. 		;;
44. 	parisc*)
45. 		debarch=hppa ;;
46. 	mips*)
47. 		if is_enabled CONFIG_CPU_LITTLE_ENDIAN; then
48. 			debarch=mips$(if_enabled_echo CONFIG_64BIT 64)$(if_enabled_echo CONFIG_CPU_MIPSR6 r6)el
49. 		elif is_enabled CONFIG_CPU_MIPSR6; then
50. 			debarch=mips$(if_enabled_echo CONFIG_64BIT 64)r6
51. 		else
52. 			debarch=mips
53. 		fi
54. 		;;
55. 	aarch64|arm64)
56. 		debarch=arm64 ;;
57. 	arm*)
58. 		if is_enabled CONFIG_AEABI; then
59. 			debarch=arm$(if_enabled_echo CONFIG_VFP hf el)
60. 		else
61. 			debarch=arm
62. 		fi
63. 		;;
64. 	openrisc)
65. 		debarch=or1k ;;
66. 	sh)
67. 		if is_enabled CONFIG_CPU_SH3; then
68. 			debarch=sh3$(if_enabled_echo CONFIG_CPU_BIG_ENDIAN eb)
69. 		elif is_enabled CONFIG_CPU_SH4; then
70. 			debarch=sh4$(if_enabled_echo CONFIG_CPU_BIG_ENDIAN eb)
71. 		fi
72. 		;;
73. 	um)
74. 		if is_enabled CONFIG_64BIT; then
75. 			debarch=amd64
76. 		else
77. 			debarch=i386
78. 		fi
79. 		;;
80. 	loongarch64)
81. 		debarch=loong64 ;;
82. 	esac
83. 	if [ -z "$debarch" ]; then
84. 		debarch=$(dpkg-architecture -qDEB_HOST_ARCH)
85. 		echo "" >&2
86. 		echo "** ** **  WARNING  ** ** **" >&2
87. 		echo "" >&2
88. 		echo "Your architecture doesn't have its equivalent" >&2
89. 		echo "Debian userspace architecture defined!" >&2
90. 		echo "Falling back to the current host architecture ($debarch)." >&2
91. 		echo "Please add support for $UTS_MACHINE to ${0} ..." >&2
92. 		echo "" >&2
93. 	fi
94. }
95. 
96. # Create debian/source/ if it is a source package build
97. gen_source ()
98. {
99. 	mkdir -p debian/source
100. 
101. 	echo "3.0 (quilt)" > debian/source/format
102. 
103. 	{
104. 		echo "diff-ignore"
105. 		echo "extend-diff-ignore = .*"
106. 	} > debian/source/local-options
107. 
108. 	# Add .config as a patch
109. 	mkdir -p debian/patches
110. 	{
111. 		echo "Subject: Add .config"
112. 		echo "Author: ${maintainer}"
113. 		echo
114. 		echo "--- /dev/null"
115. 		echo "+++ linux/.config"
116. 		diff -u /dev/null "${KCONFIG_CONFIG}" | tail -n +3
117. 	} > debian/patches/config.patch
118. 	echo config.patch > debian/patches/series
119. 
120. 	"${srctree}/scripts/package/gen-diff-patch" debian/patches/diff.patch
121. 	if [ -s debian/patches/diff.patch ]; then
122. 		sed -i "
123. 			1iSubject: Add local diff
124. 			1iAuthor: ${maintainer}
125. 			1i
126. 		" debian/patches/diff.patch
127. 
128. 		echo diff.patch >> debian/patches/series
129. 	else
130. 		rm -f debian/patches/diff.patch
131. 	fi
132. }
133. 
134. rm -rf debian
135. mkdir debian
136. 
137. user=${KBUILD_BUILD_USER:-$(id -nu)}
138. name=${DEBFULLNAME:-${user}}
139. if [ "${DEBEMAIL:+set}" ]; then
140. 	email=${DEBEMAIL}
141. else
142. 	buildhost=${KBUILD_BUILD_HOST:-$(hostname -f 2>/dev/null || hostname)}
143. 	email="${user}@${buildhost}"
144. fi
145. maintainer="${name} <${email}>"
146. 
147. while [ $# -gt 0 ]; do
148. 	case "$1" in
149. 	--need-source)
150. 		gen_source
151. 		shift
152. 		;;
153. 	*)
154. 		break
155. 		;;
156. 	esac
157. done
158. 
159. # Some variables and settings used throughout the script
160. if [ "${KDEB_PKGVERSION:+set}" ]; then
161. 	packageversion=$KDEB_PKGVERSION
162. else
163. 	upstream_version=$("${srctree}/scripts/setlocalversion" --no-local "${srctree}" | sed 's/-\(rc[1-9]\)/~\1/')
164. 	debian_revision=$("${srctree}/scripts/build-version")
165. 	packageversion=${upstream_version}-${debian_revision}
166. fi
167. sourcename=${KDEB_SOURCENAME:-linux-upstream}
168. 
169. if [ "$ARCH" = "um" ] ; then
170. 	packagename=user-mode-linux
171. else
172. 	packagename=linux-image
173. fi
174. 
175. debarch=
176. set_debarch
177. 
178. # Try to determine distribution
179. if [ "${KDEB_CHANGELOG_DIST:+set}" ]; then
180.         distribution=$KDEB_CHANGELOG_DIST
181. # In some cases lsb_release returns the codename as n/a, which breaks dpkg-parsechangelog
182. elif distribution=$(lsb_release -cs 2>/dev/null) && [ -n "$distribution" ] && [ "$distribution" != "n/a" ]; then
183.         : # nothing to do in this case
184. else
185.         distribution="unstable"
186.         echo >&2 "Using default distribution of 'unstable' in the changelog"
187.         echo >&2 "Install lsb-release or set \$KDEB_CHANGELOG_DIST explicitly"
188. fi
189. 
190. echo $debarch > debian/arch
191. 
192. host_gnu=$(dpkg-architecture -a "${debarch}" -q DEB_HOST_GNU_TYPE | sed 's/_/-/g')
193. 
194. # Generate a simple changelog template
195. cat <<EOF > debian/changelog
196. $sourcename ($packageversion) $distribution; urgency=low
197. 
198.   * Custom built Linux kernel.
199. 
200.  -- $maintainer  $(date -R)
201. EOF
202. 
203. # Generate a control file
204. cat <<EOF > debian/control
205. Source: $sourcename
206. Section: kernel
207. Priority: optional
208. Maintainer: $maintainer
209. Rules-Requires-Root: no
210. Build-Depends: debhelper-compat (= 12)
211. Build-Depends-Arch: bc, bison, flex,
212.  gcc-${host_gnu} <!pkg.${sourcename}.nokernelheaders>,
213.  kmod, libdw-dev:native, libelf-dev:native,
214.  libssl-dev:native, libssl-dev <!pkg.${sourcename}.nokernelheaders>,
215.  python3:native, rsync
216. Homepage: https://www.kernel.org/
217. 
218. Package: $packagename-${KERNELRELEASE}
219. Architecture: $debarch
220. Description: Linux kernel, version ${KERNELRELEASE}
221.  This package contains the Linux kernel, modules and corresponding other
222.  files, version: ${KERNELRELEASE}.
223. EOF
224. 
225. if [ "${SRCARCH}" != um ]; then
226. cat <<EOF >> debian/control
227. 
228. Package: linux-libc-dev
229. Section: devel
230. Provides: linux-kernel-headers
231. Architecture: $debarch
232. Description: Linux support headers for userspace development
233.  This package provides userspaces headers from the Linux kernel.  These headers
234.  are used by the installed headers for GNU glibc and other system libraries.
235. Multi-Arch: same
236. EOF
237. 
238. if is_enabled CONFIG_MODULES; then
239. cat <<EOF >> debian/control
240. 
241. Package: linux-headers-${KERNELRELEASE}
242. Architecture: $debarch
243. Build-Profiles: <!pkg.${sourcename}.nokernelheaders>
244. Description: Linux kernel headers for ${KERNELRELEASE} on $debarch
245.  This package provides kernel header files for ${KERNELRELEASE} on $debarch
246.  .
247.  This is useful for people who need to build external modules
248. EOF
249. fi
250. fi
251. 
252. if is_enabled CONFIG_DEBUG_INFO; then
253. cat <<EOF >> debian/control
254. 
255. Package: linux-image-${KERNELRELEASE}-dbg
256. Section: debug
257. Architecture: $debarch
258. Build-Profiles: <!pkg.${sourcename}.nokerneldbg>
259. Description: Linux kernel debugging symbols for ${KERNELRELEASE}
260.  This package will come in handy if you need to debug the kernel. It provides
261.  all the necessary debug symbols for the kernel and its modules.
262. EOF
263. fi
264. 
265. cat <<EOF > debian/rules.vars
266. ARCH := ${ARCH}
267. KERNELRELEASE := ${KERNELRELEASE}
268. EOF
269. 
270. cp "${srctree}/scripts/package/debian/copyright" debian/
271. cp "${srctree}/scripts/package/debian/rules" debian/
272. 
273. exit 0
274.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/rules.**

/wrk/avatar/src/linux/debian/rules

<details>
<summary>98 lines</summary>

```
1. #!/usr/bin/make -f
2. # SPDX-License-Identifier: GPL-2.0-only
3. 
4. # in case debian/rules is executed directly
5. export DEB_RULES_REQUIRES_ROOT := no
6. 
7. include debian/rules.vars
8. 
9. ifneq (,$(filter-out parallel=1,$(filter parallel=%,$(DEB_BUILD_OPTIONS))))
10.     NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
11.     MAKEFLAGS += -j$(NUMJOBS)
12. endif
13. 
14. # When KBUILD_VERBOSE is undefined (presumably you are directly working with
15. # the debianized tree), show verbose logs unless DEB_BUILD_OPTION=terse is set.
16. ifeq ($(origin KBUILD_VERBOSE),undefined)
17.     ifeq (,$(filter terse,$(DEB_BUILD_OPTIONS)))
18.         export KBUILD_VERBOSE := 1
19.     else
20.         Q := @
21.     endif
22. endif
23. 
24. revision = $(shell dpkg-parsechangelog -S Version | sed -n 's/.*-//p')
25. CROSS_COMPILE ?= $(filter-out $(DEB_BUILD_GNU_TYPE)-, $(DEB_HOST_GNU_TYPE)-)
26. make-opts = ARCH=$(ARCH) KERNELRELEASE=$(KERNELRELEASE) \
27.     $(addprefix KBUILD_BUILD_VERSION=,$(revision)) \
28.     $(addprefix CROSS_COMPILE=,$(CROSS_COMPILE))
29. 
30. binary-targets := $(addprefix binary-, image image-dbg headers libc-dev)
31. 
32. all-packages = $(shell dh_listpackages)
33. image-package = $(filter linux-image-% user-%, $(filter-out %-dbg, $(all-packages)))
34. image-dbg-package = $(filter %-dbg, $(all-packages))
35. libc-dev-package = $(filter linux-libc-dev, $(all-packages))
36. headers-package = $(filter linux-headers-%, $(all-packages))
37. 
38. mk-files = $(patsubst binary-%,debian/%.files,$1)
39. package = $($(@:binary-%=%-package))
40. 
41. # DH_OPTION is an environment variable common for all debhelper commands.
42. # We could 'export' it, but here it is passed from the command line to clarify
43. # which package is being processed in the build log.
44. DH_OPTIONS = -p$(package)
45. 
46. # Note: future removal of KDEB_COMPRESS
47. # dpkg-deb >= 1.21.10 supports the DPKG_DEB_COMPRESSOR_TYPE environment
48. # variable, which provides the same functionality as KDEB_COMPRESS. The
49. # KDEB_COMPRESS variable will be removed in the future.
50. define binary
51. 	$(Q)dh_testdir $(DH_OPTIONS)
52. 	$(Q)dh_testroot $(DH_OPTIONS)
53. 	$(Q)dh_prep $(DH_OPTIONS)
54. 	$(Q)+$(MAKE) $(make-opts) run-command KBUILD_RUN_COMMAND='+$$(srctree)/scripts/package/builddeb $(package)'
55. 	$(Q)dh_installdocs $(DH_OPTIONS)
56. 	$(Q)dh_installchangelogs $(DH_OPTIONS)
57. 	$(Q)dh_compress $(DH_OPTIONS)
58. 	$(Q)dh_fixperms $(DH_OPTIONS)
59. 	$(Q)dh_gencontrol $(DH_OPTIONS) -- -f$(call mk-files,$@)
60. 	$(Q)dh_md5sums $(DH_OPTIONS)
61. 	$(Q)dh_builddeb $(DH_OPTIONS) -- $(addprefix -Z,$(KDEB_COMPRESS))
62. endef
63. 
64. .PHONY: $(binary-targets)
65. $(binary-targets): build-arch
66. 	$(Q)truncate -s0 $(call mk-files,$@)
67. 	$(if $(package),$(binary))
68. 
69. .PHONY: binary binary-indep binary-arch
70. binary: binary-arch binary-indep
71. binary-indep: build-indep
72. binary-arch: $(binary-targets)
73. 	$(Q)cat $(call mk-files,$^) > debian/files
74. 
75. .PHONY: build build-indep build-arch
76. build: build-arch build-indep
77. build-indep:
78. build-arch:
79. 	$(Q)$(MAKE) $(make-opts) olddefconfig
80. 	$(Q)$(MAKE) $(make-opts) $(if $(filter um,$(ARCH)),,headers) all
81. 
82. .PHONY: clean
83. clean:
84. 	$(Q)dh_clean
85. 	$(Q)rm -rf debian/deb-env.vars* debian/*.files
86. 	$(Q)$(MAKE) ARCH=$(ARCH) clean
87. 
88. # If DEB_HOST_ARCH is empty, it is likely that debian/rules was executed
89. # directly. Run 'dpkg-architecture --print-set --print-format=make' to
90. # generate a makefile construct that exports all DEB_* variables.
91. ifndef DEB_HOST_ARCH
92. include debian/deb-env.vars
93. 
94. debian/deb-env.vars:
95. 	$(Q)dpkg-architecture -a$$(cat debian/arch) --print-set --print-format=make > $@.tmp
96. 	$(Q)mv $@.tmp $@
97. endif
98.
```

</details>


### 💬 Copilot

Now let me check the debian/ directory files at the repo root:

### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/rules.**

/wrk/avatar/src/linux/debian/rules

<details>
<summary>98 lines</summary>

```
1. #!/usr/bin/make -f
2. # SPDX-License-Identifier: GPL-2.0-only
3. 
4. # in case debian/rules is executed directly
5. export DEB_RULES_REQUIRES_ROOT := no
6. 
7. include debian/rules.vars
8. 
9. ifneq (,$(filter-out parallel=1,$(filter parallel=%,$(DEB_BUILD_OPTIONS))))
10.     NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
11.     MAKEFLAGS += -j$(NUMJOBS)
12. endif
13. 
14. # When KBUILD_VERBOSE is undefined (presumably you are directly working with
15. # the debianized tree), show verbose logs unless DEB_BUILD_OPTION=terse is set.
16. ifeq ($(origin KBUILD_VERBOSE),undefined)
17.     ifeq (,$(filter terse,$(DEB_BUILD_OPTIONS)))
18.         export KBUILD_VERBOSE := 1
19.     else
20.         Q := @
21.     endif
22. endif
23. 
24. revision = $(shell dpkg-parsechangelog -S Version | sed -n 's/.*-//p')
25. CROSS_COMPILE ?= $(filter-out $(DEB_BUILD_GNU_TYPE)-, $(DEB_HOST_GNU_TYPE)-)
26. make-opts = ARCH=$(ARCH) KERNELRELEASE=$(KERNELRELEASE) \
27.     $(addprefix KBUILD_BUILD_VERSION=,$(revision)) \
28.     $(addprefix CROSS_COMPILE=,$(CROSS_COMPILE))
29. 
30. binary-targets := $(addprefix binary-, image image-dbg headers libc-dev)
31. 
32. all-packages = $(shell dh_listpackages)
33. image-package = $(filter linux-image-% user-%, $(filter-out %-dbg, $(all-packages)))
34. image-dbg-package = $(filter %-dbg, $(all-packages))
35. libc-dev-package = $(filter linux-libc-dev, $(all-packages))
36. headers-package = $(filter linux-headers-%, $(all-packages))
37. 
38. mk-files = $(patsubst binary-%,debian/%.files,$1)
39. package = $($(@:binary-%=%-package))
40. 
41. # DH_OPTION is an environment variable common for all debhelper commands.
42. # We could 'export' it, but here it is passed from the command line to clarify
43. # which package is being processed in the build log.
44. DH_OPTIONS = -p$(package)
45. 
46. # Note: future removal of KDEB_COMPRESS
47. # dpkg-deb >= 1.21.10 supports the DPKG_DEB_COMPRESSOR_TYPE environment
48. # variable, which provides the same functionality as KDEB_COMPRESS. The
49. # KDEB_COMPRESS variable will be removed in the future.
50. define binary
51. 	$(Q)dh_testdir $(DH_OPTIONS)
52. 	$(Q)dh_testroot $(DH_OPTIONS)
53. 	$(Q)dh_prep $(DH_OPTIONS)
54. 	$(Q)+$(MAKE) $(make-opts) run-command KBUILD_RUN_COMMAND='+$$(srctree)/scripts/package/builddeb $(package)'
55. 	$(Q)dh_installdocs $(DH_OPTIONS)
56. 	$(Q)dh_installchangelogs $(DH_OPTIONS)
57. 	$(Q)dh_compress $(DH_OPTIONS)
58. 	$(Q)dh_fixperms $(DH_OPTIONS)
59. 	$(Q)dh_gencontrol $(DH_OPTIONS) -- -f$(call mk-files,$@)
60. 	$(Q)dh_md5sums $(DH_OPTIONS)
61. 	$(Q)dh_builddeb $(DH_OPTIONS) -- $(addprefix -Z,$(KDEB_COMPRESS))
62. endef
63. 
64. .PHONY: $(binary-targets)
65. $(binary-targets): build-arch
66. 	$(Q)truncate -s0 $(call mk-files,$@)
67. 	$(if $(package),$(binary))
68. 
69. .PHONY: binary binary-indep binary-arch
70. binary: binary-arch binary-indep
71. binary-indep: build-indep
72. binary-arch: $(binary-targets)
73. 	$(Q)cat $(call mk-files,$^) > debian/files
74. 
75. .PHONY: build build-indep build-arch
76. build: build-arch build-indep
77. build-indep:
78. build-arch:
79. 	$(Q)$(MAKE) $(make-opts) olddefconfig
80. 	$(Q)$(MAKE) $(make-opts) $(if $(filter um,$(ARCH)),,headers) all
81. 
82. .PHONY: clean
83. clean:
84. 	$(Q)dh_clean
85. 	$(Q)rm -rf debian/deb-env.vars* debian/*.files
86. 	$(Q)$(MAKE) ARCH=$(ARCH) clean
87. 
88. # If DEB_HOST_ARCH is empty, it is likely that debian/rules was executed
89. # directly. Run 'dpkg-architecture --print-set --print-format=make' to
90. # generate a makefile construct that exports all DEB_* variables.
91. ifndef DEB_HOST_ARCH
92. include debian/deb-env.vars
93. 
94. debian/deb-env.vars:
95. 	$(Q)dpkg-architecture -a$$(cat debian/arch) --print-set --print-format=make > $@.tmp
96. 	$(Q)mv $@.tmp $@
97. endif
98.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/control.**

/wrk/avatar/src/linux/debian/control

<details>
<summary>44 lines</summary>

```
1. Source: linux-upstream
2. Section: kernel
3. Priority: optional
4. Maintainer: Alistair Young <avatar@arkane-systems.net>
5. Rules-Requires-Root: no
6. Build-Depends: debhelper-compat (= 12)
7. Build-Depends-Arch: bc, bison, flex,
8.  gcc-x86-64-linux-gnu <!pkg.linux-upstream.nokernelheaders>,
9.  kmod, libdw-dev:native, libelf-dev:native,
10.  libssl-dev:native, libssl-dev <!pkg.linux-upstream.nokernelheaders>,
11.  python3:native, rsync
12. Homepage: https://www.kernel.org/
13. 
14. Package: linux-image-7.0.0-rc22026030501-microsoft-custom-WSL2+
15. Architecture: amd64
16. Description: Linux kernel, version 7.0.0-rc22026030501-microsoft-custom-WSL2+
17.  This package contains the Linux kernel, modules and corresponding other
18.  files, version: 7.0.0-rc22026030501-microsoft-custom-WSL2+.
19. 
20. Package: linux-libc-dev
21. Section: devel
22. Provides: linux-kernel-headers
23. Architecture: amd64
24. Description: Linux support headers for userspace development
25.  This package provides userspaces headers from the Linux kernel.  These headers
26.  are used by the installed headers for GNU glibc and other system libraries.
27. Multi-Arch: same
28. 
29. Package: linux-headers-7.0.0-rc22026030501-microsoft-custom-WSL2+
30. Architecture: amd64
31. Build-Profiles: <!pkg.linux-upstream.nokernelheaders>
32. Description: Linux kernel headers for 7.0.0-rc22026030501-microsoft-custom-WSL2+ on amd64
33.  This package provides kernel header files for 7.0.0-rc22026030501-microsoft-custom-WSL2+ on amd64
34.  .
35.  This is useful for people who need to build external modules
36. 
37. Package: linux-image-7.0.0-rc22026030501-microsoft-custom-WSL2+-dbg
38. Section: debug
39. Architecture: amd64
40. Build-Profiles: <!pkg.linux-upstream.nokerneldbg>
41. Description: Linux kernel debugging symbols for 7.0.0-rc22026030501-microsoft-custom-WSL2+
42.  This package will come in handy if you need to debug the kernel. It provides
43.  all the necessary debug symbols for the kernel and its modules.
44.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/changelog.**

/wrk/avatar/src/linux/debian/changelog

<details>
<summary>6 lines</summary>

```
1. linux-upstream (7.0.0~rc2-00090-gc107785c7e8d-2) forky; urgency=low
2. 
3.   * Custom built Linux kernel.
4. 
5.  -- Alistair Young <avatar@arkane-systems.net>  Thu, 05 Mar 2026 13:57:44 -0600
6.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/copyright.**

/wrk/avatar/src/linux/debian/copyright (lines 1-30)

<details>
<summary>16 lines</summary>

```
1. This is a packaged upstream version of the Linux kernel.
2. 
3. The sources may be found at most Linux archive sites, including:
4. https://www.kernel.org/pub/linux/kernel
5. 
6. Copyright: 1991 - 2023 Linus Torvalds and others.
7. 
8. The git repository for mainline kernel development is at:
9. git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
10. 
11.     This program is free software; you can redistribute it and/or modify
12.     it under the terms of the GNU General Public License as published by
13.     the Free Software Foundation; version 2 dated June, 1991.
14. 
15. On Debian GNU/Linux systems, the complete text of the GNU General Public
16. License version 2 can be found in `/usr/share/common-licenses/GPL-2'.
```

</details>


### 💬 Copilot

Let me check the helper scripts and .files templates:

### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/package/install-extmod-build.**

/wrk/avatar/src/linux/scripts/package/install-extmod-build (lines 1-50)

<details>
<summary>50 lines</summary>

```
1. #!/bin/sh
2. # SPDX-License-Identifier: GPL-2.0-only
3. 
4. set -eu
5. 
6. destdir=${1}
7. 
8. is_enabled() {
9. 	grep -q "^$1=y" include/config/auto.conf
10. }
11. 
12. find_in_scripts() {
13. 	find scripts \
14. 		\( -name atomic -o -name dtc -o -name kconfig -o -name package \) -prune -o \
15. 		! -name unifdef -a ! -name mk_elfconfig -a \( -type f -o -type l \) -print
16. }
17. 
18. mkdir -p "${destdir}"
19. 
20. (
21. 	cd "${srctree}"
22. 	echo Makefile
23. 	find "arch/${SRCARCH}" -maxdepth 1 -name 'Makefile*'
24. 	find "arch/${SRCARCH}" -name generated -prune -o -name include -type d -print
25. 	find "arch/${SRCARCH}" -name Kbuild.platforms -o -name Platform
26. 	find include \( -name config -o -name generated \) -prune -o \( -type f -o -type l \) -print
27. 	find_in_scripts
28. ) | tar -c -f - -C "${srctree}" -T - | tar -xf - -C "${destdir}"
29. 
30. {
31. 	if is_enabled CONFIG_OBJTOOL; then
32. 		echo tools/objtool/objtool
33. 	fi
34. 
35. 	echo Module.symvers
36. 	echo "arch/${SRCARCH}/include/generated"
37. 	echo include/config/auto.conf
38. 	echo include/config/kernel.release
39. 	echo include/generated
40. 	find_in_scripts
41. 
42. 	if is_enabled CONFIG_GCC_PLUGINS; then
43. 		find scripts/gcc-plugins -name '*.so'
44. 	fi
45. } | tar -c -f - -T - | tar -xf - -C "${destdir}"
46. 
47. # When ${CC} and ${HOSTCC} differ, rebuild host programs using ${CC}.
48. #
49. # This caters to host programs that participate in Kbuild. objtool and
50. # resolve_btfids are out of scope.
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/image.files.**

/wrk/avatar/src/linux/debian/image.files

```
1. 
```


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/headers.files.**

/wrk/avatar/src/linux/debian/headers.files

```
1. 
```


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/libc-dev.files.**

/wrk/avatar/src/linux/debian/libc-dev.files

```
1. 
```


### 💬 Copilot

Let me check scripts/package/debian/rules and look for more files information:

### ✅ `view`

**view the file at /wrk/avatar/src/linux/scripts/package/debian/rules.**

/wrk/avatar/src/linux/scripts/package/debian/rules

<details>
<summary>98 lines</summary>

```
1. #!/usr/bin/make -f
2. # SPDX-License-Identifier: GPL-2.0-only
3. 
4. # in case debian/rules is executed directly
5. export DEB_RULES_REQUIRES_ROOT := no
6. 
7. include debian/rules.vars
8. 
9. ifneq (,$(filter-out parallel=1,$(filter parallel=%,$(DEB_BUILD_OPTIONS))))
10.     NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
11.     MAKEFLAGS += -j$(NUMJOBS)
12. endif
13. 
14. # When KBUILD_VERBOSE is undefined (presumably you are directly working with
15. # the debianized tree), show verbose logs unless DEB_BUILD_OPTION=terse is set.
16. ifeq ($(origin KBUILD_VERBOSE),undefined)
17.     ifeq (,$(filter terse,$(DEB_BUILD_OPTIONS)))
18.         export KBUILD_VERBOSE := 1
19.     else
20.         Q := @
21.     endif
22. endif
23. 
24. revision = $(shell dpkg-parsechangelog -S Version | sed -n 's/.*-//p')
25. CROSS_COMPILE ?= $(filter-out $(DEB_BUILD_GNU_TYPE)-, $(DEB_HOST_GNU_TYPE)-)
26. make-opts = ARCH=$(ARCH) KERNELRELEASE=$(KERNELRELEASE) \
27.     $(addprefix KBUILD_BUILD_VERSION=,$(revision)) \
28.     $(addprefix CROSS_COMPILE=,$(CROSS_COMPILE))
29. 
30. binary-targets := $(addprefix binary-, image image-dbg headers libc-dev)
31. 
32. all-packages = $(shell dh_listpackages)
33. image-package = $(filter linux-image-% user-%, $(filter-out %-dbg, $(all-packages)))
34. image-dbg-package = $(filter %-dbg, $(all-packages))
35. libc-dev-package = $(filter linux-libc-dev, $(all-packages))
36. headers-package = $(filter linux-headers-%, $(all-packages))
37. 
38. mk-files = $(patsubst binary-%,debian/%.files,$1)
39. package = $($(@:binary-%=%-package))
40. 
41. # DH_OPTION is an environment variable common for all debhelper commands.
42. # We could 'export' it, but here it is passed from the command line to clarify
43. # which package is being processed in the build log.
44. DH_OPTIONS = -p$(package)
45. 
46. # Note: future removal of KDEB_COMPRESS
47. # dpkg-deb >= 1.21.10 supports the DPKG_DEB_COMPRESSOR_TYPE environment
48. # variable, which provides the same functionality as KDEB_COMPRESS. The
49. # KDEB_COMPRESS variable will be removed in the future.
50. define binary
51. 	$(Q)dh_testdir $(DH_OPTIONS)
52. 	$(Q)dh_testroot $(DH_OPTIONS)
53. 	$(Q)dh_prep $(DH_OPTIONS)
54. 	$(Q)+$(MAKE) $(make-opts) run-command KBUILD_RUN_COMMAND='+$$(srctree)/scripts/package/builddeb $(package)'
55. 	$(Q)dh_installdocs $(DH_OPTIONS)
56. 	$(Q)dh_installchangelogs $(DH_OPTIONS)
57. 	$(Q)dh_compress $(DH_OPTIONS)
58. 	$(Q)dh_fixperms $(DH_OPTIONS)
59. 	$(Q)dh_gencontrol $(DH_OPTIONS) -- -f$(call mk-files,$@)
60. 	$(Q)dh_md5sums $(DH_OPTIONS)
61. 	$(Q)dh_builddeb $(DH_OPTIONS) -- $(addprefix -Z,$(KDEB_COMPRESS))
62. endef
63. 
64. .PHONY: $(binary-targets)
65. $(binary-targets): build-arch
66. 	$(Q)truncate -s0 $(call mk-files,$@)
67. 	$(if $(package),$(binary))
68. 
69. .PHONY: binary binary-indep binary-arch
70. binary: binary-arch binary-indep
71. binary-indep: build-indep
72. binary-arch: $(binary-targets)
73. 	$(Q)cat $(call mk-files,$^) > debian/files
74. 
75. .PHONY: build build-indep build-arch
76. build: build-arch build-indep
77. build-indep:
78. build-arch:
79. 	$(Q)$(MAKE) $(make-opts) olddefconfig
80. 	$(Q)$(MAKE) $(make-opts) $(if $(filter um,$(ARCH)),,headers) all
81. 
82. .PHONY: clean
83. clean:
84. 	$(Q)dh_clean
85. 	$(Q)rm -rf debian/deb-env.vars* debian/*.files
86. 	$(Q)$(MAKE) ARCH=$(ARCH) clean
87. 
88. # If DEB_HOST_ARCH is empty, it is likely that debian/rules was executed
89. # directly. Run 'dpkg-architecture --print-set --print-format=make' to
90. # generate a makefile construct that exports all DEB_* variables.
91. ifndef DEB_HOST_ARCH
92. include debian/deb-env.vars
93. 
94. debian/deb-env.vars:
95. 	$(Q)dpkg-architecture -a$$(cat debian/arch) --print-set --print-format=make > $@.tmp
96. 	$(Q)mv $@.tmp $@
97. endif
98.
```

</details>


### ✅ `grep`

**/wrk/avatar/src/linux/debian**

"." (/wrk/avatar/src/linux/debian)

<details>
<summary>8 matches</summary>

```
/wrk/avatar/src/linux/debian/changelog
/wrk/avatar/src/linux/debian/copyright
/wrk/avatar/src/linux/debian/rules
/wrk/avatar/src/linux/debian/control
/wrk/avatar/src/linux/debian/rules.vars
/wrk/avatar/src/linux/debian/arch
/wrk/avatar/src/linux/debian/source/format
/wrk/avatar/src/linux/debian/source/local-options
```

</details>


### ✅ `view`

**view the file at /wrk/avatar/src/linux/debian/image-dbg.files.**

/wrk/avatar/src/linux/debian/image-dbg.files

```
1. 
```


### 💬 Copilot

Perfect! Now let me create a comprehensive summary with a visual flow diagram based on what I've found:

### ✅ `grep`

**/wrk/avatar/src/linux/scripts/Makefile.package**

"deb-pkg|srcdeb-pkg|bindeb-pkg" (/wrk/avatar/src/linux/scripts/Makefile.package)

<details>
<summary>11 matches</summary>

```
/wrk/avatar/src/linux/scripts/Makefile.package:# deb-pkg srcdeb-pkg bindeb-pkg
/wrk/avatar/src/linux/scripts/Makefile.package:PHONY += deb-pkg srcdeb-pkg bindeb-pkg
/wrk/avatar/src/linux/scripts/Makefile.package:deb-pkg:    private build-type := source,binary
/wrk/avatar/src/linux/scripts/Makefile.package:srcdeb-pkg: private build-type := source
/wrk/avatar/src/linux/scripts/Makefile.package:bindeb-pkg: private build-type := binary
/wrk/avatar/src/linux/scripts/Makefile.package:deb-pkg srcdeb-pkg: debian-orig
/wrk/avatar/src/linux/scripts/Makefile.package:bindeb-pkg: debian
/wrk/avatar/src/linux/scripts/Makefile.package:deb-pkg srcdeb-pkg bindeb-pkg:
/wrk/avatar/src/linux/scripts/Makefile.package:	@echo '  deb-pkg             - Build both source and binary deb kernel packages'
/wrk/avatar/src/linux/scripts/Makefile.package:	@echo '  srcdeb-pkg          - Build only the source kernel deb package'
/wrk/avatar/src/linux/scripts/Makefile.package:	@echo '  bindeb-pkg          - Build only the binary kernel deb package'
```

</details>


### 💬 Copilot

## Comprehensive Debian Packaging Analysis

### 1. **deb-pkg Definition in Makefile** 
Located in `/wrk/avatar/src/linux/scripts/Makefile.package` (lines 83-133):

- **deb-pkg**: Builds both source AND binary packages (`build-type := source,binary`)
- **srcdeb-pkg**: Source only (`build-type := source`)
- **bindeb-pkg**: Binary only (`build-type := binary`)

All three ultimately call `dpkg-buildpackage` with different flags.

---

### 2. **scripts/package/ Directory Structure**

| File | Role |
|------|------|
| **builddeb** | Main installation script (~171 lines) - packages kernel image, modules, headers, libc-dev, debug symbols |
| **mkdebian** | Generates debian/ directory and control files - creates changelog, control file, rules, patches |
| **install-extmod-build** | Installs kernel headers for external module builds to `/usr/src/linux-headers-*` |
| gen-diff-patch | Generates diff patches for source packages |
| scripts/package/debian/rules | Template debian/rules file (copied to debian/) |
| scripts/package/debian/copyright | License information template |
| PKGBUILD, kernel.spec, buildtar, snapcraft.template | Support for other package formats (RPM, snap, etc.) |

---

### 3. **debian/ Directory at Repo Root**

Generated dynamically by `mkdebian` script. Contains:

| File | Purpose |
|------|---------|
| **rules** | Makefile controlling binary package build (dh_* commands, debhelper integration) |
| **rules.vars** | Architecture and kernel release variables |
| **control** | Package metadata (Source, Build-Depends, Architecture, Package descriptions) |
| **changelog** | Version and distribution info |
| **copyright** | License/copyright declaration |
| **arch** | Target Debian architecture (e.g., amd64) |
| **source/** | Source format (quilt) and local options for source packages |
| **patches/** | config.patch and diff.patch for source package reconstruction |
| **image.files**, **headers.files**, **libc-dev.files**, **image-dbg.files** | File manifests (initially empty, populated during build) |

---

### 4. **Overall Build Flow (make deb-pkg)**

```
make deb-pkg
    ↓
[Scripts/Makefile.package line 119-133]
    ├─→ debian-orig target (lines 105-115)
    │   ├─→ mkdebian --need-source
    │   │   └─→ Generates debian/, debian/source/, debian/patches/
    │   ├─→ Creates linux.tar.gz (git archive)
    │   └─→ Copies to parent as \<source\>_\<version\>.orig.tar.gz
    │
    └─→ dpkg-buildpackage (lines 126-133)
        ├─→ Build mode: source,binary
        ├─→ Runs debian/rules build-arch (line 79)
        │   ├─→ make olddefconfig (configure kernel)
        │   └─→ make headers all (build kernel + modules)
        │
        └─→ Runs debian/rules binary (line 70)
            ├─→ binary-arch target (line 72)
            │   ├─→ binary-image (calls builddeb linux-image-*)
            │   ├─→ binary-headers (calls builddeb linux-headers-*)
            │   ├─→ binary-libc-dev (calls builddeb linux-libc-dev)
            │   └─→ binary-image-dbg (calls builddeb linux-image-*-dbg)
            │
            └─→ dh_* packaging steps (lines 51-61):
                ├─→ dh_installdocs/dh_installchangelogs
                ├─→ dh_compress/dh_fixperms
                ├─→ dh_gencontrol (with .files manifests)
                ├─→ dh_md5sums
                └─→ dh_builddeb (creates .deb packages)
```

---

### 5. **Key Helper Scripts**

| Script | Function |
|--------|----------|
| **builddeb** | Routes package type → install functions: kernel image, modules, debug symbols, headers |
| **mkdebian** | Architecture detection, changelog/control generation, patch setup |
| **install-extmod-build** | Copies Makefiles, headers, scripts to /usr/src/ for external module compilation |

---

### 6. **Package Assembly Details**

**builddeb** dispatches on package name:

- **linux-image-\***: 
  - Installs modules (`make modules_install`)
  - Installs kernel image (`vmlinuz-*` or `vmlinux-*` depending on arch)
  - Installs System.map, .config to /boot
  - Installs maintainer scripts (postinst, prerm, etc.) for initramfs hooks

- **linux-headers-\***: 
  - Calls `install-extmod-build` → copies headers, Makefiles to `/usr/src/linux-headers-*`
  - Creates `/lib/modules/*/build` symlink

- **linux-libc-dev**: 
  - Runs `make headers_install` → public userspace headers to `/usr/include`
  - Moves asm headers for multi-arch support

- **linux-image-\*-dbg** (if CONFIG_DEBUG_INFO=y):
  - Extracts debug symbols from vmlinux
  - Stores in `/usr/lib/debug/lib/modules/*/vmlinux`
  - Creates `.build-id/` symlinks for debuggers

---

### Output Artifacts
- `linux-upstream_\<version\>.orig.tar.gz` (source)
- `linux-upstream_\<version\>-\<rev\>.debian.tar.gz` (patches/rules)
- `*.dsc` (source package description)
- `linux-image-*.deb` (kernel + modules)
- `linux-headers-*.deb` (development headers)
- `linux-libc-dev_*.deb` (userspace headers)
- `linux-image-*-dbg_*.deb` (debug symbols, if enabled)


---

<sub>⏱️ 3m 4s</sub>

### 💭 Reasoning

*Good overview. Let me also look at the actual files to get more specific details about the scripts.*

---

<sub>⏱️ 3m 5s</sub>

### 💬 Copilot

Here's a summary of the `deb-pkg` packaging pipeline:

**Entry point:** `scripts/Makefile.package` defines `deb-pkg`, `bindeb-pkg`, and `srcdeb-pkg` targets. `deb-pkg` builds both source and binary packages via `dpkg-buildpackage`.

**Key scripts in `scripts/package/`:**
- **`mkdebian`** — generates the `debian/` directory (control, changelog, rules, patches) dynamically before each build
- **`builddeb`** — the main installation script invoked by `debian/rules`; dispatches by package type to install the kernel image, modules, headers, libc-dev headers, and debug symbols
- **`install-extmod-build`** — copies headers/Makefiles to `/usr/src/linux-headers-*` for external module builds

**Packages produced:**
| Package | Contents |
|---|---|
| `linux-image-*` | kernel image, modules, System.map, .config, initramfs hooks |
| `linux-headers-*` | build tree for external modules |
| `linux-libc-dev` | userspace kernel headers (`/usr/include`) |
| `linux-image-*-dbg` | debug symbols (if `CONFIG_DEBUG_INFO=y`) |

**Flow:** `make deb-pkg` → `mkdebian` generates `debian/` → `dpkg-buildpackage` runs `debian/rules build-arch` (builds kernel) then `debian/rules binary` (calls `builddeb` for each package type, then `dh_*` helpers to assemble `.deb` files).

What would you like to work on?

---

<sub>⏱️ 6m 58s</sub>

### 👤 User

Building the packages fails when the kernel's release information contains capital letters (with error messages of the form 'dh_listpackages: error: Package-field must be a valid package name, got: "linux-image-7.0.0-rc22026030501-microsoft-custom-WSL2+", should match "(?^:^(?^:[a-z0-9][-+\.a-z0-9]+)$)"'). Since WSL detection requires that the capital letters be present, we need to modify the packaging pipeline to convert capital letters in the kernel release to lower case when generating a package name, but leave them intact for all other uses.

---

<sub>⏱️ 6m 59s</sub>

### 💭 Reasoning

*Let me look at the relevant packaging scripts to understand where package names are generated from the kernel release string.*

---

<sub>⏱️ 7m 3s</sub>

### ✅ `bash`

**Read mkdebian script**

$ cat -n /wrk/avatar/src/linux/scripts/package/mkdebian

<details>
<summary>274 lines</summary>

```
1	#!/bin/sh
     2	#
     3	# Copyright 2003 Wichert Akkerman <wichert@wiggy.net>
     4	#
     5	# Simple script to generate a debian/ directory for a Linux kernel.
     6	
     7	set -eu
     8	
     9	is_enabled() {
    10		grep -q "^$1=y" include/config/auto.conf
    11	}
    12	
    13	if_enabled_echo() {
    14		if is_enabled "$1"; then
    15			echo -n "$2"
    16		elif [ $# -ge 3 ]; then
    17			echo -n "$3"
    18		fi
    19	}
    20	
    21	set_debarch() {
    22		if [ "${KBUILD_DEBARCH:+set}" ]; then
    23			debarch="$KBUILD_DEBARCH"
    24			return
    25		fi
    26	
    27		# Attempt to find the correct Debian architecture
    28		case "$UTS_MACHINE" in
    29		i386|alpha|m68k|riscv*)
    30			debarch="$UTS_MACHINE" ;;
    31		x86_64)
    32			debarch=amd64 ;;
    33		sparc*)
    34			debarch=sparc$(if_enabled_echo CONFIG_64BIT 64) ;;
    35		s390*)
    36			debarch=s390x ;;
    37		ppc*)
    38			if is_enabled CONFIG_64BIT; then
    39				debarch=ppc64$(if_enabled_echo CONFIG_CPU_LITTLE_ENDIAN el)
    40			else
    41				debarch=powerpc$(if_enabled_echo CONFIG_SPE spe)
    42			fi
    43			;;
    44		parisc*)
    45			debarch=hppa ;;
    46		mips*)
    47			if is_enabled CONFIG_CPU_LITTLE_ENDIAN; then
    48				debarch=mips$(if_enabled_echo CONFIG_64BIT 64)$(if_enabled_echo CONFIG_CPU_MIPSR6 r6)el
    49			elif is_enabled CONFIG_CPU_MIPSR6; then
    50				debarch=mips$(if_enabled_echo CONFIG_64BIT 64)r6
    51			else
    52				debarch=mips
    53			fi
    54			;;
    55		aarch64|arm64)
    56			debarch=arm64 ;;
    57		arm*)
    58			if is_enabled CONFIG_AEABI; then
    59				debarch=arm$(if_enabled_echo CONFIG_VFP hf el)
    60			else
    61				debarch=arm
    62			fi
    63			;;
    64		openrisc)
    65			debarch=or1k ;;
    66		sh)
    67			if is_enabled CONFIG_CPU_SH3; then
    68				debarch=sh3$(if_enabled_echo CONFIG_CPU_BIG_ENDIAN eb)
    69			elif is_enabled CONFIG_CPU_SH4; then
    70				debarch=sh4$(if_enabled_echo CONFIG_CPU_BIG_ENDIAN eb)
    71			fi
    72			;;
    73		um)
    74			if is_enabled CONFIG_64BIT; then
    75				debarch=amd64
    76			else
    77				debarch=i386
    78			fi
    79			;;
    80		loongarch64)
    81			debarch=loong64 ;;
    82		esac
    83		if [ -z "$debarch" ]; then
    84			debarch=$(dpkg-architecture -qDEB_HOST_ARCH)
    85			echo "" >&2
    86			echo "** ** **  WARNING  ** ** **" >&2
    87			echo "" >&2
    88			echo "Your architecture doesn't have its equivalent" >&2
    89			echo "Debian userspace architecture defined!" >&2
    90			echo "Falling back to the current host architecture ($debarch)." >&2
    91			echo "Please add support for $UTS_MACHINE to ${0} ..." >&2
    92			echo "" >&2
    93		fi
    94	}
    95	
    96	# Create debian/source/ if it is a source package build
    97	gen_source ()
    98	{
    99		mkdir -p debian/source
   100	
   101		echo "3.0 (quilt)" > debian/source/format
   102	
   103		{
   104			echo "diff-ignore"
   105			echo "extend-diff-ignore = .*"
   106		} > debian/source/local-options
   107	
   108		# Add .config as a patch
   109		mkdir -p debian/patches
   110		{
   111			echo "Subject: Add .config"
   112			echo "Author: ${maintainer}"
   113			echo
   114			echo "--- /dev/null"
   115			echo "+++ linux/.config"
   116			diff -u /dev/null "${KCONFIG_CONFIG}" | tail -n +3
   117		} > debian/patches/config.patch
   118		echo config.patch > debian/patches/series
   119	
   120		"${srctree}/scripts/package/gen-diff-patch" debian/patches/diff.patch
   121		if [ -s debian/patches/diff.patch ]; then
   122			sed -i "
   123				1iSubject: Add local diff
   124				1iAuthor: ${maintainer}
   125				1i
   126			" debian/patches/diff.patch
   127	
   128			echo diff.patch >> debian/patches/series
   129		else
   130			rm -f debian/patches/diff.patch
   131		fi
   132	}
   133	
   134	rm -rf debian
   135	mkdir debian
   136	
   137	user=${KBUILD_BUILD_USER:-$(id -nu)}
   138	name=${DEBFULLNAME:-${user}}
   139	if [ "${DEBEMAIL:+set}" ]; then
   140		email=${DEBEMAIL}
   141	else
   142		buildhost=${KBUILD_BUILD_HOST:-$(hostname -f 2>/dev/null || hostname)}
   143		email="${user}@${buildhost}"
   144	fi
   145	maintainer="${name} <${email}>"
   146	
   147	while [ $# -gt 0 ]; do
   148		case "$1" in
   149		--need-source)
   150			gen_source
   151			shift
   152			;;
   153		*)
   154			break
   155			;;
   156		esac
   157	done
   158	
   159	# Some variables and settings used throughout the script
   160	if [ "${KDEB_PKGVERSION:+set}" ]; then
   161		packageversion=$KDEB_PKGVERSION
   162	else
   163		upstream_version=$("${srctree}/scripts/setlocalversion" --no-local "${srctree}" | sed 's/-\(rc[1-9]\)/~\1/')
   164		debian_revision=$("${srctree}/scripts/build-version")
   165		packageversion=${upstream_version}-${debian_revision}
   166	fi
   167	sourcename=${KDEB_SOURCENAME:-linux-upstream}
   168	
   169	if [ "$ARCH" = "um" ] ; then
   170		packagename=user-mode-linux
   171	else
   172		packagename=linux-image
   173	fi
   174	
   175	debarch=
   176	set_debarch
   177	
   178	# Try to determine distribution
   179	if [ "${KDEB_CHANGELOG_DIST:+set}" ]; then
   180	        distribution=$KDEB_CHANGELOG_DIST
   181	# In some cases lsb_release returns the codename as n/a, which breaks dpkg-parsechangelog
   182	elif distribution=$(lsb_release -cs 2>/dev/null) && [ -n "$distribution" ] && [ "$distribution" != "n/a" ]; then
   183	        : # nothing to do in this case
   184	else
   185	        distribution="unstable"
   186	        echo >&2 "Using default distribution of 'unstable' in the changelog"
   187	        echo >&2 "Install lsb-release or set \$KDEB_CHANGELOG_DIST explicitly"
   188	fi
   189	
   190	echo $debarch > debian/arch
   191	
   192	host_gnu=$(dpkg-architecture -a "${debarch}" -q DEB_HOST_GNU_TYPE | sed 's/_/-/g')
   193	
   194	# Generate a simple changelog template
   195	cat <<EOF > debian/changelog
   196	$sourcename ($packageversion) $distribution; urgency=low
   197	
   198	  * Custom built Linux kernel.
   199	
   200	 -- $maintainer  $(date -R)
   201	EOF
   202	
   203	# Generate a control file
   204	cat <<EOF > debian/control
   205	Source: $sourcename
   206	Section: kernel
   207	Priority: optional
   208	Maintainer: $maintainer
   209	Rules-Requires-Root: no
   210	Build-Depends: debhelper-compat (= 12)
   211	Build-Depends-Arch: bc, bison, flex,
   212	 gcc-${host_gnu} <!pkg.${sourcename}.nokernelheaders>,
   213	 kmod, libdw-dev:native, libelf-dev:native,
   214	 libssl-dev:native, libssl-dev <!pkg.${sourcename}.nokernelheaders>,
   215	 python3:native, rsync
   216	Homepage: https://www.kernel.org/
   217	
   218	Package: $packagename-${KERNELRELEASE}
   219	Architecture: $debarch
   220	Description: Linux kernel, version ${KERNELRELEASE}
   221	 This package contains the Linux kernel, modules and corresponding other
   222	 files, version: ${KERNELRELEASE}.
   223	EOF
   224	
   225	if [ "${SRCARCH}" != um ]; then
   226	cat <<EOF >> debian/control
   227	
   228	Package: linux-libc-dev
   229	Section: devel
   230	Provides: linux-kernel-headers
   231	Architecture: $debarch
   232	Description: Linux support headers for userspace development
   233	 This package provides userspaces headers from the Linux kernel.  These headers
   234	 are used by the installed headers for GNU glibc and other system libraries.
   235	Multi-Arch: same
   236	EOF
   237	
   238	if is_enabled CONFIG_MODULES; then
   239	cat <<EOF >> debian/control
   240	
   241	Package: linux-headers-${KERNELRELEASE}
   242	Architecture: $debarch
   243	Build-Profiles: <!pkg.${sourcename}.nokernelheaders>
   244	Description: Linux kernel headers for ${KERNELRELEASE} on $debarch
   245	 This package provides kernel header files for ${KERNELRELEASE} on $debarch
   246	 .
   247	 This is useful for people who need to build external modules
   248	EOF
   249	fi
   250	fi
   251	
   252	if is_enabled CONFIG_DEBUG_INFO; then
   253	cat <<EOF >> debian/control
   254	
   255	Package: linux-image-${KERNELRELEASE}-dbg
   256	Section: debug
   257	Architecture: $debarch
   258	Build-Profiles: <!pkg.${sourcename}.nokerneldbg>
   259	Description: Linux kernel debugging symbols for ${KERNELRELEASE}
   260	 This package will come in handy if you need to debug the kernel. It provides
   261	 all the necessary debug symbols for the kernel and its modules.
   262	EOF
   263	fi
   264	
   265	cat <<EOF > debian/rules.vars
   266	ARCH := ${ARCH}
   267	KERNELRELEASE := ${KERNELRELEASE}
   268	EOF
   269	
   270	cp "${srctree}/scripts/package/debian/copyright" debian/
   271	cp "${srctree}/scripts/package/debian/rules" debian/
   272	
   273	exit 0
<exited with exit code 0>
```

</details>


---

<sub>⏱️ 7m 3s</sub>

### ✅ `bash`

**Read builddeb script**

$ cat -n /wrk/avatar/src/linux/scripts/package/builddeb

<details>
<summary>171 lines</summary>

```
1	#!/bin/sh
     2	#
     3	# builddeb 1.3
     4	# Copyright 2003 Wichert Akkerman <wichert@wiggy.net>
     5	#
     6	# Simple script to generate a deb package for a Linux kernel. All the
     7	# complexity of what to do with a kernel after it is installed or removed
     8	# is left to other scripts and packages. Scripts can be placed into the
     9	# preinst, postinst, prerm and postrm directories in /etc/kernel or
    10	# /usr/share/kernel. A different list of search directories can be given
    11	# via KDEB_HOOKDIR. Scripts in directories earlier in the list will
    12	# override scripts of the same name in later directories.  The script will
    13	# be called on package installation and removal.
    14	
    15	set -eu
    16	
    17	is_enabled() {
    18		grep -q "^$1=y" include/config/auto.conf
    19	}
    20	
    21	if_enabled_echo() {
    22		if is_enabled "$1"; then
    23			echo -n "$2"
    24		elif [ $# -ge 3 ]; then
    25			echo -n "$3"
    26		fi
    27	}
    28	
    29	install_linux_image () {
    30		pname=$1
    31		pdir=debian/$1
    32	
    33		# Only some architectures with OF support have this target
    34		if is_enabled CONFIG_OF_EARLY_FLATTREE && [ -d "${srctree}/arch/${SRCARCH}/boot/dts" ]; then
    35			${MAKE} -f ${srctree}/Makefile INSTALL_DTBS_PATH="${pdir}/usr/lib/linux-image-${KERNELRELEASE}" dtbs_install
    36		fi
    37	
    38		${MAKE} -f ${srctree}/Makefile INSTALL_MOD_PATH="${pdir}" INSTALL_MOD_STRIP=1 modules_install
    39		rm -f "${pdir}/lib/modules/${KERNELRELEASE}/build"
    40	
    41		# Install the kernel
    42		if [ "${ARCH}" = um ] ; then
    43			mkdir -p "${pdir}/usr/lib/uml/modules"
    44			mv "${pdir}/lib/modules/${KERNELRELEASE}" "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}"
    45			mkdir -p "${pdir}/usr/bin" "${pdir}/usr/share/doc/${pname}"
    46			cp System.map "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}/System.map"
    47			cp ${KCONFIG_CONFIG} "${pdir}/usr/share/doc/${pname}/config"
    48			gzip "${pdir}/usr/share/doc/${pname}/config"
    49		else
    50			mkdir -p "${pdir}/boot"
    51			cp System.map "${pdir}/boot/System.map-${KERNELRELEASE}"
    52			cp ${KCONFIG_CONFIG} "${pdir}/boot/config-${KERNELRELEASE}"
    53		fi
    54	
    55		# Not all arches have the same installed path in debian
    56		# XXX: have each arch Makefile export a variable of the canonical image install
    57		# path instead
    58		case "${SRCARCH}" in
    59		um)
    60			installed_image_path="usr/bin/linux-${KERNELRELEASE}";;
    61		parisc|mips|powerpc)
    62			installed_image_path="boot/vmlinux-${KERNELRELEASE}";;
    63		*)
    64			installed_image_path="boot/vmlinuz-${KERNELRELEASE}";;
    65		esac
    66		cp "$(${MAKE} -s -f ${srctree}/Makefile image_name)" "${pdir}/${installed_image_path}"
    67	
    68		if [ "${ARCH}" != um ]; then
    69			install_maint_scripts "${pdir}"
    70		fi
    71	}
    72	
    73	install_maint_scripts () {
    74		# Install the maintainer scripts
    75		# Note: hook scripts under /etc/kernel are also executed by official Debian
    76		# kernel packages, as well as kernel packages built using make-kpkg.
    77		# make-kpkg sets $INITRD to indicate whether an initramfs is wanted, and
    78		# so do we; recent versions of dracut and initramfs-tools will obey this.
    79		debhookdir=${KDEB_HOOKDIR:-/etc/kernel /usr/share/kernel}
    80		for script in postinst postrm preinst prerm; do
    81			mkdir -p "${pdir}/DEBIAN"
    82			cat <<-EOF > "${pdir}/DEBIAN/${script}"
    83			#!/bin/sh
    84	
    85			set -e
    86	
    87			# Pass maintainer script parameters to hook scripts
    88			export DEB_MAINT_PARAMS="\$*"
    89	
    90			# Tell initramfs builder whether it's wanted
    91			export INITRD=$(if_enabled_echo CONFIG_BLK_DEV_INITRD Yes No)
    92	
    93			# run-parts will error out if one of its directory arguments does not
    94			# exist, so filter the list of hook directories accordingly.
    95			hookdirs=
    96			for dir in ${debhookdir}; do
    97				test -d "\$dir/${script}.d" || continue
    98				hookdirs="\$hookdirs \$dir/${script}.d"
    99			done
   100			hookdirs="\${hookdirs# }"
   101			test -n "\$hookdirs" && run-parts --arg="${KERNELRELEASE}" --arg="/${installed_image_path}" \$hookdirs
   102			exit 0
   103			EOF
   104			chmod 755 "${pdir}/DEBIAN/${script}"
   105		done
   106	}
   107	
   108	install_linux_image_dbg () {
   109		pdir=debian/$1
   110	
   111		# Parse modules.order directly because 'make modules_install' may sign,
   112		# compress modules, and then run unneeded depmod.
   113		if is_enabled CONFIG_MODULES; then
   114			while read -r mod; do
   115				mod="${mod%.o}.ko"
   116				dbg="${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/kernel/${mod}"
   117				buildid=$("${READELF}" -n "${mod}" | sed -n 's@^.*Build ID: \(..\)\(.*\)@\1/\2@p')
   118				link="${pdir}/usr/lib/debug/.build-id/${buildid}.debug"
   119	
   120				mkdir -p "${dbg%/*}" "${link%/*}"
   121				"${OBJCOPY}" --only-keep-debug "${mod}" "${dbg}"
   122				ln -sf --relative "${dbg}" "${link}"
   123			done < modules.order
   124		fi
   125	
   126		# Build debug package
   127		# Different tools want the image in different locations
   128		# perf
   129		mkdir -p ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
   130		cp vmlinux ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
   131		# systemtap
   132		mkdir -p ${pdir}/usr/lib/debug/boot/
   133		ln -s ../lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/boot/vmlinux-${KERNELRELEASE}
   134		# kdump-tools
   135		ln -s lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/vmlinux-${KERNELRELEASE}
   136	}
   137	
   138	install_kernel_headers () {
   139		pdir=debian/$1
   140		version=${1#linux-headers-}
   141	
   142		CC="${DEB_HOST_GNU_TYPE}-gcc" "${srctree}/scripts/package/install-extmod-build" "${pdir}/usr/src/linux-headers-${version}"
   143	
   144		mkdir -p $pdir/lib/modules/$version/
   145		ln -s /usr/src/linux-headers-$version $pdir/lib/modules/$version/build
   146	}
   147	
   148	install_libc_headers () {
   149		pdir=debian/$1
   150	
   151		$MAKE -f $srctree/Makefile headers_install INSTALL_HDR_PATH=$pdir/usr
   152	
   153		# move asm headers to /usr/include/<libc-machine>/asm to match the structure
   154		# used by Debian-based distros (to support multi-arch)
   155		mkdir "$pdir/usr/include/${DEB_HOST_MULTIARCH}"
   156		mv "$pdir/usr/include/asm" "$pdir/usr/include/${DEB_HOST_MULTIARCH}"
   157	}
   158	
   159	package=$1
   160	
   161	case "${package}" in
   162	*-dbg)
   163		install_linux_image_dbg "${package}";;
   164	linux-image-*|user-mode-linux-*)
   165		install_linux_image "${package}";;
   166	linux-libc-dev)
   167		install_libc_headers "${package}";;
   168	linux-headers-*)
   169		install_kernel_headers "${package}";;
   170	esac
<exited with exit code 0>
```

</details>


---

<sub>⏱️ 7m 4s</sub>

### 💭 Reasoning

*Now I have a clear picture. In `mkdebian`, package names are constructed directly using `${KERNELRELEASE}`:

- Line 218: `Package: $packagename-${KERNELRELEASE}` (linux-image-*)
- Line 241: `Package: linux-headers-${KERNELRELEASE}`
- Line 255: `Package: linux-image-${KERNELRELEASE}-dbg`

The fix is to introduce a `packagerelease` variable that is `${KERNELRELEASE}` lowercased, and use it specifically for package names (the `Package:` fields in the control file), while keeping `${KERNELRELEASE}` for everything else (descriptions, file paths, etc.).


I'll add a line to lowercase `KERNELRELEASE` into a `packagerelease` variable and then swap it in for those three `Package:` field lines. Since `builddeb` receives the package name as an argument, it should already be lowercased once I fix `mkdebian`.

Now I need to check the `debian/rules` file and `scripts/package/debian/rules` to see if there are other places where package names are being constructed that might also need this lowercase treatment.*

---

<sub>⏱️ 7m 12s</sub>

### ✅ `bash`

**Read debian/rules template**

$ cat -n /wrk/avatar/src/linux/scripts/package/debian/rules

<details>
<summary>98 lines</summary>

```
1	#!/usr/bin/make -f
     2	# SPDX-License-Identifier: GPL-2.0-only
     3	
     4	# in case debian/rules is executed directly
     5	export DEB_RULES_REQUIRES_ROOT := no
     6	
     7	include debian/rules.vars
     8	
     9	ifneq (,$(filter-out parallel=1,$(filter parallel=%,$(DEB_BUILD_OPTIONS))))
    10	    NUMJOBS = $(patsubst parallel=%,%,$(filter parallel=%,$(DEB_BUILD_OPTIONS)))
    11	    MAKEFLAGS += -j$(NUMJOBS)
    12	endif
    13	
    14	# When KBUILD_VERBOSE is undefined (presumably you are directly working with
    15	# the debianized tree), show verbose logs unless DEB_BUILD_OPTION=terse is set.
    16	ifeq ($(origin KBUILD_VERBOSE),undefined)
    17	    ifeq (,$(filter terse,$(DEB_BUILD_OPTIONS)))
    18	        export KBUILD_VERBOSE := 1
    19	    else
    20	        Q := @
    21	    endif
    22	endif
    23	
    24	revision = $(shell dpkg-parsechangelog -S Version | sed -n 's/.*-//p')
    25	CROSS_COMPILE ?= $(filter-out $(DEB_BUILD_GNU_TYPE)-, $(DEB_HOST_GNU_TYPE)-)
    26	make-opts = ARCH=$(ARCH) KERNELRELEASE=$(KERNELRELEASE) \
    27	    $(addprefix KBUILD_BUILD_VERSION=,$(revision)) \
    28	    $(addprefix CROSS_COMPILE=,$(CROSS_COMPILE))
    29	
    30	binary-targets := $(addprefix binary-, image image-dbg headers libc-dev)
    31	
    32	all-packages = $(shell dh_listpackages)
    33	image-package = $(filter linux-image-% user-%, $(filter-out %-dbg, $(all-packages)))
    34	image-dbg-package = $(filter %-dbg, $(all-packages))
    35	libc-dev-package = $(filter linux-libc-dev, $(all-packages))
    36	headers-package = $(filter linux-headers-%, $(all-packages))
    37	
    38	mk-files = $(patsubst binary-%,debian/%.files,$1)
    39	package = $($(@:binary-%=%-package))
    40	
    41	# DH_OPTION is an environment variable common for all debhelper commands.
    42	# We could 'export' it, but here it is passed from the command line to clarify
    43	# which package is being processed in the build log.
    44	DH_OPTIONS = -p$(package)
    45	
    46	# Note: future removal of KDEB_COMPRESS
    47	# dpkg-deb >= 1.21.10 supports the DPKG_DEB_COMPRESSOR_TYPE environment
    48	# variable, which provides the same functionality as KDEB_COMPRESS. The
    49	# KDEB_COMPRESS variable will be removed in the future.
    50	define binary
    51		$(Q)dh_testdir $(DH_OPTIONS)
    52		$(Q)dh_testroot $(DH_OPTIONS)
    53		$(Q)dh_prep $(DH_OPTIONS)
    54		$(Q)+$(MAKE) $(make-opts) run-command KBUILD_RUN_COMMAND='+$$(srctree)/scripts/package/builddeb $(package)'
    55		$(Q)dh_installdocs $(DH_OPTIONS)
    56		$(Q)dh_installchangelogs $(DH_OPTIONS)
    57		$(Q)dh_compress $(DH_OPTIONS)
    58		$(Q)dh_fixperms $(DH_OPTIONS)
    59		$(Q)dh_gencontrol $(DH_OPTIONS) -- -f$(call mk-files,$@)
    60		$(Q)dh_md5sums $(DH_OPTIONS)
    61		$(Q)dh_builddeb $(DH_OPTIONS) -- $(addprefix -Z,$(KDEB_COMPRESS))
    62	endef
    63	
    64	.PHONY: $(binary-targets)
    65	$(binary-targets): build-arch
    66		$(Q)truncate -s0 $(call mk-files,$@)
    67		$(if $(package),$(binary))
    68	
    69	.PHONY: binary binary-indep binary-arch
    70	binary: binary-arch binary-indep
    71	binary-indep: build-indep
    72	binary-arch: $(binary-targets)
    73		$(Q)cat $(call mk-files,$^) > debian/files
    74	
    75	.PHONY: build build-indep build-arch
    76	build: build-arch build-indep
    77	build-indep:
    78	build-arch:
    79		$(Q)$(MAKE) $(make-opts) olddefconfig
    80		$(Q)$(MAKE) $(make-opts) $(if $(filter um,$(ARCH)),,headers) all
    81	
    82	.PHONY: clean
    83	clean:
    84		$(Q)dh_clean
    85		$(Q)rm -rf debian/deb-env.vars* debian/*.files
    86		$(Q)$(MAKE) ARCH=$(ARCH) clean
    87	
    88	# If DEB_HOST_ARCH is empty, it is likely that debian/rules was executed
    89	# directly. Run 'dpkg-architecture --print-set --print-format=make' to
    90	# generate a makefile construct that exports all DEB_* variables.
    91	ifndef DEB_HOST_ARCH
    92	include debian/deb-env.vars
    93	
    94	debian/deb-env.vars:
    95		$(Q)dpkg-architecture -a$$(cat debian/arch) --print-set --print-format=make > $@.tmp
    96		$(Q)mv $@.tmp $@
    97	endif
<exited with exit code 0>
```

</details>


---

<sub>⏱️ 7m 15s</sub>

### 💭 Reasoning

*Now I have a clear picture. The issue is specifically in `mkdebian` where package names are constructed using `${KERNELRELEASE}` directly:

- Line 218: `Package: $packagename-${KERNELRELEASE}` (e.g., `linux-image-7.0.0-rc22026030501-microsoft-custom-WSL2+`)
- Line 241: `Package: linux-headers-${KERNELRELEASE}`
- Line 255: `Package: linux-image-${KERNELRELEASE}-dbg`

The fix is simple: introduce a `packagerelease` variable that lowercases `KERNELRELEASE`, and use it only in the `Package:` lines in the control file. All other uses of `KERNELRELEASE` (descriptions, file paths, maintainer scripts, etc.) should remain unchanged.


I'll implement this by creating a lowercase variant of the kernel release after setting the package name, then substituting it into just the package name fields while leaving everything else untouched. I'm tracing through the `builddeb` script to see how the package name gets parsed and used in the `install_kernel_headers` function—it strips the `linux-headers-` prefix to get the version, which is then used to construct the actual directory paths and symlinks for the kernel headers installation. The issue is that `$version` comes from the package name (lowercased), but modules are actually installed under `${KERNELRELEASE}` (original case), so the symlink path in `install_kernel_headers` needs to use `KERNELRELEASE` instead of `version` to point to the correct directory. Let me check the `install_kernel_headers` function to see exactly where this mismatch occurs... The issue is that the symlink path needs to use the original `KERNELRELEASE` value (which preserves the uppercase characters) rather than the lowercased `version`, since the running system expects modules to be in `/lib/modules/${KERNELRELEASE}`. So I need to adjust the symlink creation to reference `KERNELRELEASE` instead, while keeping the headers directory name based on the package's lowercased version. The symlink needs to point from the actual `KERNELRELEASE` directory to the lowercased headers path, so the build system can find the headers regardless of case differences. I'm realizing this might already be working correctly in the current implementation, so I should verify whether this is actually a problem. even exists. Currently, the `version` variable in `install_kernel_headers` strips the package name prefix. If the package name IS `linux-headers-7.0.0-rc2-WSL2` (uppercase), then the build directory being set up would be at `lib/modules/7.0.0-rc2-WSL2/build`. 

But the fix we're making is to lowercase the package name in `mkdebian`. So after the fix:
- Package name: `linux-headers-7.0.0-rc2-wsl2` (lowercase)
- `version` derived in `builddeb`: `7.0.0-rc2-wsl2` (lowercase)
- But `KERNELRELEASE` in the environment: `7.0.0-rc2-WSL2` (original case)
- Modules installed to: `lib/modules/7.0.0-rc2-WSL2/`

This creates a mismatch—the headers package would create `lib/modules/7.0.0-rc2-wsl2/build` (lowercase) while the kernel image installs modules to `lib/modules/7.0.0-rc2-WSL2/` (uppercase). I need to fix `install_kernel_headers` in `builddeb` to use `KERNELRELEASE` for the module directory path instead. Since `KERNELRELEASE` is exported in `rules.vars` and available during the build, I can reference it directly in the make options. I need to update the package names in the control file templates to use the lowercase version of the kernel release, while keeping the actual `KERNELRELEASE` variable for build rules and descriptions. In the builddeb script, I'll need to adjust the header installation path to use the same lowercase packagerelease variable for consistency.*

---

<sub>⏱️ 7m 54s</sub>

### 💬 Copilot

Now I have a clear picture of what needs to change. The package names are formed in `mkdebian` using `${KERNELRELEASE}` directly on lines 218, 241, and 255. There's also a secondary issue in `builddeb`'s `install_kernel_headers`: it derives the module directory path from the package name (which will be lowercased), but modules are installed under the original-case `${KERNELRELEASE}` — those need to match.

The fix:
1. **`mkdebian`**: introduce `packagerelease` (lowercased `KERNELRELEASE`) and use it only for `Package:` name lines
2. **`builddeb`**: use `${KERNELRELEASE}` (not the package-name-derived `$version`) for the `lib/modules/` symlink path

---

<sub>⏱️ 8m 28s</sub>

### ✅ `edit`

**edit the file at /wrk/avatar/src/linux/scripts/package/mkdebian.**

/wrk/avatar/src/linux/scripts/package/mkdebian

```
File /wrk/avatar/src/linux/scripts/package/mkdebian updated with changes.
```


---

<sub>⏱️ 8m 26s</sub>

### ✅ `edit`

**edit the file at /wrk/avatar/src/linux/scripts/package/builddeb.**

/wrk/avatar/src/linux/scripts/package/builddeb

```
File /wrk/avatar/src/linux/scripts/package/builddeb updated with changes.
```


---

<sub>⏱️ 8m 29s</sub>

### 💬 Copilot

Now replace the three `Package:` name lines in `mkdebian` to use `${packagerelease}` while keeping descriptions using `${KERNELRELEASE}`:

---

<sub>⏱️ 8m 37s</sub>

### ✅ `edit`

**edit the file at /wrk/avatar/src/linux/scripts/package/mkdebian.**

/wrk/avatar/src/linux/scripts/package/mkdebian

```
File /wrk/avatar/src/linux/scripts/package/mkdebian updated with changes.
```


---

<sub>⏱️ 8m 39s</sub>

### ✅ `edit`

**edit the file at /wrk/avatar/src/linux/scripts/package/mkdebian.**

/wrk/avatar/src/linux/scripts/package/mkdebian

```
File /wrk/avatar/src/linux/scripts/package/mkdebian updated with changes.
```


---

<sub>⏱️ 8m 41s</sub>

### ✅ `edit`

**edit the file at /wrk/avatar/src/linux/scripts/package/mkdebian.**

/wrk/avatar/src/linux/scripts/package/mkdebian

```
File /wrk/avatar/src/linux/scripts/package/mkdebian updated with changes.
```


---

<sub>⏱️ 8m 43s</sub>

### 💬 Copilot

Now let me verify both files look correct:

---

<sub>⏱️ 8m 46s</sub>

### ✅ `bash`

**Check mkdebian changes**

$ grep -n 'packagerelease\|KERNELRELEASE\|packagename' /wrk/avatar/src/linux/scripts/package/mkdebian

<details>
<summary>14 lines</summary>

```
170:	packagename=user-mode-linux
172:	packagename=linux-image
175:# Debian package names must be lowercase; KERNELRELEASE may contain uppercase
178:packagerelease=$(echo "${KERNELRELEASE}" | tr 'A-Z' 'a-z')
223:Package: $packagename-${packagerelease}
225:Description: Linux kernel, version ${KERNELRELEASE}
227: files, version: ${KERNELRELEASE}.
246:Package: linux-headers-${packagerelease}
249:Description: Linux kernel headers for ${KERNELRELEASE} on $debarch
250: This package provides kernel header files for ${KERNELRELEASE} on $debarch
260:Package: linux-image-${packagerelease}-dbg
264:Description: Linux kernel debugging symbols for ${KERNELRELEASE}
272:KERNELRELEASE := ${KERNELRELEASE}
<exited with exit code 0>
```

</details>


---

<sub>⏱️ 8m 46s</sub>

### ✅ `bash`

**Check builddeb changes**

$ grep -n 'version\|KERNELRELEASE' /wrk/avatar/src/linux/scripts/package/builddeb | grep -A2 -B2 'modules'

<details>
<summary>19 lines</summary>

```
35:		${MAKE} -f ${srctree}/Makefile INSTALL_DTBS_PATH="${pdir}/usr/lib/linux-image-${KERNELRELEASE}" dtbs_install
39:	rm -f "${pdir}/lib/modules/${KERNELRELEASE}/build"
44:		mv "${pdir}/lib/modules/${KERNELRELEASE}" "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}"
46:		cp System.map "${pdir}/usr/lib/uml/modules/${KERNELRELEASE}/System.map"
51:		cp System.map "${pdir}/boot/System.map-${KERNELRELEASE}"
52:		cp ${KCONFIG_CONFIG} "${pdir}/boot/config-${KERNELRELEASE}"
--
78:	# so do we; recent versions of dracut and initramfs-tools will obey this.
101:		test -n "\$hookdirs" && run-parts --arg="${KERNELRELEASE}" --arg="/${installed_image_path}" \$hookdirs
116:			dbg="${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/kernel/${mod}"
129:	mkdir -p ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
130:	cp vmlinux ${pdir}/usr/lib/debug/lib/modules/${KERNELRELEASE}/
133:	ln -s ../lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/boot/vmlinux-${KERNELRELEASE}
135:	ln -s lib/modules/${KERNELRELEASE}/vmlinux ${pdir}/usr/lib/debug/vmlinux-${KERNELRELEASE}
140:	version=${1#linux-headers-}
142:	CC="${DEB_HOST_GNU_TYPE}-gcc" "${srctree}/scripts/package/install-extmod-build" "${pdir}/usr/src/linux-headers-${version}"
144:	mkdir -p $pdir/lib/modules/${KERNELRELEASE}/
145:	ln -s /usr/src/linux-headers-$version $pdir/lib/modules/${KERNELRELEASE}/build
<exited with exit code 0>
```

</details>


---

<sub>⏱️ 8m 47s</sub>

### 💬 Copilot

Both changes are correct. Here's a summary of what was done:

**`scripts/package/mkdebian`** — Added `packagerelease=$(echo "${KERNELRELEASE}" | tr 'A-Z' 'a-z')` and used it in all three `Package:` name lines in `debian/control`. All `Description:` fields, `rules.vars`, and every other reference still use `${KERNELRELEASE}` unchanged.

**`scripts/package/builddeb`** — In `install_kernel_headers`, the `lib/modules/` directory and build symlink now use `${KERNELRELEASE}` instead of `$version` (which was derived from the lowercased package name). This ensures the symlink lands in `lib/modules/7.0.0-rc2-WSL2/build` — matching where `modules_install` actually puts the modules — while the headers directory in `/usr/src/` still carries the lowercase package name.

---

<sub>⏱️ 9m 29s</sub>

### ❌ Error

Failed to share session: Error: ENOENT: no such file or directory, open '/wrk/avatar/src/linux/session ./modifications'

---

<sub>Generated by [GitHub Copilot CLI](https://github.com/features/copilot/cli)</sub>

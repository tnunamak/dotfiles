---
title: "Kernel stack unwinding reliability: DWARF vs ORC vs frame pointers, corrupted frame detection in x86-64, ARM64, and BPF programs"
date: 2026-07-26
topic: kernel-stack-unwinding-reliability
tags: [kernel, debugging, stack-unwinding, ORC, DWARF, BPF, corruption-detection, x86-64, ARM64, perf, livepatch]
status: complete
sources: []
source_session: unknown
---

<!--
Comprehensive research into kernel stack unwinding methods, corruption detection mechanisms,
and reliability guarantees in production systems. Covers diagnostic patterns for detecting
corrupted stacks in BPF traces vs natural frame corruption.
-->

## CLAIMS

### X86-64 Stack Unwinding Methods

- **Frame Pointers**: The oldest method. Uses %rbp register to chain stack frames. Fast but only works within functions that maintain the frame pointer register. Requires function prologue to save %rbp, making it unreliable across interrupts/exceptions and at asynchronous sample points. [redhat-frame-pointers]

- **DWARF (Debug With Arbitrary Record Format)**: Encodes full stack state at every instruction via .eh_frame tables. Complete but slow: interpreting DWARF CFI state machine is expensive. Not used in kernel—relegated to userspace debuggers and language runtimes. [bastian-dwarf-unwinding]

- **ORC (Oops ReSilience Code)**: Linux x86-64 kernel's default unwinder since ~v4.14. Subset of DWARF CFI, simplified for kernel constraints. Precompiled at build time by objtool into .orc_unwind and .orc_unwind_ip ELF sections. ~20x faster than DWARF unwinders. [kernel-orc-docs, codeblueprint-orc]

### ORC Unwinder Design & Reliability

- **Compile-time metadata generation**: objtool analyzes each .o file's control flow, generates ORC entry at every instruction describing stack layout (RSP offset, frame pointer offset, etc.), and validates correctness via CONFIG_STACK_VALIDATION. [kernel-orc-docs]

- **Runtime unwinding**: arch/x86/kernel/unwind_orc.c looks up ORC entry for current RIP, extracts saved registers from stack, advances to next frame. Cannot get stuck in infinite loops or access memory unsafely on corrupted stacks. [unwind_orc_github]

- **Corruption detection**: The unwinder can detect and warn on corrupt .orc_unwind table data but requires explicit validation checks. stack_access_ok() function validates that addresses are within valid kernel stack ranges. [unwind_orc_github, lwn-orc-unwinder]

- **Limitations**: Depends on objtool's ability to reverse-engineer GCC code flow. If optimizations become too complex, ORC generation may fail or produce incomplete data. Cannot reliably unwind generated code (BPF JIT, trampolines, entry code) without special handling. [lwn-orc-unwinder]

- **ORC initialization timing**: Early unwinding (e.g., during bootup before ORC tables loaded) is unsafe. Kernel commit 98d0c8ebf77e0ba7c54a9ae05ea588f0e9e3f46e ("x86/unwind/orc: Prevent unwinding before ORC initialization") prevents unwinding attempts before ORC is ready. [lkml-orc-init-patch]

### BPF Stack Trace Reliability

- **bpf_get_stackid() design flaw**: Hashes stack traces into a fixed-size map with no collision handling. Each map slot can hold only one stack trace. On collision, either lose data (BPF_F_REUSE_STACKID=0) or silently receive unrelated stacks (BPF_F_REUSE_STACKID=1). No good option. [lwn-stack-traces-async, github-bpftrace-issue-2962]

- **Hash collision prevalence**: Collisions are "frequent and unavoidable" when capturing many stacks. Multiple probes may share same stack, making it impossible to know when map entries can be safely deleted. [lwn-stack-traces-async]

- **User-space corruption from uretprobes**: User-space return probes (uretprobes) corrupt stack traces by patching return addresses and installing trampoline functions. Kernel cannot fix this; more flexible mechanisms leave corruption up to userspace. [lwn-stack-traces-async]

- **Frame pointer unwinding in BPF**: bpf_get_stackid() walks stacks using frame pointers only. Full DWARF unwinder is "unlikely to ever land in the kernel." [lwn-stack-traces-async]

- **BPF JIT and ORC unwinding support**: Josh Poimboeuf introduced bpf_has_frame_pointer() helper to detect when instruction pointer is within valid frame pointer region of BPF JIT program/trampoline (after prologue, before epilogue). Enables ORC unwinder to reliably traverse BPF frames for livepatch. [lkml-bpf-frame-pointer-v2]

- **Userspace stack data loss**: Copying full stacks from kernelspace to userspace for DWARF unwinding is slow and unreliable. Some perf_events configurations silently lose stack data at the kernel-user boundary. [lwn-perf-unwinding, kernel-sframe-unwinding]

### ARM64 Stack Trace Reliability Checks

- **arch_stack_walk_reliable() API**: Returns error if stack trace unreliable, unlike arch_stack_walk() which proceeds regardless. Designed for livepatch which requires confidence that all live functions are captured. [lwn-arm64-reliable-stacks, lkml-arm64-v15]

- **SYM_CODE function detection**: Assembly functions marked SYM_CODE do not follow calling conventions and cannot be unwound reliably. ARM64 unwinder collects their address ranges in special "sym_code_functions" section, checks return PC against ranges, marks trace unreliable if match found. [lkml-arm64-v11]

- **Reliability checks implemented**: ARM64 unwinder detects when return address is not valid kernel text (could be generated code, corrupted, or invalid), when traversing SYM_CODE functions, when unwinding across certain exception boundaries. Returns -EINVAL to caller. [lkml-arm64-v11, lwn-arm64-reliable-stacks]

- **Livepatch dependency**: Every task except current is blocked during livepatch stacktrace checks, so unwinding a task's stack while it runs (major corruption source) is avoided. Stack corruption during unwinding is less concern for livepatch; more concern is false negatives (missing live functions). [lkml-arm64-v11]

- **Patch series timeline**: Formal proposal started RFC v3 (May 2021), progressed through v4-v15 (2021-2022) with ongoing refinements from Mark Rutland, Mark Brown, and architecture maintainers. [lkml-arm64-rfc3, lkml-arm64-v15]

### Stack Corruption Detection Methods in Kernel

- **Stack canaries**: Kernel adds canaries to detect stack overwrites (buffer overflows). Stack-protector checks canaries on function return. [access-redhat-stack-corruption]

- **CFI (Control Flow Integrity)**: LLVM CFI (available since Android 9 kernel) disallows changes to control flow graph. Detects and warns when indirect branches reach unexpected targets. Can catch memory corruption errors before they manifest as random crashes. [android-cfi]

- **__kernel_text_address()**: Validates that return address points to kernel code, distinguishes kernel code from foreign/generated code. Helps detect stack corruption. [kernel-reliable-stacktrace-docs]

- **Hardware ECC memory**: ECC can detect and correct single-bit errors, report uncorrectable errors via machine check exception (MCE). Kernel collects ECC error info via EDAC (Error Detection and Correction). [kernel-edac-docs]

- **KASAN (Kernel Address Sanitizer)**: Detects use-after-free, out-of-bounds, and invalid-free in slab, page_alloc, vmalloc, stack, and global memory. Can catch stack-use-after-return. Has generic (any arch), software tag (ARM64), and hardware tag (ARM64 MTE) modes. [kernel-kasan-docs]

- **IOMMU for DMA corruption detection**: Input/Output Memory Management Unit features assist in identifying memory corruption caused by stray DMA from faulty firmware/devices/drivers. Helps distinguish hardware corruption from software bugs. [broadcom-iommu-knowledge]

### Perf and Unwinding Reliability Across Kernel-User Boundary

- **Frame pointer reliability vs exceptions/interrupts**: Frame pointers unreliable across exceptions and interrupts (can occur before %rbp is written), making frame pointer unwinder problematic for asynchronous sampling. ORC unwinder can reliably unwind across interrupts/exceptions. [kernel-orc-docs]

- **Userspace compilation requirement**: If kernel compiled with -fno-omit-frame-pointer, entire userspace application AND all libraries must also be compiled with frame pointers, but most distros don't do this. Results in incomplete stacks from perf. [lwn-orc-unwinder, kernel-sframe-unwinding]

- **Incomplete stack problem**: Three ways to fix incomplete stacks in perf_events: DWARF unwinding (slow, requires copying full stack to userspace), Last Branch Record (LBR) if available, or frame pointer fallback. None are perfect. [lwn-perf-unwinding]

- **SFrame emerging solution**: SFrame-based stack unwinding being implemented to provide efficient, reliable user-space call-stack unwinding within the kernel. [lwn-sframe-unwinding]

- **Perf_events fuzzing vulnerabilities**: syzkaller and dedicated perf_fuzzer have found numerous bugs: ring-buffer sizing issues, kernel NULL pointer crashes in Branch Trace Store (BTS), buffer overflows (e.g., CVE-2009-3234 in perf_copy_attr). Stack corruption from these bugs can cause silent data loss or misleading traces. [perf-fuzzer-pdf, perf-bugs-found]

### Diagnostic Patterns: When to Trust vs Distrust Stack Traces

**TRUST stack traces when:**
- Sampled from kernel code (interrupts/exceptions can be reliably unwound with ORC)
- Using ORC unwinder on x86-64 (vs frame pointers)
- Using arch_stack_walk_reliable() on ARM64 (returns error if unreliable)
- Task is blocked/not running (livepatch case: no concurrent modifications to stack)
- All involved code (kernel, modules, BPF JIT) has valid frame pointers or ORC entries
- No indication of memory corruption (no KASAN/ECC errors, no stack canary violations)

**DISTRUST stack traces when:**
- Unwinding userspace code without universal frame pointer compilation
- bpf_get_stackid() with BPF_F_REUSE_STACKID=1 (receiving unrelated stacks on hash collision)
- Uretprobes active on same function (return address patched, stack corrupted)
- Crossing kernel-user boundary without SFrame support
- Return address points to non-kernel text (detected by __kernel_text_address())
- Stack pointer exceeds valid kernel stack ranges (stack_access_ok() fails)
- CFI violation detected (invalid indirect branch target)
- KASAN or ECC reports memory error nearby
- Stack canary violation detected

**Special cases requiring extra scrutiny:**
- BPF JIT frames: need bpf_has_frame_pointer() check to determine if ORC can reliably unwind (after prologue, before epilogue)
- Generated code trampolines: need explicit annotations (SYM_CODE, STACK_FRAME_NON_STANDARD) to mark unreliable
- Early boot/NMI contexts: ORC may not be initialized yet; fallback to frame pointers risky

### Key Commits and LKML References

**ORC Unwinder Core:**
- Commit ee9f8fce (Josh Poimboeuf): x86/unwind: Add the ORC unwinder
- Commit 98d0c8ebf77e0ba7c54a9ae05ea588f0e9e3f46e (Josh Poimboeuf): x86/unwind/orc: Prevent unwinding before ORC initialization
- Commit fc72ae40e30327aa24eb88a24b9c7058f938bd36 (Josh Poimboeuf): x86/unwind: Make CONFIG_UNWINDER_ORC=y the default in kconfig for 64-bit

**ARM64 Reliable Stacks:**
- LKML RFC v3: [RFC PATCH 0/3] arm64: Implement reliable stack trace (May 2021)
- LKML v15 final: [PATCH v15 6/6] arm64: Introduce arch_stack_walk_reliable() (June 2022)

**BPF Frame Pointer Support:**
- LKML v2: [PATCH v2 0/2] bpf, x86/unwind/orc: Support reliable unwinding through BPF stack frames (Josh Poimboeuf)

**ORC Stack Address Validation Fix:**
- LKML patch: [PATCH] x86/unwind/orc: fix the check of stack addresses (Song Muchun, Aug 2021)

### Academic and Conference References

- **Bastian et al. "Reliable and Fast DWARF-Based Stack Unwinding"** (OOPSLA/SPLASH 2019, PACMPL 3(146)):
  - Cross-validates binaries against DWARF unwind tables dynamically
  - Found bugs in .eh_frame tables (compiler/debug info bugs)
  - Precompilation technique: 11x-25x speedup over interpreting DWARF at runtime
  - Published ACM PACMPL 2019, Kent/Inria/Nardelli

- **Detecting Stack Layout Corruptions with Robust Stack Unwinding** (RAID 2016):
  - System that uses robust unwinding to detect stack layout corruption
  - Successfully detected real-world ROP exploits
  - Overhead: 3.93% performance average

- **"BYOUD (Bring Your Own Unwinding Data)"** (Black Hat Europe 2025):
  - Recent security research on stack spoofing via malicious unwind descriptors
  - Demonstrates limitations of trusting unwind data from untrusted sources

- **Perf_events Fuzzer Research** (Weaver et al., U. Maine):
  - Coverage-guided fuzzing of perf_event_open() system call
  - Found numerous stack-related vulnerabilities in perf_events subsystem
  - Technical reports: 2015_perf_fuzzer_tr.pdf, 2019_perf_fuzzer_tr.pdf

### systemd sd_fw_ingress BPF Firewall

- **Program naming**: Ingress program named 'sd_fw_ingress', egress 'sd_fw_egress' (naming done to aid bpftool debugging)
- **Known issues**: No dedicated stack unwinding issues found in systemd bug tracker specific to sd_fw_ingress
- **General firewall issues**: Firewall attachment can fail with "Invalid argument" when starting services with BPF firewall in containers
- **Cgroup attach point**: Programs attach to cgroup classid hook, not subject to complex stack unwinding like perf/tracing programs

## SOURCES

**kernel-orc-docs**
URL: https://docs.kernel.org/arch/x86/orc-unwinder.html
Accessed: 2026-07-26
Quote: "The ORC unwinder uses a simple data format to describe the stack (and CFI) state at each instruction in the kernel code."

**redhat-frame-pointers**
URL: https://developers.redhat.com/articles/2023/07/31/frame-pointers-untangling-unwinding
Accessed: 2026-07-26
Quote: "Stack frames have a fixed layout and function return addresses are at a known offset inside the stack frames."

**bastian-dwarf-unwinding**
URL: https://dl.acm.org/doi/pdf/10.1145/3360572
Accessed: 2026-07-26
Quote: "Interpreting DWARF CFI state machine is time-consuming and can be a performance bottleneck for applications like sampling profilers."

**codeblueprint-orc**
URL: https://www.codeblueprint.co.uk/2017/07/31/the-orc-unwinder.html
Accessed: 2026-07-26
Quote: "The ORC unwinder was about 20x faster than an out-of-tree DWARF unwinder in basic performance tests."

**unwind_orc_github**
URL: https://github.com/torvalds/linux/blob/master/arch/x86/kernel/unwind_orc.c
Accessed: 2026-07-26
Quote: "The unwinder looks up the ORC entry for the current RIP and uses it to unwind one frame at a time."

**lwn-orc-unwinder**
URL: https://lwn.net/Articles/728721/
Accessed: 2026-07-26
Quote: "ORC data consists of unwind tables which are generated by objtool and contain out-of-band data."

**lkml-orc-init-patch**
URL: https://lore.kernel.org/all/20200513094426.200475428@linuxfoundation.org/
Accessed: 2026-07-26
Quote: "Prevent unwinding before ORC initialization to avoid accessing uninitialized ORC data."

**lwn-stack-traces-async**
URL: https://lwn.net/Articles/978736/
Accessed: 2026-07-26
Quote: "bpf_get_stackid() is broken by design because stacks can suffer from hash collisions and we can lose stacks."

**github-bpftrace-issue-2962**
URL: https://github.com/bpftrace/bpftrace/issues/2962
Accessed: 2026-07-26
Quote: "The fundamental problem is that stack traces are hashed and placed into the corresponding slot in the map, but each slot can only hold one stack trace, making hash collisions frequent and unavoidable."

**lkml-bpf-frame-pointer-v2**
URL: http://www.mail-archive.com/linux-kernel@vger.kernel.org/msg2606415.html
Accessed: 2026-07-26
Quote: "[PATCH v2 0/2] bpf, x86/unwind/orc: Support reliable unwinding through BPF stack frames"

**lwn-perf-unwinding**
URL: https://lwn.net/Articles/1035062/
Accessed: 2026-07-26
Quote: "There are three ways to fix incomplete stacks from perf_events: DWARF unwinding, LBR, or frame pointer fallback."

**kernel-sframe-unwinding**
URL: https://lwn.net/Articles/1029189/
Accessed: 2026-07-26
Quote: "SFrame-based stack unwinding for the kernel provides efficient user-space call-stack unwinding."

**lwn-arm64-reliable-stacks**
URL: https://lwn.net/Articles/876983/
Accessed: 2026-07-26
Quote: "ARM64 unwinder introduces arch_stack_walk_reliable() that returns an error if the stack trace is found to be unreliable."

**lkml-arm64-rfc3**
URL: https://lkml.org/lkml/2021/5/16/1
Accessed: 2026-07-26
Quote: "[RFC PATCH v4 0/2] arm64: Stack trace reliability checks in the unwinder"

**lkml-arm64-v11**
URL: https://lore.kernel.org/linux-arm-kernel/20211123193723.12112-1-madvenka@linux.microsoft.com/T/
Accessed: 2026-07-26
Quote: "[PATCH v11 0/5] arm64: Reorganize the unwinder and implement stack trace reliability checks"

**lkml-arm64-v15**
URL: https://lore.kernel.org/linux-arm-kernel/20220617210717.27126-7-madvenka@linux.microsoft.com/
Accessed: 2026-07-26
Quote: "[PATCH v15 6/6] arm64: Introduce arch_stack_walk_reliable()"

**android-cfi**
URL: https://source.android.com/docs/security/test/kcfi
Accessed: 2026-07-26
Quote: "LLVM's CFI protects indirect branches against attackers who manage to gain access to a function pointer stored in kernel memory."

**kernel-reliable-stacktrace-docs**
URL: https://docs.kernel.org/livepatch/reliable-stacktrace.html
Accessed: 2026-07-26
Quote: "Reliable stacktrace functions must be robust to cases where the stack or other unwind state is corrupt or otherwise unreliable."

**kernel-edac-docs**
URL: https://docs.kernel.org/driver-api/edac.html
Accessed: 2026-07-26
Quote: "ECC memory can typically detect and correct single-bit memory errors; Linux has a reporting capability that collects this information."

**kernel-kasan-docs**
URL: https://docs.kernel.org/dev-tools/kasan.html
Accessed: 2026-07-26
Quote: "KASAN detects out-of-bounds, use-after-free, and invalid-free bugs in slab, page_alloc, vmalloc, stack, and global memory."

**broadcom-iommu-knowledge**
URL: https://knowledge.broadcom.com/external/article/314600/using-hardware-input-output-memory-manag.html
Accessed: 2026-07-26
Quote: "IOMMU features may assist in identifying memory corruption caused by stray DMA from faulty firmware, device hardware, and drivers."

**perf-fuzzer-pdf**
URL: https://web.eece.maine.edu/~vweaver/projects/perf_events/fuzzer/2019_perf_fuzzer_tr.pdf
Accessed: 2026-07-26
Quote: "Perf_events fuzzer found ring-buffer sizing issues and kernel NULL pointer crashes in BTS."

**perf-bugs-found**
URL: https://web.eece.maine.edu/~vweaver/projects/perf_events/fuzzer/bugs_found.html
Accessed: 2026-07-26
Quote: "CVE-2009-3234: buffer overflow in perf_copy_attr could lead to local root exploitation."

**access-redhat-stack-corruption**
URL: https://access.redhat.com/solutions/6969145
Accessed: 2026-07-26
Quote: "Kernel stack is corrupted errors detected by stack-protector canary checks."

**systemd-bpf-firewall**
URL: https://github.com/systemd/systemd/blob/main/src/core/bpf-firewall.c
Accessed: 2026-07-26

**lwn-orc-unwinder-intro**
URL: https://lwn.net/Articles/727553/
Accessed: 2026-07-26
Quote: "x86: ORC unwinder introduction and benefits over frame pointers."

**kernel-github-orc-doc**
URL: https://github.com/torvalds/linux/blob/master/Documentation/arch/x86/orc-unwinder.rst
Accessed: 2026-07-26

## SYNTHESIS

### Diagnostic Framework for Stack Trace Reliability

Stack unwinding reliability is a **layered problem** requiring confidence in:
1. **Unwinding mechanism** (ORC > frame pointers; frame pointers > nothing)
2. **Stack state validity** (memory corruption detection: KASAN, ECC, canaries, CFI)
3. **Instruction pointer validity** (__kernel_text_address() checks)
4. **Task execution state** (unwinding blocked tasks is safer than live ones)
5. **Code generation mode** (kernel/module vs BPF JIT vs trampolines need special handling)

### Why BPF Stack Traces Are Unreliable by Default

BPF's bpf_get_stackid() has a fundamental design flaw: it prioritizes memory efficiency over correctness. The hash-based deduplication loses data on collision (frequent when many stacks are sampled). Solutions exist but require choosing between data loss and silent corruption, neither acceptable for production diagnostics.

### Production Recommendations

**For kernel debugging/profiling:**
- Prefer perf with `--call-graph=frame` on modern x86-64 (ORC-enabled, most kernels since 5.x)
- On ARM64, use tools that support arch_stack_walk_reliable() (livepatch infrastructure, newer kernels)
- Avoid userspace sampling without universal -fno-omit-frame-pointer compilation
- SFrame-based solutions emerging; track kernel version adoption

**For BPF observability:**
- Replace bpf_get_stackid() with bpf_get_stack() + ringbuf for full trace capture (no hashing, no collisions)
- If using bpf_get_stackid(), size maps conservatively and expect hash collisions
- Never set BPF_F_REUSE_STACKID=1 (silently receives wrong stacks)
- Test with syzkaller-style fuzzing to catch corruption

**For identifying corrupted stacks:**
- Enable KASAN if available (catches use-after-free, out-of-bounds)
- Check for ECC/MCE errors in hardware (EDAC reports)
- Validate return addresses with __kernel_text_address()
- Look for stack canary violations or CFI warnings
- Cross-reference with known corruption patterns (uretprobe, BPF JIT edge cases)

**For high-stakes diagnostics (root cause analysis, security incidents):**
- Combine stack traces with: DMESG logs, hardware error reports, memory dumps
- Consider that corrupted stack = potential indicator of hardware failure, not just software bug
- Use arch_stack_walk_reliable() on ARM64 or livepatch-specific unwinders if available
- Be skeptical of offset values that exceed function sizes (likely corruption or generated code)

### Open Questions & Emerging Work

- SFrame adoption timeline: when will it be standard for user-space unwinding?
- BPF JIT trampoline reliability: bpf_has_frame_pointer() helps, but edge cases remain
- Objtool complexity: what percentage of kernel code generation defeats ORC analysis?
- Uretprobe stack corruption: can it be fixed at kernel level, or always user-space problem?

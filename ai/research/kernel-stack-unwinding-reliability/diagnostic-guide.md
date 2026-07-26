# Kernel Stack Unwinding: Quick Diagnostic Guide

## When Should You Trust a Stack Trace?

### YES - Trust It
- **ORC unwinder output on x86-64** (Linux 4.14+, default since 5.x)
  - Symmetric across interrupts/exceptions
  - Compile-time validation via objtool
  - Fast (20x vs DWARF)
  
- **arch_stack_walk_reliable() on ARM64** (Linux 5.x+)
  - Returns error if unreliable (don't ignore)
  - Designed for livepatch consistency checks
  
- **Blocked task stacks** (task not running)
  - No concurrent stack modifications
  - Safer than sampling live tasks
  - Livepatch's use case
  
- **Kernel code only** (no userspace, no trampolines)
  - If all return addresses validate with `__kernel_text_address()`
  - If no KASAN/ECC warnings
  - If stack canary not violated

### NO - Distrust It
- **bpf_get_stackid() with BPF_F_REUSE_STACKID=1** (any kernel)
  - Silently returns wrong stack on hash collision (happens often)
  - Use `bpf_get_stack()` + ringbuf instead
  
- **Userspace stacks without universal frame pointers**
  - App + all libraries must be compiled with `-fno-omit-frame-pointer`
  - Most distros don't do this
  - Results in incomplete traces
  
- **Return address points to non-kernel text**
  - Check with `__kernel_text_address()`
  - Indicates corrupted stack or generated code not annotated
  
- **Unwinding with uretprobes active**
  - uretprobe modifies return address on stack
  - Corrupts kernel trace of patched function
  - Use uprobes on RET instruction instead
  
- **Offset exceeds function size**
  - Likely corrupted stack or unrecognized generated code
  - Compare with objdump to verify function bounds
  
- **Stack canary violation detected**
  - Buffer overflow, stack smashing
  - Don't trust any frame below the violation

### MAYBE - Requires Extra Context
- **BPF JIT frames**
  - Need `bpf_has_frame_pointer()` check
  - Safe if within prologue-to-epilogue region
  - Risky at entry/exit points
  
- **Trampolines (ftrace, kprobes, entry code)**
  - Marked `SYM_CODE` = explicitly unreliable
  - Check if function has `STACK_FRAME_NON_STANDARD` annotation
  - If annotated, unwinder should skip or mark unreliable
  
- **Early boot / NMI contexts**
  - ORC may not be initialized yet
  - Frame pointers might be the only option
  - Be skeptical of early boot traces (kernel_init, cpu_bringup, etc.)
  
- **Mixed frame pointer + ORC**
  - Modern x86-64 uses ORC for kernel
  - Frame pointers may be in userspace
  - Crossing kernel-user boundary = incomplete

## Corruption Diagnosis Checklist

### Hardware Corruption Indicators
- [ ] ECC memory errors in dmesg (MCE machine check exceptions)
- [ ] Multiple stack corruption crashes in same system
- [ ] Corruption in reproducible memory addresses
- [ ] Hardware error logs available (EDAC `/sys/devices/system/edac/`)
- [ ] Crashes correlate with RAM upgrade or thermal changes

### Software Corruption Indicators
- [ ] Single crash, no pattern
- [ ] Stack corruption only in one process/thread
- [ ] Happens under specific load or code path
- [ ] Nearby memory (heap, globals) also corrupted
- [ ] KASAN reports (use-after-free, out-of-bounds)

### Stack Smashing (Malicious or Bug)
- [ ] Stack canary violation message
- [ ] Return address points to non-code region (e.g., heap)
- [ ] CFI (Control Flow Integrity) warning
- [ ] Offset radically exceeds function size (e.g., 0x1000 in 100-byte function)

### False Positives (Not Actual Corruption)
- [ ] Offset high but within bounds (compiler-generated safe space)
- [ ] Return address is valid kernel text but not current function (tail call, return trampoline)
- [ ] BPF JIT frame (generated code, has frame pointer)
- [ ] FTrace trampoline (expected to be non-standard)

## Quick Reference: Unwinding Method Comparison

| Method | Speed | Reliability | Coverage | Interrupt-Safe | Best For |
|--------|-------|-------------|----------|---------------|-----------| 
| Frame Pointers | Fast | Low | Partial | No | Userspace, simple cases |
| DWARF | Slow | High | Complete | Yes | Userspace debuggers, C++ exceptions |
| ORC (x86-64) | Very Fast | High | Complete | Yes | Kernel backtraces, profiling |
| arch_stack_walk_reliable() (ARM64) | Fast | Very High | Complete | Yes | Livepatch, kernel consistency |

## Key Kernel Commits for Reference

**ORC Initialization & Prevention of Early Unwinding:**
```
98d0c8ebf77e0ba7c54a9ae05ea588f0e9e3f46e
x86/unwind/orc: Prevent unwinding before ORC initialization
```

**BPF JIT Frame Pointer Support (ORC reliable unwinding through BPF):**
```
Search LKML: [PATCH v2 0/2] bpf, x86/unwind/orc: Support reliable unwinding through BPF stack frames
Josh Poimboeuf (jpoimboe@redhat.com)
2019-2020 timeframe
```

**ARM64 Reliable Stack Traces:**
```
LKML v15 final: [PATCH v15 6/6] arm64: Introduce arch_stack_walk_reliable()
Madhavan T. Venkataraman (madvenka@linux.microsoft.com)
June 2022
Merged into Linux 5.17+
```

**ORC Stack Address Validation Fix:**
```
Song Muchun (songmuchun@bytedance.com)
August 2021
Subject: [PATCH] x86/unwind/orc: fix the check of stack addresses
Issue: get_stack_info() only checks if address is in valid range,
       ignores length parameter; after get_stack_info returns,
       range needs rechecking
```

**objtool Stack Validation (CONFIG_STACK_VALIDATION):**
```
Compile-time validation of stack metadata generation
Kernel v4.6+ (initial), evolved through v5.x
Implemented in tools/objtool/check.c
```

## Perf and BPF Profiling Red Flags

### bpf_get_stackid() Issues
```c
// BAD: Will silently return wrong stacks on collision
stack_id = bpf_get_stackid(ctx, &stack_map, BPF_F_REUSE_STACKID);

// GOOD: Get full stack, submit via ringbuf (no collision)
bpf_get_stack(ctx, &stack_data, sizeof(stack_data), 0);
bpf_ringbuf_output(&ring, &stack_data, sizeof(stack_data), 0);
```

### Userspace Stack Unwinding
```bash
# BAD: Will have gaps in userspace stack
perf record -g --call-graph=fp my_app

# BETTER (if userspace compiled with -fno-omit-frame-pointer)
perf record -g --call-graph=frame my_app

# WORKAROUND: LBR-based (requires modern CPU)
perf record -g --call-graph=lbr my_app
```

## When Hardware vs Software Debugging Matters

**Reach for Hardware Debugging (ECC, EDAC, IOMMU) when:**
- Pattern suggests memory corruption at fixed address
- Multiple independent crashes in same region
- Event log shows MCE (Machine Check Exception)
- Suspecting DMA corruption from I/O devices
- Need to exclude software as root cause

**Reach for Software Debugging (KASAN, CFI, stack canary) when:**
- Single reproducible crash with clear call chain
- Stack trace is corrupt but heap/code look fine
- Bug is in specific userspace/kernel module
- Trying to catch bugs in development

## Testing Stack Unwinding Robustness

**For ORC (x86-64):**
```bash
# Verify ORC is active
cat /proc/cmdline | grep unwinder

# Build kernel with CONFIG_STACK_VALIDATION=y to catch objtool errors

# Test with syzkaller (coverage-guided fuzzing of perf_events)
```

**For ARM64:**
```bash
# Check if livepatch is enabled
cat /proc/cmdline | grep livepatch

# Test arch_stack_walk_reliable() via livepatch consistency model
```

**For BPF:**
```bash
# Replace bpf_get_stackid() with bpf_get_stack() + ringbuf
# Size ringbuf conservatively (expect many stacks)
# Test with bcc-based fuzzing of stack capture under load
```

## References

- Kernel docs: https://docs.kernel.org/arch/x86/orc-unwinder.html
- Livepatch reliable stacktrace: https://docs.kernel.org/livepatch/reliable-stacktrace.html
- Academic: Bastian et al. "Reliable and Fast DWARF-Based Stack Unwinding" (OOPSLA 2019)
- BPF: LWN "Capturing stack traces asynchronously with BPF" (2024)
- Perf fuzzing: https://web.eece.maine.edu/~vweaver/projects/perf_events/fuzzer/bugs_found.html

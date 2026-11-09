/* Force an ELF TLS segment alignment compatible with Android ARM64 Bionic. */
.section .tdata.obscura_android_tls_align,"awT",%progbits
.p2align 6
.globl __obscura_android_tls_align
.hidden __obscura_android_tls_align
.type __obscura_android_tls_align, %object
__obscura_android_tls_align:
.byte 0
.size __obscura_android_tls_align, 1

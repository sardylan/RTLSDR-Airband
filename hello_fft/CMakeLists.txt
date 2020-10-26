add_library(hello_fft STATIC
        mailbox.c mailbox.h ../rtl_airband.h
        gpu_fft.c gpu_fft.h
        gpu_fft_twiddles.c
        gpu_fft_shaders.c
        gpu_fft_base.c
        gpu_fft_trans.h)

target_compile_options(hello_fft PRIVATE -O3 -Wall)

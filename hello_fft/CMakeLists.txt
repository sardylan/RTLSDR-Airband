include_directories(../)

add_library(hello_fft STATIC
        mailbox.c mailbox.h
        gpu_fft.c gpu_fft.h
        gpu_fft_twiddles.c
        gpu_fft_shaders.c
        gpu_fft_base.c
        gpu_fft_trans.h)

target_compile_options(hello_fft PRIVATE -O3 -Wall)

target_link_libraries(hello_fft
        dl
        bcm_host)

set_source_files_properties(gpu_fft.c PROPERTIES LANGUAGE CXX)
set_source_files_properties(gpu_fft_base.c PROPERTIES LANGUAGE CXX)
set_source_files_properties(gpu_fft_shaders.c PROPERTIES LANGUAGE CXX)
set_source_files_properties(gpu_fft_twiddles.c PROPERTIES LANGUAGE CXX)
set_source_files_properties(mailbox.c PROPERTIES LANGUAGE CXX)

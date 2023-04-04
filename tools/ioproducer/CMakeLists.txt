cmake_minimum_required(VERSION 3.0.0)
project(main VERSION 0.1.0)

aux_source_directory(. DIR_SRCS)
add_executable(main ${DIR_SRCS})
target_link_libraries(main pmem pthread)
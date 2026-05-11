cmake_minimum_required(VERSION 4.1)
project(asm LANGUAGES ASM C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/tmp")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/build/asm_pure_obj")
file(MAKE_DIRECTORY "${CMAKE_SOURCE_DIR}/build/asm_file_obj")

function(collect_asm_objects out_var source_dir output_dir)
    file(GLOB asm_sources CONFIGURE_DEPENDS "${source_dir}/*.s")
    set(obj_files)

    foreach(asm_source IN LISTS asm_sources)
        get_filename_component(asm_name "${asm_source}" NAME_WE)
        set(obj_file "${output_dir}/${asm_name}.obj")

        add_custom_command(
                OUTPUT "${obj_file}"
                COMMAND "${CMAKE_ASM_COMPILER}" -c "${asm_source}" -o "${obj_file}"
                DEPENDS "${asm_source}"
                VERBATIM
        )

        list(APPEND obj_files "${obj_file}")
    endforeach()

    set(${out_var} "${obj_files}" PARENT_SCOPE)
endfunction()

collect_asm_objects(ASM_PURE_OBJECTS "${CMAKE_SOURCE_DIR}/asm_pure" "${CMAKE_SOURCE_DIR}/build/asm_pure_obj")
collect_asm_objects(ASM_FILE_OBJECTS "${CMAKE_SOURCE_DIR}/asm_file" "${CMAKE_SOURCE_DIR}/build/asm_file_obj")

set(READWRITEFILE_OBJ "${CMAKE_SOURCE_DIR}/build/asm_file_obj/readwritefile.obj")
set(HEAP_OBJ_COMPAT "${CMAKE_SOURCE_DIR}/build/asm_file_obj/heap.obj")

add_library(http_asm STATIC
        asm_pure/sock.s
        asm_pure/httpclient.s
        asm_pure/httpserver.s
)
target_link_libraries(http_asm PUBLIC ws2_32)

add_executable(compiler
        compiler/compiler.cpp
        compiler/lexer.cpp
        compiler/parser.cpp
        compiler/SemanticAnalyser.cpp
        compiler/CollectionLexer.cpp
        compiler/ArrayLexer.cpp
        compiler/IR.cpp
        compiler/IRGenerator.cpp
        compiler/CodeGenerator.cpp
        compiler/LinkingRuntime.cpp
)
target_link_libraries(compiler PRIVATE
        kernel32
        ntdll
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/badaapi_ptrs.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/integer.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/long.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/double.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/boolean.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/array.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/map.obj"
        "${READWRITEFILE_OBJ}"
        "${HEAP_OBJ_COMPAT}"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/thread.obj"
        "${CMAKE_SOURCE_DIR}/build/asm_pure_obj/string.obj"
)

add_executable(executor_cpp
        executor/executor.c
)

add_executable(string_main
        asm_pure/string.s
        asm_pure/badaapi_ptrs.s
        asm_pure/string_main.cpp
)
set_source_files_properties(asm_pure/string_main.cpp PROPERTIES LANGUAGE C)
set_source_files_properties(asm_pure/string_main.cpp PROPERTIES COMPILE_OPTIONS "-std=gnu11")
target_link_libraries(string_main PRIVATE ntdll)

add_executable(aleka_main
        asm_pure/aleka.s
        asm_pure/string.s
        asm_pure/badaapi_ptrs.s
        asm_file/readwritefile.s
        asm_file/heap.s
        asm_pure/aleka_main.cpp
)
target_link_libraries(aleka_main PRIVATE ntdll)

add_executable(ArrayLexer_main
        compiler_asm/ArrayLexer.s
        compiler_asm/ArrayLexer_main.cpp
)

add_executable(CodeGenerator_main
        compiler_asm/CodeGenerator.s
        compiler_asm/CodeGenerator_main.cpp
)

add_executable(CollectionLexer_main
        compiler_asm/CollectionLexer.s
        compiler_asm/CollectionLexer_main.cpp
)

add_executable(IR_main
        compiler_asm/IR.s
        compiler_asm/IR_main.cpp
)

add_executable(IRGenerator_main
        compiler_asm/IRGenerator.s
        compiler_asm/IRGenerator_main.cpp
)

add_executable(Lexer_main
        compiler_asm/Lexer.s
        compiler_asm/Lexer_main.cpp
)

add_executable(LinkingRuntime_main
        compiler_asm/LinkingRuntime.s
        compiler_asm/LinkingRuntime_main.cpp
)

add_executable(Parser_main
        compiler_asm/Parser.s
        compiler_asm/Parser_main.cpp
)

add_executable(SemanticAnalyser_main
        compiler_asm/SemanticAnalyser.s
        compiler_asm/SemanticAnalyser_main.cpp
)

add_executable(Compiler_main
        compiler_asm/Compiler.s
        compiler_asm/Compiler_main.cpp
)

add_executable(CollectionAnalyser_main
        compiler_asm/CollectionAnalyser.s
        compiler_asm/CollectionAnalyser_main.cpp
)

add_executable(bada_symbols
        asm_pure/map.s
        asm_pure/string.s
        asm_pure/badaapi_ptrs.s
)
target_link_libraries(bada_symbols PRIVATE ntdll)

add_custom_target(asm_pure_obj_runtime
        DEPENDS
        ${ASM_PURE_OBJECTS}
)

add_dependencies(executor_cpp asm_pure_obj_runtime asm_file_obj_runtime)

add_custom_target(asm_file_obj_runtime
        DEPENDS
        ${ASM_FILE_OBJECTS}
)

add_dependencies(compiler asm_pure_obj_runtime asm_file_obj_runtime)

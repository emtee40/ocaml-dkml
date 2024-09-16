# Does `git subtree split --rejoin` but tags+branches the commit (retagging and rebranching as necessary).
#
# Similar to `git subtree split --rejoin --branch` but addresses a bug in that behavior:
#   The `git subtree split --rejoin --branch <x>` fails if <x> exists, so deleting the
#   <x> branch if it existed was the previous behavior. But there was no creation <x>
#   if there was no change to the rejoin commit. So no way to use --rejoin --branch
#   consistently.

# git -c core.fsmonitor=false avoids `error: daemon terminated` lines, esp. on Windows
set(git_OPTS -c core.fsmonitor=false)

if(NOT GIT_EXECUTABLE OR NOT SUBTREE_PREFIX OR NOT SUBTREE_REF)
    message(FATAL_ERROR "Invalid subtree-split.cmake arguments")
endif()

function(delete_local_tag_if_exists)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${git_OPTS} show-ref --quiet "refs/tags/${SUBTREE_REF}"
        # Do not use: COMMAND_ERROR_IS_FATAL ANY
        RESULT_VARIABLE statuscode
    )
    if(statuscode EQUAL 0)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} ${git_OPTS} tag --delete "${SUBTREE_REF}"
            COMMAND_ECHO STDOUT
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()    
endfunction()
function(delete_local_branch_if_exists)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${git_OPTS} show-ref --quiet "refs/heads/${SUBTREE_REF}"
        # Do not use: COMMAND_ERROR_IS_FATAL ANY
        RESULT_VARIABLE statuscode
    )
    if(statuscode EQUAL 0)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} ${git_OPTS} branch --delete --force "${SUBTREE_REF}"
            COMMAND_ECHO STDOUT
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()    
endfunction()

function(create_tag_and_branch commit_id)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${git_OPTS} tag "${SUBTREE_REF}" "${commit_id}"
        COMMAND_ECHO STDOUT
        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${git_OPTS} branch "${SUBTREE_REF}" "${commit_id}"
        COMMAND_ECHO STDOUT
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

macro(do_subtree_split)    
    execute_process(
        COMMAND ${GIT_EXECUTABLE} ${git_OPTS} subtree split --prefix "${SUBTREE_PREFIX}" --rejoin ${SUBTREE_SQUASH_OPTIONS}
        COMMAND_ERROR_IS_FATAL ANY
        OUTPUT_STRIP_TRAILING_WHITESPACE
        # Examples:
        #   1. Subtree is already at commit d3bad8cc922c05960dea56682948316faee5efdc. (standard error)
        #   2. 00a22decddc521b4bf30ff2be412059ae691c97c (standard output)
        #   3. <what is message when rejoin point changes?>
        OUTPUT_VARIABLE split_output_stdout
        ERROR_VARIABLE split_output_stderr
    )
endmacro()
macro(proceed gitref)
    delete_local_branch_if_exists()
    delete_local_tag_if_exists()
    create_tag_and_branch("${gitref}")
endmacro()

do_subtree_split()
if(split_output_stdout MATCHES "([0-9a-f]+)")
    proceed("${CMAKE_MATCH_1}")
elseif(split_output_stderr MATCHES "already at commit ([0-9a-f]+)")
    proceed("${CMAKE_MATCH_1}")
else()
    # Likely: The `git subtree split` succeeded but had a merge. Rerun so the commit id is reported back by `git subtree`.
    do_subtree_split()
    if(split_output_stdout MATCHES "([0-9a-f]+)")
        proceed("${CMAKE_MATCH_1}")
    elseif(split_output_stderr MATCHES "already at commit ([0-9a-f]+)")
        proceed("${CMAKE_MATCH_1}")
    else()
        # Likely: The `git subtree split` succeeded but had a merge. Rerun so the commit id is reported back by `git subtree`.
        message(FATAL_ERROR "The `git subtree split` succeeded. However, even after running twice it has not reported back the commit id (or we don't recognize it).\nstdout:\n${split_output_stdout}\nstderr:\n${split_output_stderr}")
    endif()
endif()

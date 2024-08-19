# Does `git subtree split --rejoin` but tags+branches the commit (retagging and rebranching as necessary).
#
# Similar to `git subtree split --rejoin --branch` but addresses a bug in that behavior:
#   The `git subtree split --rejoin --branch <x>` fails if <x> exists, so deleting the
#   <x> branch if it existed was the previous behavior. But there was no creation <x>
#   if there was no change to the rejoin commit. So no way to use --rejoin --branch
#   consistently.

if(NOT GIT_EXECUTABLE OR NOT SUBTREE_PREFIX OR NOT SUBTREE_REF)
    message(FATAL_ERROR "Invalid subtree-split.cmake arguments")
endif()

function(delete_local_tag_if_exists)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} show-ref --quiet "refs/tags/${SUBTREE_REF}"
        # Do not use: COMMAND_ERROR_IS_FATAL ANY
        RESULT_VARIABLE statuscode
    )
    if(statuscode EQUAL 0)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} tag --delete "${SUBTREE_REF}"
            COMMAND_ECHO STDOUT
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()    
endfunction()
function(delete_local_branch_if_exists)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} show-ref --quiet "refs/heads/${SUBTREE_REF}"
        # Do not use: COMMAND_ERROR_IS_FATAL ANY
        RESULT_VARIABLE statuscode
    )
    if(statuscode EQUAL 0)
        execute_process(
            COMMAND ${GIT_EXECUTABLE} branch --delete --force "${SUBTREE_REF}"
            COMMAND_ECHO STDOUT
            COMMAND_ERROR_IS_FATAL ANY
        )
    endif()    
endfunction()

function(create_tag_and_branch commit_id)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} tag "${SUBTREE_REF}" "${commit_id}"
        COMMAND_ECHO STDOUT
        COMMAND_ERROR_IS_FATAL ANY
    )
    execute_process(
        COMMAND ${GIT_EXECUTABLE} branch "${SUBTREE_REF}" "${commit_id}"
        COMMAND_ECHO STDOUT
        COMMAND_ERROR_IS_FATAL ANY
    )
endfunction()

execute_process(
    COMMAND ${GIT_EXECUTABLE} subtree split --prefix "${SUBTREE_PREFIX}" --rejoin ${SUBTREE_SQUASH_OPTIONS}
    COMMAND_ERROR_IS_FATAL ANY
    OUTPUT_STRIP_TRAILING_WHITESPACE
    # Examples on the standard error:
    #   1. Subtree is already at commit d3bad8cc922c05960dea56682948316faee5efdc.
    #   2. <what is message when rejoin point changes?>
    ERROR_VARIABLE split_output
)

if(split_output MATCHES "already at commit ([0-9a-f]+)")
    delete_local_branch_if_exists()
    delete_local_tag_if_exists()
    create_tag_and_branch("${CMAKE_MATCH_1}")
else()
    message(FATAL_ERROR "TODO: Parse the subtree message to get the commit id: ${split_output}")
endif()

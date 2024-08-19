# Force deletes a branch if it exists

if(NOT GIT_EXECUTABLE OR NOT BRANCH_TO_DELETE)
    message(FATAL_ERROR "Invalid branch-delete.cmake arguments")
endif()

execute_process(
    COMMAND ${GIT_EXECUTABLE} show-ref --quiet "refs/heads/${BRANCH_TO_DELETE}"
    # Do not use: COMMAND_ERROR_IS_FATAL ANY
    RESULT_VARIABLE statuscode
)
if(statuscode EQUAL 0)
    execute_process(
        COMMAND ${GIT_EXECUTABLE} branch --delete --force "${BRANCH_TO_DELETE}"
        COMMAND_ECHO STDOUT
        COMMAND_ERROR_IS_FATAL ANY
    )
endif()

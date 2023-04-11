*** Settings ***
Library     Browser


*** Keywords ***
I see the "${text_content}" text
    Wait Until Network Is Idle
    Get Page Source    *=    ${text_content}

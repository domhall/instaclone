*** Settings ***
Library     Browser


*** Keywords ***
I see the "${text_content}" text
    Wait Until Network Is Idle
    Wait Until Keyword Succeeds    10 s    1 s    Get Page Source    *=    ${text_content}

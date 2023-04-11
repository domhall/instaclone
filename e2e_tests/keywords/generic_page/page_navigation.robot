*** Settings ***
Library     Browser


*** Keywords ***
I click the "${link_text}" link
    Wait Until Network Is Idle
    Click    text=${link_text}

I click the "${link_text}" button
    Wait Until Network Is Idle
    Click    xpath=//button >> text=${link_text}

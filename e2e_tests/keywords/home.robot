*** Settings ***
Library     Browser


*** Keywords ***
I open the home page
    New Page    http://localhost:4004
    Get Title    *=    Instaclone

I click the "${link_text}" link
    Click    text=${link_text}

I click the "${link_text}" button
    Click    text=${link_text}

I see the "${text_content}" text
    Wait Until Network Is Idle
    Get Page Source    *=    ${text_content}

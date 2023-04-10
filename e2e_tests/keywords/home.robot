*** Settings ***
Library     Browser


*** Keywords ***
I open the home page
    New Page    http://localhost:4004
    Get Title    *=    Metrics

I click the "${link_text}" link
    Click    text=${link_text}

I see the "${text_content}" text
    Get Page Source    *=    ${text_content}

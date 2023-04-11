*** Settings ***
Library     Browser


*** Keywords ***
I click the "${link_text}" link
    Click    text=${link_text}

I click the "${link_text}" button
    Click    text=${link_text}

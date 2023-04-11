*** Settings ***
Library     Browser


*** Keywords ***
I enter text "${intext}" into the field "${id}"
    Fill Text    id=${id}    ${intext}

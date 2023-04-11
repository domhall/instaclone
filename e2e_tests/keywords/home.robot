*** Settings ***
Library     Browser


*** Keywords ***
I open the home page
    New Page    http://localhost:4004
    Get Title    *=    Instaclone

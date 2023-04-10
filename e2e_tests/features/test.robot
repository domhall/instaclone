*** Settings ***
Resource    ../keywords/home.robot
Library     Browser
*** Tasks ***
Simple test
    Given I open the home page
    When I click the "Follow on Twitter" link
    Then I see the "src" text

*** Settings ***
Resource    ../keywords/home.robot
Resource    ../keywords/form.robot
Library     Browser
*** Tasks ***
Registration test
    Given I navigate to the password registration page
        And I enter an email "test@example.com" and password "test123456789"
    When I click the "Create an account" button
    Then I see the "Account created successfully!" text
# Account created successfully!    
*** Keywords ***
I navigate to the password registration page
    I open the home page
    I click the "Register" link

I enter an email "${email}" and password "${password}"
    I enter text "${email}" into the field "password_user_email"
    I enter text "${password}" into the field "password_user_password"
    
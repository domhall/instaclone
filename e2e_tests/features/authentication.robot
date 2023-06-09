*** Settings ***
Resource    ../keywords/home.robot
Resource    ../keywords/generic_page/index.robot
Library     Browser
*** Tasks ***
Registration test
    Given I navigate to the password registration page
        And I enter an email "test@example.com" and password "test123456789"
    When I click the "Create an account" button
    Then I see the "Account created successfully!" text
        And I see the "test@example.com" text
Login test
    Given I navigate to the password login page
        And I enter an email "test@example.com" and password "test123456789"
    When I click the "Sign in" button
    Then I see the "Welcome back!" text
        And I see the "test@example.com" text
# Account created successfully!    
*** Keywords ***
I navigate to the password registration page
    I open the home page
    I click the "Register" link
I navigate to the password login page
    I open the home page
    I click the "Log in" link

I enter an email "${email}" and password "${password}"
    I enter text "${email}" into the field "password_user_email"
    I enter text "${password}" into the field "password_user_password"
    
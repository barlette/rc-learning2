*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Robocorp.Vault
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Archive
Library           Dialogs

*** Keywords ***
Open the robot order website
    [Arguments]    ${url}
    Open Available Browser    ${url}[url]

*** Keywords ***
Get orders
    [Arguments]    ${url}
    Download    ${url}    overwrite=True
    ${orders}=    Read Table from CSV    orders.csv    header=True
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    Click Button When Visible    xpath://button[contains(.,'OK')]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://label[contains(.,'3. Legs:')]/../input    ${row}[Legs]
    Input Text    xpath://input[@id='address']    ${row}[Address]

*** Keywords ***
Preview the robot
    Click Button    xpath://button[@id='preview']

*** Keywords ***
Submit the order
    Click Button    xpath://button[@id='order']
    Wait Until Element Is Visible    xpath://div[@id='receipt']

*** Keywords ***
Go to order another robot
    Wait And Click Button    xpath://button[@id='order-another']

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${OrderNumber}
    ${receipt}=    Get Element Attribute    xpath://div[@id='receipt']    outerHTML
    ${path}    Set Variable    ${CURDIR}${/}output${/}receipts${/}receipt_order_${OrderNumber}.pdf
    Html To Pdf    ${receipt}    ${path}
    [Return]    ${path}

*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${OrderNumber}
    ${path}    Set Variable    ${CURDIR}${/}output${/}receipts${/}preview_order_${OrderNumber}.png
    Screenshot    id:robot-preview    ${path}
    [Return]    ${path}

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${files}    ${pdf_path}
    Open Pdf    ${pdf_path}
    Add Files To Pdf    ${files}    ${pdf_path}
    Close Pdf    ${pdf_path}

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}receipts.zip    include=*.pdf

*** Keywords ***
Get file URL from user
    ${url}=    Get Value From User    Input file URL
    [Return]    ${url}

*** Keywords ***
Log Out And Close The Browser
    Close Browser

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${website_url}=    Get Secret    website_url
    ${file_url}=    Get file URL from user
    Open the robot order website    ${website_url}
    ${orders}=    Get orders    ${file_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    5x    0.5s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        ${files}=    Create List    ${pdf}    ${screenshot}
        Embed the robot screenshot to the receipt PDF file    ${files}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    [Teardown]    Log Out And Close The Browser

*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem
Library             RPA.RobotLogListener
Library             RPA.Assistant


*** Variables ***
${orders_file}              ${OUTPUT_DIR}${/}orders.csv
${img_folder}               ${OUTPUT_DIR}${/}image_files
${pdf_folder_receipts}      ${OUTPUT_DIR}${/}receipts
${zip_file}                 ${OUTPUT_DIR}${/}pdf_archive.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Directory Cleanup
    User Input task

    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    10x    2s    Preview the robot
        Wait Until Keyword Succeeds    10x    2s    Submit The Order
        ${pdf}=    Store the receipt as a PDF file    ORDER_NUMBER=${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ORDER_NUMBER=${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    IMG_FILE=${screenshot}    PDF_FILE=${pdf}

        Go to order another robot
    END
    Archive output PDFs

    [Teardown]    Close RobotSpareBin Browser


*** Keywords ***
User Input task
    Add Heading    Input from User
    Add Text Input    text_input
    ...    Please enter URL
    ...    default=https://robotsparebinindustries.com/#/robot-order
    Add submit buttons    buttons=Submit,Cancel    default=Submit
    ${result}=    Run dialog

    ${url}=    Set Variable    ${result}[text_input]
    Log To Console    ${url}
    Open the robot order website    ${url}

Directory Cleanup
    Log To console    Cleaning up content from previous runs
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder_receipts}

    Empty Directory    ${img_folder}
    Empty Directory    ${pdf_folder_receipts}

Open the robot order website
    [Arguments]    ${robot_order_url}
    Open Available Browser    ${robot_order_url}

Get orders
    Download    url=https://robotsparebinindustries.com/orders.csv    target_file=${orders_file}    overwrite=True
    ${table}=    Read table from CSV    path=${orders_file}
    RETURN    ${table}

Close the annoying modal
    Set Local Variable    ${btn_yep}    //*[@id="root"]/div/div[2]/div/div/div/div/div/button[2]
    Wait And Click Button    ${btn_yep}

Go to order another robot
    Set Local Variable    ${btn_order_another_robot}    //*[@id="order-another"]
    Click Button    ${btn_order_another_robot}

Fill the form
    [Arguments]    ${order}

    Set Local Variable    ${head}    ${order}[Head]
    Set Local Variable    ${body}    ${order}[Body]
    Set Local Variable    ${legs}    ${order}[Legs]
    Set Local Variable    ${address}    ${order}[Address]

    Set Local Variable    ${input_head}    //*[@id="head"]
    Set Local Variable    ${input_body}    body
    Set Local Variable    ${input_legs}    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable    ${input_address}    //*[@id="address"]
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible    ${input_head}
    Wait Until Element Is Enabled    ${input_head}
    Select From List By Value    ${input_head}    ${head}

    Wait Until Element Is Enabled    ${input_body}
    Select Radio Button    ${input_body}    ${body}

    Wait Until Element Is Enabled    ${input_legs}
    Input Text    ${input_legs}    ${legs}
    Wait Until Element Is Enabled    ${input_address}
    Input Text    ${input_address}    ${address}

Preview the robot
    Set Local Variable    ${btn_preview}    //*[@id="preview"]
    Set Local Variable    ${img_preview}    //*[@id="robot-preview-image"]
    Click Button    ${btn_preview}
    Wait Until Element Is Visible    ${img_preview}

Submit the order
    Set Local Variable    ${btn_order}    //*[@id="order"]
    Set Local Variable    ${lbl_receipt}    //*[@id="receipt"]

    Mute Run On Failure    Page Should Contain Element

    Click button    ${btn_order}
    Page Should Contain Element    ${lbl_receipt}

Take a screenshot of the robot
    [Arguments]    ${ORDER_NUMBER}
    Set Local Variable    ${lbl_orderid}    xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable    ${img_robot}    //*[@id="robot-preview-image"]

    Wait Until Element Is Visible    ${img_robot}
    Wait Until Element Is Visible    ${lbl_orderid}

    Set Local Variable    ${fully_qualified_img_filename}    ${img_folder}${/}${ORDER_NUMBER}.png

    Sleep    1sec
    Log To Console    Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot    ${img_robot}    ${fully_qualified_img_filename}
    RETURN    ${fully_qualified_img_filename}

Store the receipt as a PDF file
    [Arguments]    ${ORDER_NUMBER}

    Wait Until Element Is Visible    //*[@id="receipt"]
    Log To Console    Printing ${ORDER_NUMBER}
    ${order_receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML

    Set Local Variable    ${fully_qualified_pdf_filename}    ${pdf_folder_receipts}${/}${ORDER_NUMBER}.pdf

    Html To Pdf    content=${order_receipt_html}    output_path=${fully_qualified_pdf_filename}
    RETURN    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${IMG_FILE}    ${PDF_FILE}
    Open PDF    ${PDF_FILE}
    ${image_files}=    Create List    ${IMG_FILE}:align=center
    Add Files To PDF    ${image_files}    ${PDF_FILE}    append=True
    Close PDF    ${PDF_FILE}

Archive output PDFs
    Archive Folder With Zip    ${pdf_folder_receipts}    ${zip_file}    recursive=True    include=*.pdf

Close RobotSpareBin Browser
    Close Browser
